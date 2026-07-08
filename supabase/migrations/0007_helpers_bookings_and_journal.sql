create table if not exists public.helpers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  display_name text,
  bio text,
  profile_photo_url text,
  focus_areas text[] not null default '{}',
  languages text[] not null default '{}',
  country text,
  city text,
  verification_status public.content_status not null default 'pending_review',
  verification_note text,
  is_available boolean not null default true,
  session_price numeric(12, 2) not null default 0 check (session_price >= 0),
  currency text not null default 'GHS',
  rating numeric(3, 2) not null default 0 check (rating >= 0 and rating <= 5),
  total_reviews integer not null default 0 check (total_reviews >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.helper_availability (
  id uuid primary key default gen_random_uuid(),
  helper_id uuid not null references public.helpers(id) on delete cascade,
  day_of_week integer not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);

create table if not exists public.coach_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  helper_id uuid not null references public.helpers(id) on delete cascade,
  session_type text,
  scheduled_at timestamptz,
  duration_minutes integer not null default 30 check (duration_minutes > 0),
  note text,
  status public.booking_status not null default 'requested',
  amount numeric(12, 2) not null default 0 check (amount >= 0),
  currency text not null default 'GHS',
  payment_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.helper_reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.coach_bookings(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  helper_id uuid not null references public.helpers(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  review text,
  created_at timestamptz not null default now(),
  unique (booking_id, user_id)
);

create table if not exists public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  helper_id uuid references public.helpers(id) on delete set null,
  group_id uuid references public.groups(id) on delete set null,
  title text,
  message text not null,
  urgency_level integer not null default 1 check (urgency_level between 1 and 5),
  status public.content_status not null default 'pending_review',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  body text not null,
  entry_type text,
  mood text,
  is_locked boolean not null default true,
  related_goal_id uuid references public.user_recovery_goals(id) on delete set null,
  related_prayer_id uuid references public.prayer_requests(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
