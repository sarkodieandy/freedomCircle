create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.try_uuid(raw_value text)
returns uuid
language plpgsql
immutable
as $$
begin
  return raw_value::uuid;
exception
  when others then
    return null;
end;
$$;

create or replace function public.is_admin(user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = user_uuid
      and p.status = 'active'
      and p.role in ('moderator', 'admin', 'super_admin')
  );
$$;

create or replace function public.is_group_member(group_uuid uuid, user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.group_members gm
    where gm.group_id = group_uuid
      and gm.user_id = user_uuid
      and gm.status = 'approved'
  );
$$;

create or replace function public.is_group_moderator(group_uuid uuid, user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin(user_uuid)
    or exists (
      select 1
      from public.groups g
      where g.id = group_uuid
        and g.owner_id = user_uuid
    )
    or exists (
      select 1
      from public.group_members gm
      where gm.group_id = group_uuid
        and gm.user_id = user_uuid
        and gm.status = 'approved'
        and gm.role in ('owner', 'moderator', 'helper')
    );
$$;

create or replace function public.is_org_member(org_uuid uuid, user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_members om
    where om.organization_id = org_uuid
      and om.user_id = user_uuid
      and om.status = 'approved'
  );
$$;

create or replace function public.is_org_admin(org_uuid uuid, user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin(user_uuid)
    or exists (
      select 1
      from public.organizations o
      where o.id = org_uuid
        and o.owner_user_id = user_uuid
    )
    or exists (
      select 1
      from public.organization_members om
      where om.organization_id = org_uuid
        and om.user_id = user_uuid
        and om.status = 'approved'
        and om.role in ('church_admin', 'admin', 'super_admin')
    );
$$;

create or replace function public.has_active_premium(user_uuid uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.subscriptions s
    where s.user_id = user_uuid
      and s.status in ('active', 'trialing')
      and s.plan in ('premium_monthly', 'premium_yearly')
      and (s.current_period_end is null or s.current_period_end >= now())
  )
  or exists (
    select 1
    from public.premium_entitlements e
    where e.user_id = user_uuid
      and e.active
      and (e.expires_at is null or e.expires_at >= now())
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_username text;
  generated_username text;
begin
  base_username := lower(
    regexp_replace(
      coalesce(split_part(new.email, '@', 1), 'member'),
      '[^a-zA-Z0-9_]+',
      '_',
      'g'
    )
  );
  base_username := nullif(trim(both '_' from base_username), '');
  generated_username := left(coalesce(base_username, 'member'), 24) || '_' || substring(new.id::text, 1, 8);

  insert into public.profiles (user_id, full_name, username)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', 'FreedomCircle member'),
    generated_username
  )
  on conflict (user_id) do nothing;

  insert into public.subscriptions (user_id, plan, status)
  values (new.id, 'free', 'active')
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.prevent_profile_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() = old.user_id and not public.is_admin(auth.uid()) then
    new.role = old.role;
    new.status = old.status;
    new.church_id = old.church_id;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_helper_self_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() = old.user_id and not public.is_admin(auth.uid()) then
    new.verification_status = old.verification_status;
    new.verification_note = old.verification_note;
    new.rating = old.rating;
    new.total_reviews = old.total_reviews;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_organization_plan_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_admin(auth.uid()) then
    new.subscription_plan = old.subscription_plan;
    new.subscription_status = old.subscription_status;
  end if;
  return new;
end;
$$;

create or replace function public.sync_group_member_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.status = 'approved' then
    update public.groups set member_count = member_count + 1 where id = new.group_id;
  elsif tg_op = 'DELETE' and old.status = 'approved' then
    update public.groups set member_count = greatest(member_count - 1, 0) where id = old.group_id;
  elsif tg_op = 'UPDATE' and old.status <> new.status then
    if old.status = 'approved' then
      update public.groups set member_count = greatest(member_count - 1, 0) where id = old.group_id;
    end if;
    if new.status = 'approved' then
      update public.groups set member_count = member_count + 1 where id = new.group_id;
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.refresh_post_comment_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_post_id uuid;
begin
  affected_post_id := coalesce(new.post_id, old.post_id);
  update public.community_posts
  set comment_count = (
    select count(*)::integer
    from public.post_comments pc
    where pc.post_id = affected_post_id
      and pc.status = 'active'
  )
  where id = affected_post_id;
  return coalesce(new, old);
end;
$$;

create or replace function public.refresh_post_reaction_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_post_id uuid;
begin
  affected_post_id := coalesce(new.post_id, old.post_id);
  update public.community_posts
  set reaction_count = (
    select count(*)::integer
    from public.post_reactions pr
    where pr.post_id = affected_post_id
  )
  where id = affected_post_id;
  return coalesce(new, old);
end;
$$;

create or replace function public.update_recovery_streak()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.goal_id is null then
    return new;
  end if;

  if new.log_type = 'stayed_strong' then
    update public.user_recovery_goals
    set current_streak = current_streak + 1,
        longest_streak = greatest(longest_streak, current_streak + 1),
        total_strong_days = total_strong_days + 1,
        updated_at = now()
    where id = new.goal_id and user_id = new.user_id;
  elsif new.log_type in ('struggled', 'reset') then
    update public.user_recovery_goals
    set current_streak = 0,
        total_struggle_days = total_struggle_days + 1,
        updated_at = now()
    where id = new.goal_id and user_id = new.user_id;
  end if;

  return new;
end;
$$;

create or replace function public.ensure_completed_booking_is_paid()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'completed'
    and new.amount > 0
    and not exists (
      select 1
      from public.payments p
      where p.id = new.payment_id
        and p.status = 'successful'
    )
  then
    raise exception 'Paid bookings can only be completed after verified payment.';
  end if;

  return new;
end;
$$;

create or replace function public.protect_payment_immutability()
returns trigger
language plpgsql
as $$
begin
  if new.amount <> old.amount
    or new.currency <> old.currency
    or new.provider <> old.provider
    or coalesce(new.provider_reference, '') <> coalesce(old.provider_reference, '')
    or coalesce(new.user_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.user_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.organization_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.organization_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.booking_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.booking_id, '00000000-0000-0000-0000-000000000000'::uuid)
  then
    raise exception 'Payment ownership and financial fields are immutable.';
  end if;

  return new;
end;
$$;

create or replace function public.audit_sensitive_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (actor_user_id, action, target_type, target_id, metadata)
  values (
    auth.uid(),
    tg_table_name || '.' || lower(tg_op),
    tg_table_name,
    new.id,
    jsonb_build_object(
      'old_status', coalesce(to_jsonb(old) ->> 'status', to_jsonb(old) ->> 'verification_status'),
      'new_status', coalesce(to_jsonb(new) ->> 'status', to_jsonb(new) ->> 'verification_status')
    )
  );
  return new;
end;
$$;

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'organizations',
    'profiles',
    'user_onboarding_preferences',
    'user_recovery_goals',
    'recovery_logs',
    'fasting_logs',
    'daily_checkins',
    'groups',
    'group_messages',
    'group_prayer_requests',
    'group_resources',
    'community_posts',
    'post_comments',
    'prayer_requests',
    'helpers',
    'coach_bookings',
    'support_requests',
    'journal_entries',
    'subscriptions',
    'payments',
    'reports',
    'app_content',
    'app_settings'
  ] loop
    execute format('drop trigger if exists set_%I_updated_at on public.%I', table_name, table_name);
    execute format('create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()', table_name, table_name);
  end loop;
end $$;

drop trigger if exists prevent_profile_privilege_escalation on public.profiles;
create trigger prevent_profile_privilege_escalation
  before update on public.profiles
  for each row execute function public.prevent_profile_privilege_escalation();

drop trigger if exists prevent_helper_self_verification on public.helpers;
create trigger prevent_helper_self_verification
  before update on public.helpers
  for each row execute function public.prevent_helper_self_verification();

drop trigger if exists prevent_organization_plan_escalation on public.organizations;
create trigger prevent_organization_plan_escalation
  before update on public.organizations
  for each row execute function public.prevent_organization_plan_escalation();

drop trigger if exists sync_group_member_count on public.group_members;
create trigger sync_group_member_count
  after insert or update or delete on public.group_members
  for each row execute function public.sync_group_member_count();

drop trigger if exists refresh_post_comment_count on public.post_comments;
create trigger refresh_post_comment_count
  after insert or update or delete on public.post_comments
  for each row execute function public.refresh_post_comment_count();

drop trigger if exists refresh_post_reaction_count on public.post_reactions;
create trigger refresh_post_reaction_count
  after insert or delete on public.post_reactions
  for each row execute function public.refresh_post_reaction_count();

drop trigger if exists update_recovery_streak on public.recovery_logs;
create trigger update_recovery_streak
  after insert on public.recovery_logs
  for each row execute function public.update_recovery_streak();

drop trigger if exists ensure_completed_booking_is_paid on public.coach_bookings;
create trigger ensure_completed_booking_is_paid
  before insert or update on public.coach_bookings
  for each row execute function public.ensure_completed_booking_is_paid();

drop trigger if exists protect_payment_immutability on public.payments;
create trigger protect_payment_immutability
  before update on public.payments
  for each row execute function public.protect_payment_immutability();

drop trigger if exists audit_reports_update on public.reports;
create trigger audit_reports_update
  after update on public.reports
  for each row execute function public.audit_sensitive_update();

drop trigger if exists audit_helpers_update on public.helpers;
create trigger audit_helpers_update
  after update of verification_status on public.helpers
  for each row execute function public.audit_sensitive_update();

drop trigger if exists audit_community_posts_update on public.community_posts;
create trigger audit_community_posts_update
  after update of status on public.community_posts
  for each row execute function public.audit_sensitive_update();

drop trigger if exists audit_payments_update on public.payments;
create trigger audit_payments_update
  after update of status on public.payments
  for each row execute function public.audit_sensitive_update();

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.user_onboarding_preferences enable row level security;
alter table public.organization_members enable row level security;
alter table public.recovery_categories enable row level security;
alter table public.user_recovery_goals enable row level security;
alter table public.recovery_logs enable row level security;
alter table public.recovery_milestones enable row level security;
alter table public.prayer_logs enable row level security;
alter table public.fasting_logs enable row level security;
alter table public.bible_study_logs enable row level security;
alter table public.daily_checkins enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.group_messages enable row level security;
alter table public.group_prayer_requests enable row level security;
alter table public.group_checkins enable row level security;
alter table public.group_resources enable row level security;
alter table public.community_posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_reactions enable row level security;
alter table public.prayer_requests enable row level security;
alter table public.prayer_interactions enable row level security;
alter table public.helpers enable row level security;
alter table public.helper_availability enable row level security;
alter table public.coach_bookings enable row level security;
alter table public.helper_reviews enable row level security;
alter table public.support_requests enable row level security;
alter table public.journal_entries enable row level security;
alter table public.subscriptions enable row level security;
alter table public.payments enable row level security;
alter table public.premium_entitlements enable row level security;
alter table public.notifications enable row level security;
alter table public.reports enable row level security;
alter table public.user_blocks enable row level security;
alter table public.audit_logs enable row level security;
alter table public.app_content enable row level security;
alter table public.app_settings enable row level security;

drop policy if exists profiles_select_active on public.profiles;
create policy profiles_select_active on public.profiles
  for select to authenticated
  using (status = 'active' or user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists organizations_select_active on public.organizations;
create policy organizations_select_active on public.organizations
  for select to authenticated
  using (status = 'active' or public.is_org_admin(id, auth.uid()));

drop policy if exists organizations_update_admin on public.organizations;
create policy organizations_update_admin on public.organizations
  for update to authenticated
  using (public.is_org_admin(id, auth.uid()))
  with check (public.is_org_admin(id, auth.uid()));

drop policy if exists organizations_insert_admin on public.organizations;
create policy organizations_insert_admin on public.organizations
  for insert to authenticated
  with check (
    public.is_admin(auth.uid())
    or (
      owner_user_id = auth.uid()
      and subscription_plan = 'free'
      and subscription_status = 'active'
    )
  );

drop policy if exists organization_members_select on public.organization_members;
create policy organization_members_select on public.organization_members
  for select to authenticated
  using (user_id = auth.uid() or public.is_org_admin(organization_id, auth.uid()));

drop policy if exists organization_members_insert on public.organization_members;
create policy organization_members_insert on public.organization_members
  for insert to authenticated
  with check (
    (user_id = auth.uid() and status = 'pending')
    or public.is_org_admin(organization_id, auth.uid())
  );

drop policy if exists organization_members_update_admin on public.organization_members;
create policy organization_members_update_admin on public.organization_members
  for update to authenticated
  using (public.is_org_admin(organization_id, auth.uid()))
  with check (public.is_org_admin(organization_id, auth.uid()));

drop policy if exists onboarding_owner_all on public.user_onboarding_preferences;
create policy onboarding_owner_all on public.user_onboarding_preferences
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists recovery_categories_read on public.recovery_categories;
create policy recovery_categories_read on public.recovery_categories
  for select to anon, authenticated
  using (true);

drop policy if exists recovery_categories_admin_all on public.recovery_categories;
create policy recovery_categories_admin_all on public.recovery_categories
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists recovery_goals_owner_all on public.user_recovery_goals;
create policy recovery_goals_owner_all on public.user_recovery_goals
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists recovery_logs_owner_all on public.recovery_logs;
create policy recovery_logs_owner_all on public.recovery_logs
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists recovery_milestones_owner_read on public.recovery_milestones;
create policy recovery_milestones_owner_read on public.recovery_milestones
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists recovery_milestones_admin_insert on public.recovery_milestones;
create policy recovery_milestones_admin_insert on public.recovery_milestones
  for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists prayer_logs_owner_all on public.prayer_logs;
create policy prayer_logs_owner_all on public.prayer_logs
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists fasting_logs_owner_all on public.fasting_logs;
create policy fasting_logs_owner_all on public.fasting_logs
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists bible_study_logs_owner_all on public.bible_study_logs;
create policy bible_study_logs_owner_all on public.bible_study_logs
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists daily_checkins_owner_all on public.daily_checkins;
create policy daily_checkins_owner_all on public.daily_checkins
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists groups_select_visible on public.groups;
create policy groups_select_visible on public.groups
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or owner_id = auth.uid()
    or public.is_group_member(id, auth.uid())
    or (status = 'active' and visibility in ('public', 'premium'))
  );

drop policy if exists groups_insert_authenticated on public.groups;
create policy groups_insert_authenticated on public.groups
  for insert to authenticated
  with check (owner_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists groups_update_moderator on public.groups;
create policy groups_update_moderator on public.groups
  for update to authenticated
  using (public.is_group_moderator(id, auth.uid()))
  with check (public.is_group_moderator(id, auth.uid()));

drop policy if exists group_members_select_visible on public.group_members;
create policy group_members_select_visible on public.group_members
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_group_member(group_id, auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists group_members_request_join on public.group_members;
create policy group_members_request_join on public.group_members
  for insert to authenticated
  with check (
    (user_id = auth.uid() and role = 'member' and status = 'pending')
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists group_members_moderator_update on public.group_members;
create policy group_members_moderator_update on public.group_members
  for update to authenticated
  using (public.is_group_moderator(group_id, auth.uid()))
  with check (public.is_group_moderator(group_id, auth.uid()));

drop policy if exists group_messages_select_members on public.group_messages;
create policy group_messages_select_members on public.group_messages
  for select to authenticated
  using (
    public.is_group_member(group_id, auth.uid())
    and status = 'active'
  );

drop policy if exists group_messages_insert_members on public.group_messages;
create policy group_messages_insert_members on public.group_messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_group_member(group_id, auth.uid())
  );

drop policy if exists group_messages_update_sender_or_mod on public.group_messages;
create policy group_messages_update_sender_or_mod on public.group_messages
  for update to authenticated
  using (sender_id = auth.uid() or public.is_group_moderator(group_id, auth.uid()))
  with check (sender_id = auth.uid() or public.is_group_moderator(group_id, auth.uid()));

drop policy if exists group_prayer_requests_member_all on public.group_prayer_requests;
create policy group_prayer_requests_member_all on public.group_prayer_requests
  for all to authenticated
  using (
    public.is_group_member(group_id, auth.uid())
    or user_id = auth.uid()
    or public.is_group_moderator(group_id, auth.uid())
  )
  with check (
    public.is_group_member(group_id, auth.uid())
    or user_id = auth.uid()
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists group_checkins_member_read on public.group_checkins;
create policy group_checkins_member_read on public.group_checkins
  for select to authenticated
  using (
    public.is_group_member(group_id, auth.uid())
    or user_id = auth.uid()
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists group_checkins_insert_own on public.group_checkins;
create policy group_checkins_insert_own on public.group_checkins
  for insert to authenticated
  with check (user_id = auth.uid() and public.is_group_member(group_id, auth.uid()));

drop policy if exists group_resources_member_read on public.group_resources;
create policy group_resources_member_read on public.group_resources
  for select to authenticated
  using (
    status = 'active'
    and public.is_group_member(group_id, auth.uid())
  );

drop policy if exists group_resources_moderator_all on public.group_resources;
create policy group_resources_moderator_all on public.group_resources
  for all to authenticated
  using (public.is_group_moderator(group_id, auth.uid()))
  with check (public.is_group_moderator(group_id, auth.uid()));

drop policy if exists community_posts_select_visible on public.community_posts;
create policy community_posts_select_visible on public.community_posts
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or user_id = auth.uid()
    or (
      status = 'active'
      and (
        (group_id is null and visibility = 'public')
        or public.is_group_member(group_id, auth.uid())
      )
    )
  );

drop policy if exists community_posts_insert_own on public.community_posts;
create policy community_posts_insert_own on public.community_posts
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and (
      group_id is null
      or public.is_group_member(group_id, auth.uid())
    )
  );

drop policy if exists community_posts_update_author_or_admin on public.community_posts;
create policy community_posts_update_author_or_admin on public.community_posts
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()) or public.is_group_moderator(group_id, auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()) or public.is_group_moderator(group_id, auth.uid()));

drop policy if exists post_comments_select_visible on public.post_comments;
create policy post_comments_select_visible on public.post_comments
  for select to authenticated
  using (
    status = 'active'
    and exists (
      select 1
      from public.community_posts p
      where p.id = post_id
        and (
          public.is_admin(auth.uid())
          or p.user_id = auth.uid()
          or (
            p.status = 'active'
            and (
              (p.group_id is null and p.visibility = 'public')
              or public.is_group_member(p.group_id, auth.uid())
            )
          )
        )
    )
  );

drop policy if exists post_comments_insert_own on public.post_comments;
create policy post_comments_insert_own on public.post_comments
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.community_posts p
      where p.id = post_id
        and p.status = 'active'
        and (
          (p.group_id is null and p.visibility = 'public')
          or public.is_group_member(p.group_id, auth.uid())
        )
    )
  );

