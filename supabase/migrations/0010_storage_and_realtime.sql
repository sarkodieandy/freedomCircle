insert into storage.buckets (id, name, public, file_size_limit)
values
  ('avatars', 'avatars', true, 5242880),
  ('group-covers', 'group-covers', true, 10485760),
  ('organization-assets', 'organization-assets', true, 10485760),
  ('community-attachments', 'community-attachments', false, 15728640),
  ('journal-attachments', 'journal-attachments', false, 15728640),
  ('helper-documents', 'helper-documents', false, 20971520),
  ('app-content', 'app-content', true, 10485760)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit;

alter table public.group_messages replica identity full;
alter table public.group_members replica identity full;
alter table public.notifications replica identity full;
alter table public.prayer_interactions replica identity full;
alter table public.community_posts replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.group_messages;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.group_members;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.notifications;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.prayer_interactions;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.community_posts;
exception
  when duplicate_object then null;
  when undefined_object then null;
end $$;
