create table if not exists public.quiet_time_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  description text,
  icon text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.quiet_time_sessions (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.quiet_time_categories(id) on delete cascade,
  title text not null,
  slug text unique,
  description text,
  duration_minutes integer not null default 5 check (duration_minutes > 0),
  audio_url text,
  background_image_url text,
  is_premium boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quiet_time_steps (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.quiet_time_sessions(id) on delete cascade,
  step_title text,
  step_type text,
  content text,
  scripture_reference text,
  duration_seconds integer not null default 60 check (duration_seconds > 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.quiet_time_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.quiet_time_sessions(id) on delete cascade,
  mood_before text,
  mood_after text,
  duration_completed_seconds integer not null default 0 check (duration_completed_seconds >= 0),
  completed boolean not null default false,
  private_note text,
  shared_with_group boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.quiet_time_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.quiet_time_sessions(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, session_id)
);

create index if not exists idx_quiet_time_categories_active_sort
  on public.quiet_time_categories (is_active, sort_order);
create index if not exists idx_quiet_time_sessions_active_sort
  on public.quiet_time_sessions (is_active, sort_order);
create index if not exists idx_quiet_time_sessions_category
  on public.quiet_time_sessions (category_id, is_active, sort_order);
create index if not exists idx_quiet_time_steps_session_sort
  on public.quiet_time_steps (session_id, sort_order);
create index if not exists idx_quiet_time_history_user_created
  on public.quiet_time_history (user_id, created_at desc);
create index if not exists idx_quiet_time_favorites_user_created
  on public.quiet_time_favorites (user_id, created_at desc);

create or replace function public.can_access_quiet_time_session(
  session_uuid uuid,
  user_uuid uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not s.is_premium
    or (
      user_uuid is not null
      and public.verify_entitlement(user_uuid, 'quiet_time_premium_library')
    )
  from public.quiet_time_sessions s
  where s.id = session_uuid;
$$;

drop trigger if exists set_quiet_time_sessions_updated_at on public.quiet_time_sessions;
create trigger set_quiet_time_sessions_updated_at
  before update on public.quiet_time_sessions
  for each row execute function public.set_updated_at();

alter table public.quiet_time_categories enable row level security;
alter table public.quiet_time_sessions enable row level security;
alter table public.quiet_time_steps enable row level security;
alter table public.quiet_time_history enable row level security;
alter table public.quiet_time_favorites enable row level security;

drop policy if exists quiet_time_categories_read_active on public.quiet_time_categories;
create policy quiet_time_categories_read_active
  on public.quiet_time_categories
  for select
  to anon, authenticated
  using (is_active);

drop policy if exists quiet_time_sessions_read_active on public.quiet_time_sessions;
create policy quiet_time_sessions_read_active
  on public.quiet_time_sessions
  for select
  to anon
  using (is_active and not is_premium);

drop policy if exists quiet_time_sessions_read_active_auth on public.quiet_time_sessions;
create policy quiet_time_sessions_read_active_auth
  on public.quiet_time_sessions
  for select
  to authenticated
  using (
    is_active
    and (
      not is_premium
      or public.verify_entitlement(auth.uid(), 'quiet_time_premium_library')
    )
  );

drop policy if exists quiet_time_steps_read_active on public.quiet_time_steps;
create policy quiet_time_steps_read_active
  on public.quiet_time_steps
  for select
  to anon
  using (
    exists (
      select 1
      from public.quiet_time_sessions s
      where s.id = quiet_time_steps.session_id
        and s.is_active
        and not s.is_premium
    )
  );

drop policy if exists quiet_time_steps_read_active_auth on public.quiet_time_steps;
create policy quiet_time_steps_read_active_auth
  on public.quiet_time_steps
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.quiet_time_sessions s
      where s.id = quiet_time_steps.session_id
        and s.is_active
        and (
          not s.is_premium
          or public.verify_entitlement(auth.uid(), 'quiet_time_premium_library')
        )
    )
  );

drop policy if exists quiet_time_categories_admin_all on public.quiet_time_categories;
create policy quiet_time_categories_admin_all
  on public.quiet_time_categories
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists quiet_time_sessions_admin_all on public.quiet_time_sessions;
create policy quiet_time_sessions_admin_all
  on public.quiet_time_sessions
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists quiet_time_steps_admin_all on public.quiet_time_steps;
create policy quiet_time_steps_admin_all
  on public.quiet_time_steps
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists quiet_time_history_owner_select on public.quiet_time_history;
create policy quiet_time_history_owner_select
  on public.quiet_time_history
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists quiet_time_history_owner_insert on public.quiet_time_history;
create policy quiet_time_history_owner_insert
  on public.quiet_time_history
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists quiet_time_history_owner_update on public.quiet_time_history;
create policy quiet_time_history_owner_update
  on public.quiet_time_history
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists quiet_time_favorites_owner_select on public.quiet_time_favorites;
create policy quiet_time_favorites_owner_select
  on public.quiet_time_favorites
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists quiet_time_favorites_owner_insert on public.quiet_time_favorites;
create policy quiet_time_favorites_owner_insert
  on public.quiet_time_favorites
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists quiet_time_favorites_owner_delete on public.quiet_time_favorites;
create policy quiet_time_favorites_owner_delete
  on public.quiet_time_favorites
  for delete
  to authenticated
  using (auth.uid() = user_id);

insert into public.plan_features (
  plan_id,
  feature_key,
  feature_name,
  feature_description,
  is_enabled
)
select
  p.id,
  f.feature_key,
  f.feature_name,
  f.feature_description,
  true
from public.plans p
cross join (
  values
    ('quiet_time_premium_library', 'Quiet Time Premium Library', 'Unlock premium guided Quiet Time audio sessions.'),
    ('quiet_time_advanced_insights', 'Quiet Time Advanced Insights', 'Unlock mood trends and deeper Quiet Time analytics.'),
    ('quiet_time_offline_sessions', 'Quiet Time Offline Sessions', 'Download and access Quiet Time sessions offline.')
) as f(feature_key, feature_name, feature_description)
where p.code in ('premium_monthly', 'premium_yearly')
on conflict (plan_id, feature_key)
do update set
  feature_name = excluded.feature_name,
  feature_description = excluded.feature_description,
  is_enabled = true;

insert into public.quiet_time_categories (name, slug, description, icon, sort_order, is_active)
values
  ('Guided Prayer', 'guided-prayer', 'Spirit-led prayer prompts for calm focus and trust.', 'volunteer_activism', 1, true),
  ('Scripture Meditation', 'scripture-meditation', 'Slow scripture reflection with gentle stillness.', 'menu_book', 2, true),
  ('Silent Reflection', 'silent-reflection', 'Timed quiet with breathing prayer and optional verse.', 'self_improvement', 3, true),
  ('Recovery Reset', 'recovery-reset', 'Gentle reset when tempted, tired, or discouraged.', 'restart_alt', 4, true),
  ('Gratitude', 'gratitude', 'Give thanks for grace, progress, and provision.', 'favorite', 5, true),
  ('Night Peace', 'night-peace', 'End your day in peace, prayer, and surrender.', 'nights_stay', 6, true),
  ('Morning Strength', 'morning-strength', 'Start your day anchored in strength and scripture.', 'wb_sunny', 7, true),
  ('Surrender', 'surrender', 'Lay down burdens and receive God''s peace.', 'front_hand', 8, true)
on conflict (slug)
do update set
  name = excluded.name,
  description = excluded.description,
  icon = excluded.icon,
  sort_order = excluded.sort_order,
  is_active = excluded.is_active;

with seeded_categories as (
  select id, slug
  from public.quiet_time_categories
)
insert into public.quiet_time_sessions (
  category_id,
  title,
  slug,
  description,
  duration_minutes,
  is_premium,
  is_active,
  sort_order
)
select c.id, s.title, s.slug, s.description, s.duration_minutes, s.is_premium, true, s.sort_order
from seeded_categories c
join (
  values
    ('silent-reflection', '3-Minute Stillness', '3-minute-stillness', 'A short quiet pause to breathe, settle, and reconnect.', 3, false, 1),
    ('morning-strength', 'Morning Strength Prayer', 'morning-strength-prayer', 'Start strong with scripture, prayer, and intention.', 5, false, 2),
    ('recovery-reset', 'Reset With Grace', 'reset-with-grace', 'Pause after a hard moment and take the next faithful step.', 7, false, 3),
    ('gratitude', 'Gratitude Reflection', 'gratitude-reflection', 'Name today''s mercies and end with hopeful prayer.', 6, false, 4),
    ('guided-prayer', '21-Day Quiet Time Journey', '21-day-quiet-time-journey', 'A premium guided audio path for spiritual consistency.', 12, true, 5),
    ('night-peace', 'Night Peace Audio Prayer', 'night-peace-audio-prayer', 'A calm prayer flow to release anxiety before sleep.', 10, true, 6),
    ('recovery-reset', 'Strength Before Temptation', 'strength-before-temptation', 'Ground your next decision in truth, grace, and support.', 8, true, 7),
    ('surrender', 'Surrender the Struggle', 'surrender-the-struggle', 'Release shame and surrender burdens in prayer.', 9, true, 8),
    ('scripture-meditation', 'Deep Scripture Stillness', 'deep-scripture-stillness', 'Meditate deeply on scripture with guided silence.', 10, true, 9),
    ('recovery-reset', 'Guided Recovery Reset', 'guided-recovery-reset', 'A longer recovery reset with prayer and private reflection.', 11, true, 10),
    ('scripture-meditation', '10-Minute Scripture Stillness', '10-minute-scripture-stillness', 'Rest in one passage and listen quietly.', 10, false, 11),
    ('silent-reflection', 'Silent Reflection Timer', 'silent-reflection-timer', 'Choose your own timer and practice stillness with prayer.', 5, false, 12),
    ('guided-prayer', 'Breathe and Pray', 'breathe-and-pray', 'Simple breath prayer for calm and clarity.', 7, false, 13),
    ('night-peace', 'Gratitude Before Sleep', 'gratitude-before-sleep', 'Close your day with gratitude and trust.', 8, false, 14)
) as s(category_slug, title, slug, description, duration_minutes, is_premium, sort_order)
  on s.category_slug = c.slug
on conflict (slug)
do update set
  category_id = excluded.category_id,
  title = excluded.title,
  description = excluded.description,
  duration_minutes = excluded.duration_minutes,
  is_premium = excluded.is_premium,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  updated_at = now();

with target_sessions as (
  select id, slug
  from public.quiet_time_sessions
)
insert into public.quiet_time_steps (
  session_id,
  step_title,
  step_type,
  content,
  scripture_reference,
  duration_seconds,
  sort_order
)
select s.id, x.step_title, x.step_type, x.content, x.scripture_reference, x.duration_seconds, x.sort_order
from target_sessions s
join (
  values
    ('3-minute-stillness', 'Settle', 'settle', 'Release tension and become aware of your breath.', null, 40, 1),
    ('3-minute-stillness', 'Breathe', 'breathing', 'Breathe in peace, breathe out pressure.', 'Psalm 46:10', 80, 2),
    ('3-minute-stillness', 'Pray', 'prayer', 'Offer one short honest prayer.', null, 60, 3),

    ('morning-strength-prayer', 'Settle', 'settle', 'Begin this morning with stillness and surrender.', null, 60, 1),
    ('morning-strength-prayer', 'Reflect', 'reflection', 'God''s mercy is new every morning.', 'Lamentations 3:22-23', 120, 2),
    ('morning-strength-prayer', 'Pray', 'prayer', 'Ask for wisdom, strength, and self-control today.', null, 120, 3),

    ('reset-with-grace', 'Settle', 'settle', 'You are not your struggle. This is a reset moment.', null, 60, 1),
    ('reset-with-grace', 'Breathe', 'breathing', 'Breathe slowly and gently name what you feel.', null, 120, 2),
    ('reset-with-grace', 'Reflect', 'reflection', 'What is the next faithful step in this moment?', '1 Corinthians 10:13', 120, 3),
    ('reset-with-grace', 'Pray', 'prayer', 'Pray for grace, accountability, and courage.', null, 120, 4)
) as x(session_slug, step_title, step_type, content, scripture_reference, duration_seconds, sort_order)
  on x.session_slug = s.slug
where not exists (
  select 1
  from public.quiet_time_steps qts
  where qts.session_id = s.id
    and qts.step_title = x.step_title
    and qts.sort_order = x.sort_order
);