drop policy if exists post_comments_update_owner_or_admin on public.post_comments;
create policy post_comments_update_owner_or_admin on public.post_comments
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists post_reactions_visible on public.post_reactions;
create policy post_reactions_visible on public.post_reactions
  for select to authenticated
  using (
    exists (
      select 1
      from public.community_posts p
      where p.id = post_id
        and p.status = 'active'
        and (
          (p.group_id is null and p.visibility = 'public')
          or public.is_group_member(p.group_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  );

drop policy if exists post_reactions_owner_all on public.post_reactions;
create policy post_reactions_owner_all on public.post_reactions
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists prayer_requests_select_visible on public.prayer_requests;
create policy prayer_requests_select_visible on public.prayer_requests
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or user_id = auth.uid()
    or (
      status = 'active'
      and (
        (group_id is null and organization_id is null)
        or public.is_group_member(group_id, auth.uid())
        or public.is_org_member(organization_id, auth.uid())
      )
    )
  );

drop policy if exists prayer_requests_insert_own on public.prayer_requests;
create policy prayer_requests_insert_own on public.prayer_requests
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and (
      group_id is null
      or public.is_group_member(group_id, auth.uid())
    )
    and (
      organization_id is null
      or public.is_org_member(organization_id, auth.uid())
    )
  );

drop policy if exists prayer_requests_update_author_or_admin on public.prayer_requests;
create policy prayer_requests_update_author_or_admin on public.prayer_requests
  for update to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
    or public.is_org_admin(organization_id, auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
    or public.is_org_admin(organization_id, auth.uid())
  );

drop policy if exists prayer_interactions_owner_all on public.prayer_interactions;
create policy prayer_interactions_owner_all on public.prayer_interactions
  for all to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists helpers_select_verified on public.helpers;
create policy helpers_select_verified on public.helpers
  for select to authenticated
  using (verification_status = 'active' or user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists helpers_insert_own on public.helpers;
create policy helpers_insert_own on public.helpers
  for insert to authenticated
  with check (
    public.is_admin(auth.uid())
    or (
      user_id = auth.uid()
      and verification_status = 'pending_review'
    )
  );

drop policy if exists helpers_update_own_or_admin on public.helpers;
create policy helpers_update_own_or_admin on public.helpers
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists helper_availability_select_visible on public.helper_availability;
create policy helper_availability_select_visible on public.helper_availability
  for select to authenticated
  using (
    exists (
      select 1
      from public.helpers h
      where h.id = helper_id
        and (h.verification_status = 'active' or h.user_id = auth.uid() or public.is_admin(auth.uid()))
    )
  );

drop policy if exists helper_availability_helper_all on public.helper_availability;
create policy helper_availability_helper_all on public.helper_availability
  for all to authenticated
  using (
    public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
  )
  with check (
    public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
  );

drop policy if exists coach_bookings_user_helper_read on public.coach_bookings;
create policy coach_bookings_user_helper_read on public.coach_bookings
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
  );

drop policy if exists coach_bookings_user_insert on public.coach_bookings;
create policy coach_bookings_user_insert on public.coach_bookings
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists coach_bookings_user_helper_update on public.coach_bookings;
create policy coach_bookings_user_helper_update on public.coach_bookings
  for update to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
  );

