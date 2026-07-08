create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  conversation_type text not null check (conversation_type in ('group', 'prayer_group', 'helper_private', 'support_request', 'admin_support')),
  group_id uuid references public.groups(id) on delete cascade,
  support_request_id uuid references public.support_requests(id) on delete set null,
  booking_id uuid references public.coach_bookings(id) on delete set null,
  title text,
  status text not null default 'active' check (status in ('active', 'archived', 'closed', 'pending_review')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_participants (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'helper', 'coach', 'moderator', 'admin')),
  status text not null default 'active' check (status in ('active', 'muted', 'blocked', 'left')),
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  unique (conversation_id, user_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  sender_id uuid references auth.users(id) on delete set null,
  message_type text not null default 'text' check (message_type in ('text', 'voice', 'image', 'file', 'prayer_request', 'scripture', 'checkin', 'system')),
  body text,
  attachment_url text,
  attachment_path text,
  attachment_mime_type text,
  attachment_size_bytes bigint check (attachment_size_bytes is null or attachment_size_bytes >= 0),
  audio_duration_seconds integer check (audio_duration_seconds is null or audio_duration_seconds >= 0),
  waveform jsonb not null default '[]',
  is_anonymous boolean not null default false,
  reply_to_message_id uuid references public.chat_messages(id) on delete set null,
  status text not null default 'active' check (status in ('active', 'edited', 'deleted', 'hidden', 'pending_review')),
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  unique (message_id, user_id)
);

create table if not exists public.chat_message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction text not null check (reaction in ('amen', 'pray', 'encourage', 'heart')),
  created_at timestamptz not null default now(),
  unique (message_id, user_id, reaction)
);

