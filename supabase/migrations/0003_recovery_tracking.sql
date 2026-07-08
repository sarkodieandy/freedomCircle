create table if not exists public.recovery_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug citext unique not null,
  icon text,
  description text,
  is_sensitive boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.user_recovery_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.recovery_categories(id) on delete set null,
  title text not null,
  reason text,
  start_date date not null default current_date,
  target_days integer not null default 30 check (target_days > 0),
  current_streak integer not null default 0 check (current_streak >= 0),
  longest_streak integer not null default 0 check (longest_streak >= 0),
  total_strong_days integer not null default 0 check (total_strong_days >= 0),
  total_struggle_days integer not null default 0 check (total_struggle_days >= 0),
  privacy_level public.privacy_level not null default 'private',
  status public.goal_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recovery_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_id uuid references public.user_recovery_goals(id) on delete cascade,
  log_type public.recovery_log_type not null,
  mood text,
  intensity integer check (intensity between 1 and 10),
  trigger_note text,
  reflection_note text,
  is_private boolean not null default true,
  shared_with_group_id uuid,
  log_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recovery_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  goal_id uuid not null references public.user_recovery_goals(id) on delete cascade,
  milestone_days integer not null check (milestone_days > 0),
  title text not null,
  badge_icon text,
  unlocked_at timestamptz not null default now(),
  unique (goal_id, milestone_days)
);