drop policy if exists helper_reviews_select on public.helper_reviews;
create policy helper_reviews_select on public.helper_reviews
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or user_id = auth.uid()
    or exists (select 1 from public.helpers h where h.id = helper_id and h.verification_status = 'active')
  );

drop policy if exists helper_reviews_insert_own on public.helper_reviews;
create policy helper_reviews_insert_own on public.helper_reviews
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists support_requests_visible on public.support_requests;
create policy support_requests_visible on public.support_requests
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists support_requests_insert_own on public.support_requests;
create policy support_requests_insert_own on public.support_requests
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists support_requests_update_assigned on public.support_requests;
create policy support_requests_update_assigned on public.support_requests
  for update to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or exists (select 1 from public.helpers h where h.id = helper_id and h.user_id = auth.uid())
    or public.is_group_moderator(group_id, auth.uid())
  );

drop policy if exists journal_entries_owner_all on public.journal_entries;
create policy journal_entries_owner_all on public.journal_entries
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists subscriptions_select_owner_org_admin on public.subscriptions;
create policy subscriptions_select_owner_org_admin on public.subscriptions
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or public.is_org_admin(organization_id, auth.uid())
  );

drop policy if exists subscriptions_admin_all on public.subscriptions;
create policy subscriptions_admin_all on public.subscriptions
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists payments_select_owner_org_admin on public.payments;
create policy payments_select_owner_org_admin on public.payments
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or public.is_org_admin(organization_id, auth.uid())
  );

