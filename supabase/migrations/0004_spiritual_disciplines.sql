create table if not exists public.prayer_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  duration_minutes integer not null default 0 check (duration_minutes >= 0),
  prayer_topic text,
  note text,
  is_private boolean not null default true,
  log_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.fasting_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fast_type text,
  started_at timestamptz,
  ended_at timestamptz,
  target_hours numeric(8, 2) check (target_hours is null or target_hours >= 0),
  completed boolean not null default false,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ended_at is null or started_at is null or ended_at >= started_at)
);

create table if not exists public.bible_study_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  book text,
  chapter_start integer check (chapter_start is null or chapter_start > 0),
  chapter_end integer check (chapter_end is null or chapter_end > 0),
  verse_reference text,
  note text,
  completed boolean not null default true,
  log_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mood text,
  struggle_intensity integer check (struggle_intensity between 1 and 10),
  prayer_completed boolean not null default false,
  bible_study_completed boolean not null default false,
  fasting_completed boolean not null default false,
  recovery_status public.recovery_log_type,
  private_note text,
  share_with_group boolean not null default false,
  group_id uuid,
  checkin_date date not null default current_date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, checkin_date)
);
