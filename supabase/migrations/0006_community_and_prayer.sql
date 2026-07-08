create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  group_id uuid references public.groups(id) on delete cascade,
  post_type public.post_type not null,
  title text,
  content text not null,
  is_anonymous boolean not null default false,
  visibility public.privacy_level not null default 'public',
  status public.content_status not null default 'active',
  comment_count integer not null default 0 check (comment_count >= 0),
  reaction_count integer not null default 0 check (reaction_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  comment text not null,
  is_anonymous boolean not null default false,
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.community_posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction public.reaction_type not null,
  created_at timestamptz not null default now(),
  unique (post_id, user_id, reaction)
);

create table if not exists public.prayer_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  group_id uuid references public.groups(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  title text not null,
  description text,
  is_anonymous boolean not null default false,
  is_answered boolean not null default false,
  answered_note text,
  answered_at timestamptz,
  status public.content_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prayer_interactions (
  id uuid primary key default gen_random_uuid(),
  prayer_request_id uuid not null references public.prayer_requests(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  prayed_at timestamptz not null default now(),
  unique (prayer_request_id, user_id)
);