drop policy if exists payments_insert_pending_request on public.payments;
create policy payments_insert_pending_request on public.payments
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and status = 'pending'
  );

drop policy if exists payments_admin_update on public.payments;
create policy payments_admin_update on public.payments
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists premium_entitlements_select on public.premium_entitlements;
create policy premium_entitlements_select on public.premium_entitlements
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_admin(auth.uid())
    or public.is_org_admin(organization_id, auth.uid())
  );

drop policy if exists premium_entitlements_admin_all on public.premium_entitlements;
create policy premium_entitlements_admin_all on public.premium_entitlements
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists notifications_owner_read on public.notifications;
create policy notifications_owner_read on public.notifications
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notifications_owner_update_read_at on public.notifications;
create policy notifications_owner_update_read_at on public.notifications
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notifications_admin_insert on public.notifications;
create policy notifications_admin_insert on public.notifications
  for insert to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists reports_select_own_or_admin on public.reports;
create policy reports_select_own_or_admin on public.reports
  for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists reports_insert_authenticated on public.reports;
create policy reports_insert_authenticated on public.reports
  for insert to authenticated
  with check (reporter_id = auth.uid() and status = 'open');

drop policy if exists reports_admin_update on public.reports;
create policy reports_admin_update on public.reports
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists user_blocks_owner_all on public.user_blocks;
create policy user_blocks_owner_all on public.user_blocks
  for all to authenticated
  using (blocker_id = auth.uid())
  with check (blocker_id = auth.uid());