create table if not exists public.chat_recordings (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  message_id uuid references public.chat_messages(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  recording_type text not null default 'voice_note' check (recording_type in ('voice_note', 'live_session_recording')),
  file_url text not null,
  file_path text not null,
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  mime_type text,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  transcript text,
  status text not null default 'active' check (status in ('active', 'processing', 'failed', 'deleted', 'hidden')),
  consent_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_chat_messages_conversation_created
  on public.chat_messages (conversation_id, created_at desc);
create index if not exists idx_chat_messages_group_created
  on public.chat_messages (group_id, created_at desc);
create index if not exists idx_chat_participants_user_conversation
  on public.chat_participants (user_id, conversation_id);
create index if not exists idx_chat_participants_conversation_user
  on public.chat_participants (conversation_id, user_id);
create index if not exists idx_chat_message_reads_conversation_user
  on public.chat_message_reads (conversation_id, user_id);
create index if not exists idx_chat_reactions_message_user
  on public.chat_message_reactions (message_id, user_id);
create index if not exists idx_chat_recordings_conversation_created
  on public.chat_recordings (conversation_id, created_at desc);
create index if not exists idx_chat_conversations_group
  on public.chat_conversations (group_id);
create index if not exists idx_chat_conversations_created_by
  on public.chat_conversations (created_by);
create index if not exists idx_chat_conversations_support
  on public.chat_conversations (support_request_id);

drop trigger if exists set_chat_conversations_updated_at on public.chat_conversations;
create trigger set_chat_conversations_updated_at
  before update on public.chat_conversations
  for each row execute function public.set_updated_at();

drop trigger if exists set_chat_messages_updated_at on public.chat_messages;
create trigger set_chat_messages_updated_at
  before update on public.chat_messages
  for each row execute function public.set_updated_at();

drop trigger if exists set_chat_recordings_updated_at on public.chat_recordings;
create trigger set_chat_recordings_updated_at
  before update on public.chat_recordings
  for each row execute function public.set_updated_at();

create or replace function public.is_chat_participant(
  conversation_uuid uuid,
  user_uuid uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select user_uuid is not null
    and (
      public.is_admin(user_uuid)
      or exists (
        select 1
        from public.chat_participants cp
        where cp.conversation_id = conversation_uuid
          and cp.user_id = user_uuid
          and cp.status in ('active', 'muted')
      )
      or exists (
        select 1
        from public.chat_conversations cc
        where cc.id = conversation_uuid
          and cc.group_id is not null
          and public.is_group_member(cc.group_id, user_uuid)
      )
    );
$$;

create or replace function public.is_chat_moderator(
  conversation_uuid uuid,
  user_uuid uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select user_uuid is not null
    and (
      public.is_admin(user_uuid)
      or exists (
        select 1
        from public.chat_participants cp
        where cp.conversation_id = conversation_uuid
          and cp.user_id = user_uuid
          and cp.status in ('active', 'muted')
          and cp.role in ('helper', 'coach', 'moderator', 'admin')
      )
      or exists (
        select 1
        from public.chat_conversations cc
        where cc.id = conversation_uuid
          and cc.group_id is not null
          and public.is_group_moderator(cc.group_id, user_uuid)
      )
    );
$$;

create or replace function public.chat_storage_conversation_id(object_name text)
returns uuid
language sql
stable
as $$
  select public.try_uuid((storage.foldername(object_name))[1]);
$$;

create or replace function public.get_or_create_group_chat(
  group_uuid uuid,
  conversation_kind text default 'group'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_uuid uuid;
  group_row public.groups%rowtype;
begin
  if conversation_kind not in ('group', 'prayer_group') then
    raise exception 'Unsupported group conversation type.';
  end if;

  if not public.is_group_member(group_uuid, auth.uid()) then
    raise exception 'Approved group membership is required.';
  end if;

  select * into group_row from public.groups where id = group_uuid;
  if group_row.id is null then
    raise exception 'Group not found.';
  end if;

  select id into conversation_uuid
  from public.chat_conversations
  where group_id = group_uuid
    and conversation_type = conversation_kind
  limit 1;

  if conversation_uuid is null then
    insert into public.chat_conversations (
      conversation_type,
      group_id,
      title,
      created_by
    )
    values (
      conversation_kind,
      group_uuid,
      group_row.name,
      auth.uid()
    )
    returning id into conversation_uuid;
  end if;

  insert into public.chat_participants (conversation_id, user_id, role, status)
  values (
    conversation_uuid,
    auth.uid(),
    case when public.is_group_moderator(group_uuid, auth.uid()) then 'moderator' else 'member' end,
    'active'
  )
  on conflict (conversation_id, user_id) do update
  set status = case when chat_participants.status = 'left' then 'active' else chat_participants.status end;

  return conversation_uuid;
end;
$$;

create or replace function public.get_or_create_private_chat(other_user_uuid uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_uuid uuid;
begin
  if auth.uid() is null or other_user_uuid is null or other_user_uuid = auth.uid() then
    raise exception 'A valid participant is required.';
  end if;

  if public.notification_is_blocked(auth.uid(), other_user_uuid) then
    raise exception 'This conversation is blocked.';
  end if;

  select cc.id into conversation_uuid
  from public.chat_conversations cc
  join public.chat_participants a on a.conversation_id = cc.id and a.user_id = auth.uid()
  join public.chat_participants b on b.conversation_id = cc.id and b.user_id = other_user_uuid
  where cc.conversation_type = 'helper_private'
    and cc.group_id is null
    and cc.support_request_id is null
  limit 1;

  if conversation_uuid is null then
    insert into public.chat_conversations (conversation_type, created_by)
    values ('helper_private', auth.uid())
    returning id into conversation_uuid;

    insert into public.chat_participants (conversation_id, user_id, role)
    values
      (conversation_uuid, auth.uid(), 'member'),
      (conversation_uuid, other_user_uuid, 'helper')
    on conflict (conversation_id, user_id) do nothing;
  end if;

  return conversation_uuid;
end;
$$;

create or replace function public.get_or_create_support_chat(support_request_uuid uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_uuid uuid;
  support_row public.support_requests%rowtype;
  helper_user_id uuid;
begin
  select * into support_row
  from public.support_requests
  where id = support_request_uuid;

  if support_row.id is null then
    raise exception 'Support request not found.';
  end if;

  if auth.uid() <> support_row.user_id
    and not public.is_admin(auth.uid())
    and not exists (
      select 1
      from public.helpers h
      where h.id = support_row.helper_id
        and h.user_id = auth.uid()
    )
  then
    raise exception 'Support conversation access denied.';
  end if;

  select id into conversation_uuid
  from public.chat_conversations
  where support_request_id = support_request_uuid
  limit 1;

  if conversation_uuid is null then
    insert into public.chat_conversations (
      conversation_type,
      support_request_id,
      group_id,
      title,
      created_by
    )
    values (
      'support_request',
      support_request_uuid,
      support_row.group_id,
      coalesce(support_row.title, 'Support conversation'),
      auth.uid()
    )
    returning id into conversation_uuid;

    insert into public.chat_participants (conversation_id, user_id, role)
    values (conversation_uuid, support_row.user_id, 'member')
    on conflict (conversation_id, user_id) do nothing;

    if support_row.helper_id is not null then
      select h.user_id into helper_user_id from public.helpers h where h.id = support_row.helper_id;
      if helper_user_id is not null then
        insert into public.chat_participants (conversation_id, user_id, role)
        values (conversation_uuid, helper_user_id, 'helper')
        on conflict (conversation_id, user_id) do nothing;
      end if;
    end if;
  end if;

  return conversation_uuid;
end;
$$;

create or replace function public.mark_chat_conversation_read(conversation_uuid uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  read_count integer;
begin
  if not public.is_chat_participant(conversation_uuid, auth.uid()) then
    raise exception 'Conversation access denied.';
  end if;

  insert into public.chat_message_reads (message_id, conversation_id, user_id)
  select cm.id, cm.conversation_id, auth.uid()
  from public.chat_messages cm
  where cm.conversation_id = conversation_uuid
    and cm.sender_id is distinct from auth.uid()
  on conflict (message_id, user_id) do update
  set read_at = now();

  get diagnostics read_count = row_count;

  update public.chat_participants
  set last_read_at = now()
  where conversation_id = conversation_uuid
    and user_id = auth.uid();

  return read_count;
end;
$$;

create or replace function public.create_chat_message_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  conversation_row public.chat_conversations%rowtype;
  recipient record;
  title_text text;
  body_text text;
begin
  if new.status not in ('active', 'edited') or new.sender_id is null then
    return new;
  end if;

  select * into conversation_row
  from public.chat_conversations
  where id = new.conversation_id;

  if conversation_row.id is null then
    return new;
  end if;

  title_text := case
    when conversation_row.conversation_type in ('group', 'prayer_group') then
      'New message in ' || coalesce(conversation_row.title, 'your circle')
    when conversation_row.conversation_type in ('helper_private', 'support_request') then
      'New support message'
    else 'New message'
  end;

  body_text := case
    when new.is_anonymous or new.message_type = 'voice' then
      case
        when conversation_row.conversation_type in ('helper_private', 'support_request') then 'You have a new support message'
        else 'New message in your circle'
      end
    when conversation_row.conversation_type in ('helper_private', 'support_request') then
      'You have a new support message'
    else
      'New message in your circle'
  end;

  for recipient in
    select cp.user_id
    from public.chat_participants cp
    where cp.conversation_id = new.conversation_id
      and cp.status in ('active', 'muted')
      and cp.user_id is distinct from new.sender_id
      and not public.notification_is_blocked(new.sender_id, cp.user_id)
  loop
    perform public.create_notification(
      recipient.user_id,
      'helper_message',
      title_text,
      body_text,
      jsonb_build_object(
        'conversation_id', new.conversation_id,
        'message_id', new.id,
        'group_id', new.group_id,
        'route', 'chat',
        'sensitive', new.message_type = 'voice' or conversation_row.conversation_type in ('helper_private', 'support_request')
      ),
      case when conversation_row.conversation_type in ('helper_private', 'support_request') then 'high' else 'normal' end
    );
  end loop;

  return new;
end;
$$;

drop trigger if exists create_chat_message_notification on public.chat_messages;
create trigger create_chat_message_notification
  after insert on public.chat_messages
  for each row execute function public.create_chat_message_notification();

insert into storage.buckets (id, name, public, file_size_limit)
values
  ('chat-voice-notes', 'chat-voice-notes', false, 15728640),
  ('chat-attachments', 'chat-attachments', false, 10485760),
  ('chat-images', 'chat-images', false, 10485760)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit;

insert into public.app_settings (key, value, description)
values
  ('max_voice_note_seconds', '{"seconds": 120}', 'Maximum voice note duration for chat.'),
  ('max_chat_attachment_mb', '{"megabytes": 10}', 'Maximum chat attachment size.'),
  ('voice_notes_enabled', '{"enabled": true}', 'Feature flag for chat voice notes.'),
  ('chat_attachments_enabled', '{"enabled": true}', 'Feature flag for chat attachments.'),
  ('anonymous_group_messages_enabled', '{"enabled": true}', 'Feature flag for anonymous group messages.'),
  ('typing_indicator_enabled', '{"enabled": true}', 'Feature flag for chat typing indicators.'),
  ('read_receipts_enabled', '{"enabled": true}', 'Feature flag for chat read receipts.')
on conflict (key) do update
set
  value = excluded.value,
  description = excluded.description,
  updated_at = now();

alter table public.chat_conversations replica identity full;
alter table public.chat_participants replica identity full;
alter table public.chat_messages replica identity full;
alter table public.chat_message_reads replica identity full;
alter table public.chat_message_reactions replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.chat_conversations;
exception when duplicate_object then null; when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.chat_participants;
exception when duplicate_object then null; when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.chat_messages;
exception when duplicate_object then null; when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.chat_message_reads;
exception when duplicate_object then null; when undefined_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.chat_message_reactions;
exception when duplicate_object then null; when undefined_object then null;
end $$;

alter table public.chat_conversations enable row level security;
alter table public.chat_participants enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_message_reads enable row level security;
alter table public.chat_message_reactions enable row level security;
alter table public.chat_recordings enable row level security;

drop policy if exists chat_conversations_select_participant on public.chat_conversations;
create policy chat_conversations_select_participant on public.chat_conversations
  for select to authenticated
  using (public.is_chat_participant(id, auth.uid()));

drop policy if exists chat_conversations_insert_created_by on public.chat_conversations;
create policy chat_conversations_insert_created_by on public.chat_conversations
  for insert to authenticated
  with check (created_by = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists chat_conversations_update_participant on public.chat_conversations;
create policy chat_conversations_update_participant on public.chat_conversations
  for update to authenticated
  using (created_by = auth.uid() or public.is_chat_moderator(id, auth.uid()))
  with check (created_by = auth.uid() or public.is_chat_moderator(id, auth.uid()));

drop policy if exists chat_participants_select_conversation on public.chat_participants;
create policy chat_participants_select_conversation on public.chat_participants
  for select to authenticated
  using (public.is_chat_participant(conversation_id, auth.uid()));

drop policy if exists chat_participants_insert_self_or_moderator on public.chat_participants;
create policy chat_participants_insert_self_or_moderator on public.chat_participants
  for insert to authenticated
  with check (
    public.is_admin(auth.uid())
    or (
      user_id = auth.uid()
      and exists (
        select 1 from public.chat_conversations cc
        where cc.id = conversation_id
          and cc.created_by = auth.uid()
      )
    )
    or public.is_chat_moderator(conversation_id, auth.uid())
  );

drop policy if exists chat_participants_update_self_or_moderator on public.chat_participants;
create policy chat_participants_update_self_or_moderator on public.chat_participants
  for update to authenticated
  using (user_id = auth.uid() or public.is_chat_moderator(conversation_id, auth.uid()))
  with check (user_id = auth.uid() or public.is_chat_moderator(conversation_id, auth.uid()));

drop policy if exists chat_messages_select_participant on public.chat_messages;
create policy chat_messages_select_participant on public.chat_messages
  for select to authenticated
  using (public.is_chat_participant(conversation_id, auth.uid()));

drop policy if exists chat_messages_insert_participant on public.chat_messages;
create policy chat_messages_insert_participant on public.chat_messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_chat_participant(conversation_id, auth.uid())
    and status in ('active', 'pending_review')
  );

drop policy if exists chat_messages_update_sender_or_moderator on public.chat_messages;
create policy chat_messages_update_sender_or_moderator on public.chat_messages
  for update to authenticated
  using (
    sender_id = auth.uid()
    or public.is_chat_moderator(conversation_id, auth.uid())
  )
  with check (
    sender_id = auth.uid()
    or public.is_chat_moderator(conversation_id, auth.uid())
  );

drop policy if exists chat_message_reads_select_participant on public.chat_message_reads;
create policy chat_message_reads_select_participant on public.chat_message_reads
  for select to authenticated
  using (public.is_chat_participant(conversation_id, auth.uid()));

drop policy if exists chat_message_reads_insert_own on public.chat_message_reads;
create policy chat_message_reads_insert_own on public.chat_message_reads
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_chat_participant(conversation_id, auth.uid())
  );

drop policy if exists chat_message_reads_update_own on public.chat_message_reads;
create policy chat_message_reads_update_own on public.chat_message_reads
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists chat_message_reactions_select_participant on public.chat_message_reactions;
create policy chat_message_reactions_select_participant on public.chat_message_reactions
  for select to authenticated
  using (
    exists (
      select 1 from public.chat_messages cm
      where cm.id = message_id
        and public.is_chat_participant(cm.conversation_id, auth.uid())
    )
  );

drop policy if exists chat_message_reactions_insert_own on public.chat_message_reactions;
create policy chat_message_reactions_insert_own on public.chat_message_reactions
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.chat_messages cm
      where cm.id = message_id
        and public.is_chat_participant(cm.conversation_id, auth.uid())
    )
  );

drop policy if exists chat_message_reactions_delete_own on public.chat_message_reactions;
create policy chat_message_reactions_delete_own on public.chat_message_reactions
  for delete to authenticated
  using (user_id = auth.uid());

drop policy if exists chat_recordings_select_participant on public.chat_recordings;
create policy chat_recordings_select_participant on public.chat_recordings
  for select to authenticated
  using (public.is_chat_participant(conversation_id, auth.uid()));

drop policy if exists chat_recordings_insert_own on public.chat_recordings;
create policy chat_recordings_insert_own on public.chat_recordings
  for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_chat_participant(conversation_id, auth.uid())
    and (
      recording_type = 'voice_note'
      or consent_confirmed
    )
  );

drop policy if exists chat_recordings_update_owner_or_moderator on public.chat_recordings;
create policy chat_recordings_update_owner_or_moderator on public.chat_recordings
  for update to authenticated
  using (
    user_id = auth.uid()
    or public.is_chat_moderator(conversation_id, auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.is_chat_moderator(conversation_id, auth.uid())
  );

drop policy if exists chat_voice_notes_insert_own_path on storage.objects;
create policy chat_voice_notes_insert_own_path on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'chat-voice-notes'
    and auth.uid()::text = (storage.foldername(name))[2]
    and public.is_chat_participant(public.chat_storage_conversation_id(name), auth.uid())
  );

drop policy if exists chat_voice_notes_select_participant on storage.objects;
create policy chat_voice_notes_select_participant on storage.objects
  for select to authenticated
  using (
    bucket_id = 'chat-voice-notes'
    and public.is_chat_participant(public.chat_storage_conversation_id(name), auth.uid())
  );

drop policy if exists chat_attachments_insert_own_path on storage.objects;
create policy chat_attachments_insert_own_path on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('chat-attachments', 'chat-images')
    and auth.uid()::text = (storage.foldername(name))[2]
    and public.is_chat_participant(public.chat_storage_conversation_id(name), auth.uid())
  );

drop policy if exists chat_attachments_select_participant on storage.objects;
create policy chat_attachments_select_participant on storage.objects
  for select to authenticated
  using (
    bucket_id in ('chat-attachments', 'chat-images')
    and public.is_chat_participant(public.chat_storage_conversation_id(name), auth.uid())
  );
