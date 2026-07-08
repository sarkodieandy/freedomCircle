create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug citext unique not null,
  logo_url text,
  cover_url text,
  description text,
  website text,
  country text,
  city text,
  owner_user_id uuid references auth.users(id) on delete set null,
  subscription_plan public.subscription_plan not null default 'free',
  subscription_status public.subscription_status not null default 'active',
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  full_name text,
  username citext unique,
  avatar_url text,
  role public.user_role not null default 'user',
  status public.profile_status not null default 'active',
  gender text,
  country text,
  city text,
  church_name text,
  church_id uuid references public.organizations(id) on delete set null,
  bio text,
  is_anonymous_enabled boolean not null default true,
  onboarding_completed boolean not null default false,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_onboarding_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  focus_areas text[] not null default '{}',
  privacy_level public.privacy_level not null default 'private',
  goal_duration_days integer check (goal_duration_days is null or goal_duration_days > 0),
  reminder_time time,
  wants_group boolean not null default false,
  wants_helper boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.user_role not null default 'user',
  status public.group_member_status not null default 'approved',
  joined_at timestamptz not null default now(),
  unique (organization_id, user_id)
);
