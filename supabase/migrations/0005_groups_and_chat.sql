create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  owner_id uuid references auth.users(id) on delete set null,
  name text not null,
  slug citext unique,
  description text,
  group_type text,
  visibility public.group_visibility not null default 'public',
  cover_image_url text,
  rules text,
  weekly_prompt text,
  is_premium boolean not null default false,
  member_count integer not null default 0 check (member_count >= 0),
  online_count integer not null default 0 check (online_count >= 0),
  checkin_rate numeric(5, 2) not null default 0 check (checkin_rate >= 0),
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.group_member_role not null default 'member',
  status public.group_member_status not null default 'pending',
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  unique (group_id, user_id)
);

create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  message text not null,
  message_type text not null default 'text',
  attachment_url text,
  is_anonymous boolean not null default false,
  status public.content_status not null default 'active',
  reply_to_message_id uuid references public.group_messages(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.group_prayer_requests (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  title text not null,
  description text,
  is_anonymous boolean not null default false,
  is_answered boolean not null default false,
  answered_at timestamptz,
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.group_checkins (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  checkin_date date not null default current_date,
  status text,
  note text,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  unique (group_id, user_id, checkin_date)
);

create table if not exists public.group_resources (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  created_by uuid references auth.users(id) on delete set null,
  title text not null,
  description text,
  resource_type text,
  url text,
  file_url text,
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.recovery_logs
  add constraint recovery_logs_shared_group_fk
  foreign key (shared_with_group_id) references public.groups(id) on delete set null;

alter table public.daily_checkins
  add constraint daily_checkins_group_fk
  foreign key (group_id) references public.groups(id) on delete set null;
