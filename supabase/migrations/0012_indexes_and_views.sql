create index if not exists idx_profiles_user_id on public.profiles (user_id);
create index if not exists idx_profiles_username on public.profiles (username);
create index if not exists idx_profiles_role_status on public.profiles (role, status);

create index if not exists idx_organizations_slug on public.organizations (slug);
create index if not exists idx_organization_members_org_user_status on public.organization_members (organization_id, user_id, status);

create index if not exists idx_recovery_goals_user_status on public.user_recovery_goals (user_id, status);
create index if not exists idx_recovery_logs_user_goal_date on public.recovery_logs (user_id, goal_id, log_date desc);
create index if not exists idx_recovery_logs_shared_group on public.recovery_logs (shared_with_group_id, log_date desc) where shared_with_group_id is not null;

create index if not exists idx_prayer_logs_user_date on public.prayer_logs (user_id, log_date desc);
create index if not exists idx_fasting_logs_user_created on public.fasting_logs (user_id, created_at desc);
create index if not exists idx_bible_study_logs_user_date on public.bible_study_logs (user_id, log_date desc);
create index if not exists idx_daily_checkins_user_date on public.daily_checkins (user_id, checkin_date desc);

create index if not exists idx_groups_visibility_status_created on public.groups (visibility, status, created_at desc);
create index if not exists idx_groups_organization on public.groups (organization_id, status);
create index if not exists idx_group_members_group_user_status on public.group_members (group_id, user_id, status);
create index if not exists idx_group_members_user_status on public.group_members (user_id, status);
create index if not exists idx_group_messages_group_created on public.group_messages (group_id, created_at desc);
create index if not exists idx_group_prayer_group_created on public.group_prayer_requests (group_id, created_at desc);
create index if not exists idx_group_checkins_group_date on public.group_checkins (group_id, checkin_date desc);

create index if not exists idx_community_posts_status_visibility_created on public.community_posts (status, visibility, created_at desc);
create index if not exists idx_community_posts_group_created on public.community_posts (group_id, created_at desc);
create index if not exists idx_community_posts_user_created on public.community_posts (user_id, created_at desc);
create index if not exists idx_post_comments_post_created on public.post_comments (post_id, created_at desc);
create index if not exists idx_post_reactions_post_user on public.post_reactions (post_id, user_id);

create index if not exists idx_prayer_requests_group_created on public.prayer_requests (group_id, created_at desc);
create index if not exists idx_prayer_requests_org_created on public.prayer_requests (organization_id, created_at desc);
create index if not exists idx_prayer_interactions_request_user on public.prayer_interactions (prayer_request_id, user_id);

create index if not exists idx_helpers_verified_available on public.helpers (verification_status, is_available, rating desc);
create index if not exists idx_helper_availability_helper_day on public.helper_availability (helper_id, day_of_week);
create index if not exists idx_coach_bookings_user_status on public.coach_bookings (user_id, status, scheduled_at desc);
create index if not exists idx_coach_bookings_helper_status on public.coach_bookings (helper_id, status, scheduled_at desc);

create index if not exists idx_journal_entries_user_created on public.journal_entries (user_id, created_at desc);
create index if not exists idx_notifications_user_read_created on public.notifications (user_id, read_at, created_at desc);
create index if not exists idx_payments_provider_reference on public.payments (provider_reference);
create index if not exists idx_payments_user_status on public.payments (user_id, status, created_at desc);
create index if not exists idx_subscriptions_user_status on public.subscriptions (user_id, status);
create index if not exists idx_subscriptions_org_status on public.subscriptions (organization_id, status);
create index if not exists idx_reports_status_created on public.reports (status, created_at desc);
create index if not exists idx_user_blocks_blocker_blocked on public.user_blocks (blocker_id, blocked_id);

create or replace view public.public_group_cards
with (security_invoker = true)
as
select
  g.id,
  g.organization_id,
  g.name,
  g.slug,
  g.description,
  g.group_type,
  g.visibility,
  g.cover_image_url,
  g.member_count,
  g.online_count,
  g.checkin_rate,
  g.is_premium,
  g.created_at
from public.groups g
where g.status = 'active'
  and g.visibility in ('public', 'premium');

create or replace view public.helper_public_profiles
with (security_invoker = true)
as
select
  h.id,
  h.user_id,
  coalesce(h.display_name, p.full_name, 'FreedomCircle helper') as display_name,
  h.bio,
  h.profile_photo_url,
  h.focus_areas,
  h.languages,
  h.country,
  h.city,
  h.session_price,
  h.currency,
  h.rating,
  h.total_reviews,
  h.is_available,
  h.created_at
from public.helpers h
left join public.profiles p on p.user_id = h.user_id
where h.verification_status = 'active';

create or replace view public.community_feed_posts
with (security_invoker = true)
as
select
  p.id,
  p.group_id,
  p.post_type,
  p.title,
  p.content,
  p.is_anonymous,
  case
    when p.is_anonymous then null
    else p.user_id
  end as visible_author_user_id,
  case
    when p.is_anonymous then 'Anonymous member'
    else coalesce(pr.full_name, 'FreedomCircle member')
  end as visible_author_name,
  case
    when p.is_anonymous then null
    else pr.avatar_url
  end as visible_author_avatar_url,
  p.visibility,
  p.comment_count,
  p.reaction_count,
  p.created_at,
  p.updated_at
from public.community_posts p
left join public.profiles pr on pr.user_id = p.user_id
where p.status = 'active';

create or replace view public.user_dashboard_summary
with (security_invoker = true)
as
select
  p.user_id,
  count(distinct g.id) filter (where g.status = 'active') as active_goal_count,
  max(rl.log_date) as last_recovery_log_date,
  count(distinct dc.id) filter (where dc.checkin_date >= current_date - 6) as checkins_last_7_days,
  count(distinct n.id) filter (where n.read_at is null) as unread_notification_count,
  coalesce(max(s.plan::text) filter (where s.status in ('active', 'trialing')), 'free') as active_plan
from public.profiles p
left join public.user_recovery_goals g on g.user_id = p.user_id
left join public.recovery_logs rl on rl.user_id = p.user_id
left join public.daily_checkins dc on dc.user_id = p.user_id
left join public.notifications n on n.user_id = p.user_id
left join public.subscriptions s on s.user_id = p.user_id
group by p.user_id;

create or replace view public.group_leaderboard_view
with (security_invoker = true)
as
select
  gc.group_id,
  gc.user_id,
  count(*)::integer as checkin_count,
  max(gc.checkin_date) as last_checkin_date,
  dense_rank() over (
    partition by gc.group_id
    order by count(*) desc, max(gc.checkin_date) desc
  ) as rank
from public.group_checkins gc
group by gc.group_id, gc.user_id;

create or replace view public.user_subscription_status
with (security_invoker = true)
as
select distinct on (s.user_id)
  s.user_id,
  s.plan,
  s.status,
  s.provider,
  s.current_period_start,
  s.current_period_end,
  s.cancelled_at,
  public.has_active_premium(s.user_id) as has_active_premium
from public.subscriptions s
where s.user_id is not null
order by s.user_id, s.created_at desc;
