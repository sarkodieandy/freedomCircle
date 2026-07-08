alter table public.notifications
  alter column type type text using type::text,
  alter column data set default '{}';

alter table public.notifications
  add column if not exists priority text not null default 'normal',
  add column if not exists channel text not null default 'in_app',
  add column if not exists is_read boolean not null default false,
  add column if not exists action_url text,
  add column if not exists image_url text,
  add column if not exists updated_at timestamptz not null default now();

update public.notifications
set is_read = read_at is not null
where is_read is distinct from (read_at is not null);

alter table public.notifications
  alter column type set not null,
  alter column data set not null;

alter table public.notifications
  drop constraint if exists notifications_priority_check;

alter table public.notifications
  add constraint notifications_priority_check
  check (priority in ('low', 'normal', 'high', 'urgent'))
  not valid;

alter table public.notifications
  drop constraint if exists notifications_channel_check;

alter table public.notifications
  add constraint notifications_channel_check
  check (channel in ('in_app', 'push', 'email', 'system'))
  not valid;

create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  group_messages boolean not null default true,
  prayer_requests boolean not null default true,
  community_replies boolean not null default true,
  helper_messages boolean not null default true,
  booking_updates boolean not null default true,
  recovery_reminders boolean not null default true,
  quiet_time_reminders boolean not null default true,
  fasting_reminders boolean not null default true,
  subscription_alerts boolean not null default true,
  church_announcements boolean not null default true,
  push_enabled boolean not null default true,
  email_enabled boolean not null default false,
  quiet_hours_enabled boolean not null default false,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  platform text not null check (platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux')),
  push_token text not null,
  provider text not null default 'fcm' check (provider in ('fcm', 'apns')),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_id)
);