drop policy if exists audit_logs_admin_read on public.audit_logs;
create policy audit_logs_admin_read on public.audit_logs
  for select to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists audit_logs_admin_insert on public.audit_logs;
create policy audit_logs_admin_insert on public.audit_logs
  for insert to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists app_content_public_read on public.app_content;
create policy app_content_public_read on public.app_content
  for select to anon, authenticated
  using (is_active or public.is_admin(auth.uid()));

drop policy if exists app_content_admin_all on public.app_content;
create policy app_content_admin_all on public.app_content
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists app_settings_public_read on public.app_settings;
create policy app_settings_public_read on public.app_settings
  for select to anon, authenticated
  using (true);

drop policy if exists app_settings_admin_all on public.app_settings;
create policy app_settings_admin_all on public.app_settings
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists avatars_public_read on storage.objects;
create policy avatars_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists avatars_owner_manage on storage.objects;
create policy avatars_owner_manage on storage.objects
  for all to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists group_covers_public_read on storage.objects;
create policy group_covers_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'group-covers');

drop policy if exists group_covers_moderator_manage on storage.objects;
create policy group_covers_moderator_manage on storage.objects
  for all to authenticated
  using (
    bucket_id = 'group-covers'
    and public.is_group_moderator(public.try_uuid((storage.foldername(name))[1]), auth.uid())
  )
  with check (
    bucket_id = 'group-covers'
    and public.is_group_moderator(public.try_uuid((storage.foldername(name))[1]), auth.uid())
  );

