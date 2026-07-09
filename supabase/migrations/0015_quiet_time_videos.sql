insert into storage.buckets (id, name, public, file_size_limit)
values
  ('quiet-time-videos', 'quiet-time-videos', false, 536870912)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit;

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
      and (
        public.verify_entitlement(user_uuid, 'quiet_time_premium_library')
        or public.verify_entitlement(user_uuid, 'quiet_time_premium_video_library')
      )
    )
  from public.quiet_time_sessions s
  where s.id = session_uuid;
$$;

alter table public.quiet_time_sessions
  add column if not exists session_type text not null default 'audio',
  add column if not exists video_url text,
  add column if not exists video_storage_path text,
  add column if not exists video_provider text,
  add column if not exists scripture_reference text,
  add column if not exists reflection_prompt text,
  add column if not exists difficulty_level text,
  add column if not exists status text not null default 'draft',
  add column if not exists created_by uuid references auth.users(id) on delete set null;

alter table public.quiet_time_sessions
  alter column session_type set default 'audio';

-- Safely add constraints (idempotent)
alter table public.quiet_time_sessions
  drop constraint if exists quiet_time_sessions_session_type_check;
alter table public.quiet_time_sessions
  add constraint quiet_time_sessions_session_type_check
  check (session_type in ('audio', 'video'));

alter table public.quiet_time_sessions
  drop constraint if exists quiet_time_sessions_status_check;
alter table public.quiet_time_sessions
  add constraint quiet_time_sessions_status_check
  check (status in ('draft', 'published', 'hidden', 'archived'));

-- Migrate all seeded sessions to published so Flutter can display them.
-- New sessions created via the admin start as 'draft' until explicitly published.
update public.quiet_time_sessions
set status = 'published'
where status = 'draft';

create table if not exists public.quiet_time_video_chapters (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.quiet_time_sessions(id) on delete cascade,
  title text not null,
  description text,
  start_seconds integer not null default 0 check (start_seconds >= 0),
  end_seconds integer check (end_seconds is null or end_seconds >= start_seconds),
  scripture_reference text,
  reflection_prompt text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.quiet_time_downloads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.quiet_time_sessions(id) on delete cascade,
  downloaded_at timestamptz not null default now(),
  expires_at timestamptz,
  status text not null default 'active',
  unique (user_id, session_id)
);

create index if not exists idx_quiet_time_sessions_status_sort
  on public.quiet_time_sessions (status, is_active, sort_order);
create index if not exists idx_quiet_time_sessions_type_status
  on public.quiet_time_sessions (session_type, status, is_active, sort_order);
create index if not exists idx_quiet_time_video_chapters_session_sort
  on public.quiet_time_video_chapters (session_id, sort_order);
create index if not exists idx_quiet_time_downloads_user_created
  on public.quiet_time_downloads (user_id, downloaded_at desc);

drop trigger if exists set_quiet_time_video_chapters_updated_at on public.quiet_time_video_chapters;
create trigger set_quiet_time_video_chapters_updated_at
  before update on public.quiet_time_video_chapters
  for each row execute function public.set_updated_at();

alter table public.quiet_time_video_chapters enable row level security;
alter table public.quiet_time_downloads enable row level security;

drop policy if exists quiet_time_sessions_read_active on public.quiet_time_sessions;
create policy quiet_time_sessions_read_active
  on public.quiet_time_sessions
  for select
  to anon
  using (is_active and status = 'published' and not is_premium);

drop policy if exists quiet_time_sessions_read_active_auth on public.quiet_time_sessions;
create policy quiet_time_sessions_read_active_auth
  on public.quiet_time_sessions
  for select
  to authenticated
  using (
    is_active
    and status = 'published'
    and (
      not is_premium
      or public.verify_entitlement(auth.uid(), 'quiet_time_premium_library')
      or public.verify_entitlement(auth.uid(), 'quiet_time_premium_video_library')
    )
  );

drop policy if exists quiet_time_video_chapters_read_public on public.quiet_time_video_chapters;
create policy quiet_time_video_chapters_read_public
  on public.quiet_time_video_chapters
  for select
  to anon
  using (
    exists (
      select 1
      from public.quiet_time_sessions s
      where s.id = quiet_time_video_chapters.session_id
        and s.is_active
        and s.status = 'published'
        and not s.is_premium
    )
  );

drop policy if exists quiet_time_video_chapters_read_auth on public.quiet_time_video_chapters;
create policy quiet_time_video_chapters_read_auth
  on public.quiet_time_video_chapters
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.quiet_time_sessions s
      where s.id = quiet_time_video_chapters.session_id
        and s.is_active
        and s.status = 'published'
        and (
          not s.is_premium
          or public.verify_entitlement(auth.uid(), 'quiet_time_premium_library')
          or public.verify_entitlement(auth.uid(), 'quiet_time_premium_video_library')
        )
    )
  );

drop policy if exists quiet_time_video_chapters_admin_all on public.quiet_time_video_chapters;
create policy quiet_time_video_chapters_admin_all
  on public.quiet_time_video_chapters
  for all
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists quiet_time_downloads_owner_select on public.quiet_time_downloads;
create policy quiet_time_downloads_owner_select
  on public.quiet_time_downloads
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists quiet_time_downloads_owner_insert on public.quiet_time_downloads;
create policy quiet_time_downloads_owner_insert
  on public.quiet_time_downloads
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.quiet_time_sessions s
      where s.id = quiet_time_downloads.session_id
        and s.is_active
        and s.status = 'published'
        and (
          not s.is_premium
          or public.verify_entitlement(auth.uid(), 'quiet_time_video_downloads')
        )
    )
  );

drop policy if exists quiet_time_downloads_owner_delete on public.quiet_time_downloads;
create policy quiet_time_downloads_owner_delete
  on public.quiet_time_downloads
  for delete
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists quiet_time_videos_authenticated_signed_read on storage.objects;
create policy quiet_time_videos_authenticated_signed_read on storage.objects
  for select
  to authenticated
  using (bucket_id = 'quiet-time-videos');

drop policy if exists quiet_time_videos_admin_manage on storage.objects;
create policy quiet_time_videos_admin_manage on storage.objects
  for all
  to authenticated
  using (bucket_id = 'quiet-time-videos' and public.is_admin(auth.uid()))
  with check (bucket_id = 'quiet-time-videos' and public.is_admin(auth.uid()));

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
    ('quiet_time_premium_video_library', 'Quiet Time Premium Video Library', 'Unlock premium meditation, prayer, and reflection videos.'),
    ('quiet_time_video_practice', 'Quiet Time Video Practice', 'Enable immersive Quiet Time video practice sessions.'),
    ('quiet_time_video_downloads', 'Quiet Time Video Downloads', 'Allow secure offline downloads for premium Quiet Time videos.')
) as f(feature_key, feature_name, feature_description)
where p.code in ('premium_monthly', 'premium_yearly')
on conflict (plan_id, feature_key)
do update set
  feature_name = excluded.feature_name,
  feature_description = excluded.feature_description,
  is_enabled = true;