create table if not exists public.notification_delivery_logs (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid references public.notifications(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  delivery_type text not null check (delivery_type in ('in_app', 'push', 'email')),
  provider text,
  status text not null check (status in ('pending', 'sent', 'failed', 'skipped')),
  provider_message_id text,
  error_message text,
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.notification_templates (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  title_template text not null,
  body_template text,
  type text not null,
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  is_push_enabled boolean not null default true,
  is_in_app_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_is_read_created
  on public.notifications (user_id, is_read, created_at desc);
create index if not exists idx_notifications_user_type_created
  on public.notifications (user_id, type, created_at desc);
create index if not exists idx_notification_preferences_user
  on public.notification_preferences (user_id);
create index if not exists idx_user_push_tokens_user_active
  on public.user_push_tokens (user_id, is_active, provider);
create index if not exists idx_notification_delivery_logs_notification
  on public.notification_delivery_logs (notification_id, created_at desc);
create index if not exists idx_notification_delivery_logs_user_status
  on public.notification_delivery_logs (user_id, status, created_at desc);
create index if not exists idx_notification_templates_key_enabled
  on public.notification_templates (key, is_in_app_enabled, is_push_enabled);

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
  before update on public.notifications
  for each row execute function public.set_updated_at();

drop trigger if exists set_notification_preferences_updated_at on public.notification_preferences;
create trigger set_notification_preferences_updated_at
  before update on public.notification_preferences
  for each row execute function public.set_updated_at();

drop trigger if exists set_user_push_tokens_updated_at on public.user_push_tokens;
create trigger set_user_push_tokens_updated_at
  before update on public.user_push_tokens
  for each row execute function public.set_updated_at();

drop trigger if exists set_notification_templates_updated_at on public.notification_templates;
create trigger set_notification_templates_updated_at
  before update on public.notification_templates
  for each row execute function public.set_updated_at();

create or replace function public.safe_notification_body(
  notification_type text,
  notification_body text,
  notification_data jsonb default '{}'
)
returns text
language plpgsql
stable
set search_path = public
as $$
begin
  if lower(coalesce(notification_data ->> 'sensitive', 'false')) in ('true', '1', 'yes') then
    return 'You have a new private update in FreedomCircle.';
  end if;

  if notification_type in (
    'recovery_reminder',
    'group_checkin_reminder',
    'quiet_time_reminder',
    'fasting_reminder',
    'bible_study_reminder'
  ) then
    return coalesce(notification_body, 'You have a gentle reminder in FreedomCircle.');
  end if;

  return notification_body;
end;
$$;

create or replace function public.notification_is_blocked(sender_uuid uuid, target_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select sender_uuid is not null
    and target_uuid is not null
    and exists (
      select 1
      from public.user_blocks ub
      where (
        ub.blocker_id = target_uuid
        and ub.blocked_id = sender_uuid
      )
      or (
        ub.blocker_id = sender_uuid
        and ub.blocked_id = target_uuid
      )
    );
$$;

create or replace function public.create_notification(
  target_user_id uuid,
  notification_type text,
  notification_title text,
  notification_body text,
  notification_data jsonb default '{}',
  notification_priority text default 'normal'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  notification_uuid uuid;
  safe_body text;
begin
  if target_user_id is null or not exists (select 1 from auth.users u where u.id = target_user_id) then
    return null;
  end if;

  safe_body := public.safe_notification_body(
    notification_type,
    notification_body,
    coalesce(notification_data, '{}'::jsonb)
  );

  insert into public.notifications (
    user_id,
    type,
    title,
    body,
    data,
    priority,
    channel
  )
  values (
    target_user_id,
    notification_type,
    notification_title,
    safe_body,
    coalesce(notification_data, '{}'::jsonb),
    coalesce(notification_priority, 'normal'),
    'in_app'
  )
  returning id into notification_uuid;

  return notification_uuid;
end;
$$;

create or replace function public.mark_notification_read(notification_uuid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.notifications
  set is_read = true,
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where id = notification_uuid
    and user_id = auth.uid();
end;
$$;

create or replace function public.mark_all_notifications_read()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.notifications
  set is_read = true,
      read_at = coalesce(read_at, now()),
      updated_at = now()
  where user_id = auth.uid()
    and not is_read;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

create or replace function public.get_unread_notification_count()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.notifications n
  where n.user_id = auth.uid()
    and not n.is_read;
$$;

create or replace function public.create_default_notification_preferences()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  target_user_id := public.try_uuid(coalesce(to_jsonb(new) ->> 'user_id', to_jsonb(new) ->> 'id'));

  if target_user_id is not null then
    insert into public.notification_preferences (user_id)
    values (target_user_id)
    on conflict (user_id) do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists create_default_notification_preferences_auth on auth.users;
create trigger create_default_notification_preferences_auth
  after insert on auth.users
  for each row execute function public.create_default_notification_preferences();

drop trigger if exists create_default_notification_preferences_profile on public.profiles;
create trigger create_default_notification_preferences_profile
  after insert on public.profiles
  for each row execute function public.create_default_notification_preferences();

create or replace function public.notify_group_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  group_row public.groups%rowtype;
  recipient record;
  body_text text;
begin
  if new.status <> 'active' then
    return new;
  end if;

  select * into group_row from public.groups where id = new.group_id;
  if group_row.id is null then
    return new;
  end if;

  body_text := case
    when new.is_anonymous then 'New message in your circle'
    else 'New message in your circle'
  end;

  for recipient in
    select gm.user_id
    from public.group_members gm
    where gm.group_id = new.group_id
      and gm.status = 'approved'
      and gm.user_id is distinct from new.sender_id
      and not public.notification_is_blocked(new.sender_id, gm.user_id)
  loop
    perform public.create_notification(
      recipient.user_id,
      'group_message',
      group_row.name,
      body_text,
      jsonb_build_object(
        'group_id', new.group_id,
        'message_id', new.id,
        'route', 'group_chat',
        'sensitive', new.is_anonymous
      ),
      'normal'
    );
  end loop;

  return new;
end;
$$;

create or replace function public.notify_group_join_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient record;
begin
  if new.status <> 'pending' then
    return new;
  end if;

  for recipient in
    select distinct user_id
    from (
      select g.owner_id as user_id
      from public.groups g
      where g.id = new.group_id
        and g.owner_id is not null
      union
      select gm.user_id
      from public.group_members gm
      where gm.group_id = new.group_id
        and gm.status = 'approved'
        and gm.role in ('owner', 'moderator', 'helper')
    ) recipients
    where user_id is distinct from new.user_id
      and not public.notification_is_blocked(new.user_id, user_id)
  loop
    perform public.create_notification(
      recipient.user_id,
      'group_join_request',
      'New group request',
      'Someone requested to join your circle.',
      jsonb_build_object('group_id', new.group_id, 'member_id', new.id, 'route', 'group_requests'),
      'normal'
    );
  end loop;

  return new;
end;
$$;

create or replace function public.notify_group_join_approved()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  group_name text;
begin
  if new.status = 'approved' and old.status is distinct from new.status then
    select name into group_name from public.groups where id = new.group_id;

    perform public.create_notification(
      new.user_id,
      'group_join_approved',
      'You''re in',
      'Your request to join ' || coalesce(group_name, 'this circle') || ' was approved.',
      jsonb_build_object('group_id', new.group_id, 'route', 'group_detail'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_group_prayer_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient record;
begin
  if new.status <> 'active' then
    return new;
  end if;

  for recipient in
    select gm.user_id
    from public.group_members gm
    where gm.group_id = new.group_id
      and gm.status = 'approved'
      and gm.user_id is distinct from new.user_id
      and not public.notification_is_blocked(new.user_id, gm.user_id)
  loop
    perform public.create_notification(
      recipient.user_id,
      'group_prayer_request',
      'New prayer request',
      'Someone in your circle requested prayer.',
      jsonb_build_object('group_id', new.group_id, 'group_prayer_request_id', new.id, 'route', 'group_prayer'),
      'normal'
    );
  end loop;

  return new;
end;
$$;

create or replace function public.notify_prayer_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient record;
begin
  if new.status <> 'active' or new.group_id is null then
    return new;
  end if;

  for recipient in
    select gm.user_id
    from public.group_members gm
    where gm.group_id = new.group_id
      and gm.status = 'approved'
      and gm.user_id is distinct from new.user_id
      and not public.notification_is_blocked(new.user_id, gm.user_id)
  loop
    perform public.create_notification(
      recipient.user_id,
      'prayer_request',
      'New prayer request',
      'Someone in your circle requested prayer.',
      jsonb_build_object('group_id', new.group_id, 'prayer_request_id', new.id, 'route', 'prayer_detail'),
      'normal'
    );
  end loop;

  return new;
end;
$$;

create or replace function public.notify_prayer_interaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  owner_user_id uuid;
begin
  select pr.user_id into owner_user_id
  from public.prayer_requests pr
  where pr.id = new.prayer_request_id;

  if owner_user_id is not null
    and owner_user_id is distinct from new.user_id
    and not public.notification_is_blocked(new.user_id, owner_user_id)
  then
    perform public.create_notification(
      owner_user_id,
      'prayer_interaction',
      'Someone prayed with you',
      'Your prayer request received support.',
      jsonb_build_object('prayer_request_id', new.prayer_request_id, 'route', 'prayer_detail'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_prayer_answered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient record;
begin
  if new.is_answered and old.is_answered is distinct from new.is_answered and new.group_id is not null then
    for recipient in
      select gm.user_id
      from public.group_members gm
      where gm.group_id = new.group_id
        and gm.status = 'approved'
        and gm.user_id is distinct from new.user_id
        and not public.notification_is_blocked(new.user_id, gm.user_id)
    loop
      perform public.create_notification(
        recipient.user_id,
        'prayer_answered',
        'Answered prayer',
        'A prayer request was marked as answered.',
        jsonb_build_object('group_id', new.group_id, 'prayer_request_id', new.id, 'route', 'prayer_detail'),
        'normal'
      );
    end loop;
  end if;

  return new;
end;
$$;

create or replace function public.notify_group_prayer_answered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient record;
begin
  if new.is_answered and old.is_answered is distinct from new.is_answered then
    for recipient in
      select gm.user_id
      from public.group_members gm
      where gm.group_id = new.group_id
        and gm.status = 'approved'
        and gm.user_id is distinct from new.user_id
        and not public.notification_is_blocked(new.user_id, gm.user_id)
    loop
      perform public.create_notification(
        recipient.user_id,
        'prayer_answered',
        'Answered prayer',
        'A prayer request was marked as answered.',
        jsonb_build_object('group_id', new.group_id, 'group_prayer_request_id', new.id, 'route', 'group_prayer'),
        'normal'
      );
    end loop;
  end if;

  return new;
end;
$$;

create or replace function public.notify_community_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  post_owner uuid;
begin
  select cp.user_id into post_owner
  from public.community_posts cp
  where cp.id = new.post_id;

  if post_owner is not null
    and post_owner is distinct from new.user_id
    and not public.notification_is_blocked(new.user_id, post_owner)
  then
    perform public.create_notification(
      post_owner,
      'community_comment',
      'New comment',
      'Someone replied to your post.',
      jsonb_build_object('post_id', new.post_id, 'comment_id', new.id, 'route', 'community_post'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_community_reaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  post_owner uuid;
begin
  select cp.user_id into post_owner
  from public.community_posts cp
  where cp.id = new.post_id;

  if post_owner is not null
    and post_owner is distinct from new.user_id
    and not public.notification_is_blocked(new.user_id, post_owner)
  then
    perform public.create_notification(
      post_owner,
      'community_reaction',
      'New encouragement',
      'Someone responded to your post.',
      jsonb_build_object('post_id', new.post_id, 'reaction', new.reaction, 'route', 'community_post'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_helper_support_request()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  helper_user_id uuid;
begin
  if new.helper_id is null then
    return new;
  end if;

  select h.user_id into helper_user_id
  from public.helpers h
  where h.id = new.helper_id;

  if helper_user_id is not null
    and helper_user_id is distinct from new.user_id
    and not public.notification_is_blocked(new.user_id, helper_user_id)
  then
    perform public.create_notification(
      helper_user_id,
      'helper_support_request',
      'New support request',
      'Someone requested support.',
      jsonb_build_object('support_request_id', new.id, 'helper_id', new.helper_id, 'route', 'support_request'),
      'high'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_booking_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  helper_user_id uuid;
begin
  select h.user_id into helper_user_id
  from public.helpers h
  where h.id = new.helper_id;

  if helper_user_id is not null
    and helper_user_id is distinct from new.user_id
    and not public.notification_is_blocked(new.user_id, helper_user_id)
  then
    perform public.create_notification(
      helper_user_id,
      'booking_requested',
      'New booking request',
      'Someone requested a helper session.',
      jsonb_build_object('booking_id', new.id, 'helper_id', new.helper_id, 'route', 'booking_detail'),
      'high'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_booking_status_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  helper_user_id uuid;
  notification_type text;
  title_text text;
  body_text text;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  select h.user_id into helper_user_id
  from public.helpers h
  where h.id = new.helper_id;

  notification_type := case new.status
    when 'accepted' then 'booking_accepted'
    when 'cancelled' then 'booking_cancelled'
    when 'completed' then 'booking_reminder'
    when 'missed' then 'booking_cancelled'
    else 'booking_requested'
  end;

  title_text := case new.status
    when 'accepted' then 'Booking accepted'
    when 'cancelled' then 'Booking cancelled'
    when 'completed' then 'Session completed'
    when 'missed' then 'Session update'
    else 'Booking update'
  end;

  body_text := case new.status
    when 'accepted' then 'Your helper session was accepted.'
    when 'cancelled' then 'Your helper session was cancelled.'
    when 'completed' then 'Your helper session was marked complete.'
    when 'missed' then 'There is an update on your helper session.'
    else 'There is an update on your helper session.'
  end;

  if new.user_id is not null and not public.notification_is_blocked(helper_user_id, new.user_id) then
    perform public.create_notification(
      new.user_id,
      notification_type,
      title_text,
      body_text,
      jsonb_build_object('booking_id', new.id, 'helper_id', new.helper_id, 'route', 'booking_detail'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.notify_recovery_milestone()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.create_notification(
    new.user_id,
    'milestone_unlocked',
    'Milestone unlocked',
    'You reached a new growth milestone.',
    jsonb_build_object('goal_id', new.goal_id, 'milestone_id', new.id, 'route', 'recovery_tracker'),
    'normal'
  );

  return new;
end;
$$;

create or replace function public.notify_payment_status_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status and new.user_id is not null then
    if new.status = 'successful' then
      perform public.create_notification(
        new.user_id,
        'payment_success',
        'Payment confirmed',
        'Your payment was confirmed securely.',
        jsonb_build_object('payment_id', new.id, 'subscription_id', new.subscription_id, 'program_id', new.program_id, 'route', 'payments'),
        'normal'
      );
    elsif new.status = 'failed' then
      perform public.create_notification(
        new.user_id,
        'payment_failed',
        'Payment failed',
        'We could not confirm that payment. Please try again or contact support.',
        jsonb_build_object('payment_id', new.id, 'route', 'payments'),
        'high'
      );
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.notify_subscription_status_changed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status and new.user_id is not null then
    perform public.create_notification(
      new.user_id,
      case when new.status in ('active', 'trialing') then 'subscription_success' else 'subscription_expiring' end,
      case when new.status in ('active', 'trialing') then 'Subscription active' else 'Subscription update' end,
      case when new.status in ('active', 'trialing') then 'Your subscription is active.' else 'There is an update on your subscription.' end,
      jsonb_build_object('subscription_id', new.id, 'plan_code', coalesce(new.plan_code, new.plan::text), 'route', 'subscription'),
      'normal'
    );
  end if;

  return new;
end;
$$;

create or replace function public.create_due_daily_reminder_notifications()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer := 0;
  pref record;
  notification_uuid uuid;
begin
  for pref in select * from public.notification_preferences loop
    if pref.recovery_reminders and not exists (
      select 1 from public.notifications n
      where n.user_id = pref.user_id
        and n.type = 'recovery_reminder'
        and n.created_at::date = current_date
    ) then
      notification_uuid := public.create_notification(
        pref.user_id,
        'recovery_reminder',
        'Gentle check-in',
        'Take a quiet moment to check in with your growth today.',
        jsonb_build_object('route', 'recovery_tracker'),
        'normal'
      );
      if notification_uuid is not null then inserted_count := inserted_count + 1; end if;
    end if;

    if pref.quiet_time_reminders and not exists (
      select 1 from public.notifications n
      where n.user_id = pref.user_id
        and n.type = 'quiet_time_reminder'
        and n.created_at::date = current_date
    ) then
      notification_uuid := public.create_notification(
        pref.user_id,
        'quiet_time_reminder',
        'Quiet Time',
        'Your quiet time space is ready when you are.',
        jsonb_build_object('route', 'quiet_time'),
        'normal'
      );
      if notification_uuid is not null then inserted_count := inserted_count + 1; end if;
    end if;

    if pref.prayer_requests and not exists (
      select 1 from public.notifications n
      where n.user_id = pref.user_id
        and n.type = 'prayer_request'
        and n.data ->> 'reminder_kind' = 'daily_prayer'
        and n.created_at::date = current_date
    ) then
      notification_uuid := public.create_notification(
        pref.user_id,
        'prayer_request',
        'Prayer reminder',
        'Take a quiet moment for prayer today.',
        jsonb_build_object('route', 'prayer_wall', 'reminder_kind', 'daily_prayer'),
        'normal'
      );
      if notification_uuid is not null then inserted_count := inserted_count + 1; end if;
    end if;

    if pref.fasting_reminders and not exists (
      select 1 from public.notifications n
      where n.user_id = pref.user_id
        and n.type = 'fasting_reminder'
        and n.created_at::date = current_date
    ) then
      notification_uuid := public.create_notification(
        pref.user_id,
        'fasting_reminder',
        'Fasting reminder',
        'Pause and prepare wisely for today''s fasting rhythm.',
        jsonb_build_object('route', 'quiet_time'),
        'normal'
      );
      if notification_uuid is not null then inserted_count := inserted_count + 1; end if;
    end if;

    if pref.quiet_time_reminders and not exists (
      select 1 from public.notifications n
      where n.user_id = pref.user_id
        and n.type = 'bible_study_reminder'
        and n.created_at::date = current_date
    ) then
      notification_uuid := public.create_notification(
        pref.user_id,
        'bible_study_reminder',
        'Bible study reminder',
        'Your Scripture rhythm is ready for today.',
        jsonb_build_object('route', 'quiet_time'),
        'normal'
      );
      if notification_uuid is not null then inserted_count := inserted_count + 1; end if;
    end if;
  end loop;

  return inserted_count;
end;
$$;

drop trigger if exists notify_group_message on public.group_messages;
create trigger notify_group_message
  after insert on public.group_messages
  for each row execute function public.notify_group_message();

drop trigger if exists notify_group_join_request on public.group_members;
create trigger notify_group_join_request
  after insert on public.group_members
  for each row execute function public.notify_group_join_request();

drop trigger if exists notify_group_join_approved on public.group_members;
create trigger notify_group_join_approved
  after update of status on public.group_members
  for each row execute function public.notify_group_join_approved();

drop trigger if exists notify_group_prayer_request on public.group_prayer_requests;
create trigger notify_group_prayer_request
  after insert on public.group_prayer_requests
  for each row execute function public.notify_group_prayer_request();

drop trigger if exists notify_prayer_request on public.prayer_requests;
create trigger notify_prayer_request
  after insert on public.prayer_requests
  for each row execute function public.notify_prayer_request();

drop trigger if exists notify_prayer_interaction on public.prayer_interactions;
create trigger notify_prayer_interaction
  after insert on public.prayer_interactions
  for each row execute function public.notify_prayer_interaction();

drop trigger if exists notify_prayer_answered on public.prayer_requests;
create trigger notify_prayer_answered
  after update of is_answered on public.prayer_requests
  for each row execute function public.notify_prayer_answered();

drop trigger if exists notify_group_prayer_answered on public.group_prayer_requests;
create trigger notify_group_prayer_answered
  after update of is_answered on public.group_prayer_requests
  for each row execute function public.notify_group_prayer_answered();

drop trigger if exists notify_community_comment on public.post_comments;
create trigger notify_community_comment
  after insert on public.post_comments
  for each row execute function public.notify_community_comment();

drop trigger if exists notify_community_reaction on public.post_reactions;
create trigger notify_community_reaction
  after insert on public.post_reactions
  for each row execute function public.notify_community_reaction();

drop trigger if exists notify_helper_support_request on public.support_requests;
create trigger notify_helper_support_request
  after insert on public.support_requests
  for each row execute function public.notify_helper_support_request();

drop trigger if exists notify_booking_created on public.coach_bookings;
create trigger notify_booking_created
  after insert on public.coach_bookings
  for each row execute function public.notify_booking_created();

drop trigger if exists notify_booking_status_changed on public.coach_bookings;
create trigger notify_booking_status_changed
  after update of status on public.coach_bookings
  for each row execute function public.notify_booking_status_changed();

drop trigger if exists notify_recovery_milestone on public.recovery_milestones;
create trigger notify_recovery_milestone
  after insert on public.recovery_milestones
  for each row execute function public.notify_recovery_milestone();

drop trigger if exists notify_payment_status_changed on public.payments;
create trigger notify_payment_status_changed
  after update of status on public.payments
  for each row execute function public.notify_payment_status_changed();

drop trigger if exists notify_subscription_status_changed on public.subscriptions;
create trigger notify_subscription_status_changed
  after update of status on public.subscriptions
  for each row execute function public.notify_subscription_status_changed();

alter table public.notification_preferences enable row level security;
alter table public.user_push_tokens enable row level security;
alter table public.notification_delivery_logs enable row level security;
alter table public.notification_templates enable row level security;

drop policy if exists notifications_owner_read on public.notifications;
create policy notifications_owner_read on public.notifications
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notifications_owner_update_read_at on public.notifications;
drop policy if exists notifications_owner_update on public.notifications;
create policy notifications_owner_update on public.notifications
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notifications_owner_delete on public.notifications;
create policy notifications_owner_delete on public.notifications
  for delete to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notifications_admin_insert on public.notifications;
create policy notifications_admin_insert on public.notifications
  for insert to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists notification_preferences_owner_select on public.notification_preferences;
create policy notification_preferences_owner_select on public.notification_preferences
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notification_preferences_owner_insert on public.notification_preferences;
create policy notification_preferences_owner_insert on public.notification_preferences
  for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notification_preferences_owner_update on public.notification_preferences;
create policy notification_preferences_owner_update on public.notification_preferences
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists user_push_tokens_owner_select on public.user_push_tokens;
create policy user_push_tokens_owner_select on public.user_push_tokens
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists user_push_tokens_owner_insert on public.user_push_tokens;
create policy user_push_tokens_owner_insert on public.user_push_tokens
  for insert to authenticated
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists user_push_tokens_owner_update on public.user_push_tokens;
create policy user_push_tokens_owner_update on public.user_push_tokens
  for update to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()))
  with check (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists user_push_tokens_owner_delete on public.user_push_tokens;
create policy user_push_tokens_owner_delete on public.user_push_tokens
  for delete to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notification_delivery_logs_owner_read on public.notification_delivery_logs;
create policy notification_delivery_logs_owner_read on public.notification_delivery_logs
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists notification_delivery_logs_admin_all on public.notification_delivery_logs;
create policy notification_delivery_logs_admin_all on public.notification_delivery_logs
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists notification_templates_admin_all on public.notification_templates;
create policy notification_templates_admin_all on public.notification_templates
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

insert into public.notification_templates (
  key,
  title_template,
  body_template,
  type,
  priority,
  is_push_enabled,
  is_in_app_enabled
)
values
  ('group_message', '{{group_name}}', 'New message in your circle', 'group_message', 'normal', true, true),
  ('group_join_request', 'New group request', 'Someone requested to join your circle.', 'group_join_request', 'normal', true, true),
  ('group_join_approved', 'You''re in', 'Your request to join {{group_name}} was approved.', 'group_join_approved', 'normal', true, true),
  ('group_prayer_request', 'New prayer request', 'Someone in your circle requested prayer.', 'group_prayer_request', 'normal', true, true),
  ('prayer_interaction', 'Someone prayed with you', 'Your prayer request received support.', 'prayer_interaction', 'normal', true, true),
  ('prayer_answered', 'Answered prayer', 'A prayer request was marked as answered.', 'prayer_answered', 'normal', true, true),
  ('community_comment', 'New comment', 'Someone replied to your post.', 'community_comment', 'normal', true, true),
  ('community_reaction', 'New encouragement', 'Someone responded to your post.', 'community_reaction', 'normal', true, true),
  ('helper_support_request', 'New support request', 'Someone requested support.', 'helper_support_request', 'high', true, true),
  ('booking_requested', 'New booking request', 'Someone requested a helper session.', 'booking_requested', 'high', true, true),
  ('booking_accepted', 'Booking accepted', 'Your helper session was accepted.', 'booking_accepted', 'normal', true, true),
  ('booking_cancelled', 'Booking cancelled', 'Your helper session was cancelled.', 'booking_cancelled', 'normal', true, true),
  ('recovery_reminder', 'Gentle check-in', 'Take a quiet moment to check in with your growth today.', 'recovery_reminder', 'normal', true, true),
  ('milestone_unlocked', 'Milestone unlocked', 'You reached a new growth milestone.', 'milestone_unlocked', 'normal', true, true),
  ('quiet_time_reminder', 'Quiet Time', 'Your quiet time space is ready when you are.', 'quiet_time_reminder', 'normal', true, true),
  ('fasting_reminder', 'Fasting reminder', 'Pause and prepare wisely for today''s fasting rhythm.', 'fasting_reminder', 'normal', true, true),
  ('bible_study_reminder', 'Bible study reminder', 'Your Scripture rhythm is ready for today.', 'bible_study_reminder', 'normal', true, true),
  ('subscription_success', 'Subscription active', 'Your subscription is active.', 'subscription_success', 'normal', true, true),
  ('subscription_expiring', 'Subscription update', 'There is an update on your subscription.', 'subscription_expiring', 'normal', true, true),
  ('payment_success', 'Payment confirmed', 'Your payment was confirmed securely.', 'payment_success', 'normal', true, true),
  ('payment_failed', 'Payment failed', 'We could not confirm that payment. Please try again or contact support.', 'payment_failed', 'high', true, true),
  ('church_announcement', 'Church announcement', 'Your church shared an update.', 'church_announcement', 'normal', true, true),
  ('safety_report_update', 'Safety update', 'There is an update on your report.', 'safety_report_update', 'high', true, true),
  ('system', 'FreedomCircle update', 'You have a new update in FreedomCircle.', 'system', 'normal', true, true)
on conflict (key) do update
set
  title_template = excluded.title_template,
  body_template = excluded.body_template,
  type = excluded.type,
  priority = excluded.priority,
  is_push_enabled = excluded.is_push_enabled,
  is_in_app_enabled = excluded.is_in_app_enabled,
  updated_at = now();

create or replace view public.unread_notifications_by_user
with (security_invoker = true)
as
select
  user_id,
  count(*)::integer as unread_count,
  max(created_at) as latest_unread_at
from public.notifications
where not is_read
group by user_id;

create or replace view public.notification_delivery_summary
with (security_invoker = true)
as
select
  delivery_type,
  coalesce(provider, 'unknown') as provider,
  status,
  count(*)::integer as delivery_count,
  max(created_at) as latest_event_at
from public.notification_delivery_logs
group by delivery_type, coalesce(provider, 'unknown'), status;

create or replace view public.notification_engagement_summary
with (security_invoker = true)
as
select
  type,
  count(*)::integer as total_notifications,
  count(*) filter (where is_read)::integer as read_notifications,
  count(*) filter (where not is_read)::integer as unread_notifications,
  case
    when count(*) = 0 then 0
    else round((count(*) filter (where is_read))::numeric / count(*)::numeric * 100, 2)
  end as read_rate
from public.notifications
group by type;

create or replace view public.failed_push_notifications
with (security_invoker = true)
as
select
  ndl.id,
  ndl.notification_id,
  ndl.user_id,
  n.type,
  n.title,
  ndl.provider,
  ndl.error_message,
  ndl.created_at
from public.notification_delivery_logs ndl
join public.notifications n on n.id = ndl.notification_id
where ndl.delivery_type = 'push'
  and ndl.status = 'failed';