drop policy if exists organization_assets_public_read on storage.objects;
create policy organization_assets_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'organization-assets');

drop policy if exists organization_assets_admin_manage on storage.objects;
create policy organization_assets_admin_manage on storage.objects
  for all to authenticated
  using (
    bucket_id = 'organization-assets'
    and public.is_org_admin(public.try_uuid((storage.foldername(name))[1]), auth.uid())
  )
  with check (
    bucket_id = 'organization-assets'
    and public.is_org_admin(public.try_uuid((storage.foldername(name))[1]), auth.uid())
  );

drop policy if exists community_attachments_authenticated_read on storage.objects;
create policy community_attachments_authenticated_read on storage.objects
  for select to authenticated
  using (bucket_id = 'community-attachments');

drop policy if exists community_attachments_owner_manage on storage.objects;
create policy community_attachments_owner_manage on storage.objects
  for all to authenticated
  using (bucket_id = 'community-attachments' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'community-attachments' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists journal_attachments_owner_manage on storage.objects;
create policy journal_attachments_owner_manage on storage.objects
  for all to authenticated
  using (bucket_id = 'journal-attachments' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'journal-attachments' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists helper_documents_owner_admin_manage on storage.objects;
create policy helper_documents_owner_admin_manage on storage.objects
  for all to authenticated
  using (
    bucket_id = 'helper-documents'
    and (
      public.is_admin(auth.uid())
      or exists (
        select 1
        from public.helpers h
        where h.id = public.try_uuid((storage.foldername(name))[1])
          and h.user_id = auth.uid()
      )
    )
  )
  with check (
    bucket_id = 'helper-documents'
    and (
      public.is_admin(auth.uid())
      or exists (
        select 1
        from public.helpers h
        where h.id = public.try_uuid((storage.foldername(name))[1])
          and h.user_id = auth.uid()
      )
    )
  );

drop policy if exists app_content_storage_public_read on storage.objects;
create policy app_content_storage_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'app-content');

drop policy if exists app_content_storage_admin_manage on storage.objects;
create policy app_content_storage_admin_manage on storage.objects
  for all to authenticated
  using (bucket_id = 'app-content' and public.is_admin(auth.uid()))
  with check (bucket_id = 'app-content' and public.is_admin(auth.uid()));
