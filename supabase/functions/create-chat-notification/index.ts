import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type JsonMap = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const supabase = createClient(supabaseUrl, serviceRoleKey);

serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const payload = await request.json().catch(() => ({}));
  const messageId = messageIdFromPayload(payload);
  if (!messageId) {
    return json({ error: 'message_id is required' }, 400);
  }

  const { data: message, error: messageError } = await supabase
    .from('chat_messages')
    .select('*, chat_conversations(*)')
    .eq('id', messageId)
    .maybeSingle();

  if (messageError) return json({ error: messageError.message }, 500);
  if (!message) return json({ error: 'Chat message not found' }, 404);
  if (message.status !== 'active' || !message.sender_id) {
    return json({ created: 0, skipped: true });
  }

  const conversation = message.chat_conversations as JsonMap | null;
  const conversationId = String(message.conversation_id);
  const conversationType = String(conversation?.conversation_type ?? 'group');

  const { data: participants, error: participantError } = await supabase
    .from('chat_participants')
    .select('user_id,status')
    .eq('conversation_id', conversationId)
    .in('status', ['active', 'muted']);

  if (participantError) return json({ error: participantError.message }, 500);

  let created = 0;
  for (const participant of participants ?? []) {
    const userId = participant.user_id as string;
    if (userId === message.sender_id) continue;

    const { data: blocked } = await supabase.rpc('notification_is_blocked', {
      sender_uuid: message.sender_id,
      target_uuid: userId,
    });
    if (blocked === true) continue;

    const { error } = await supabase.rpc('create_notification', {
      target_user_id: userId,
      notification_type: notificationType(conversationType),
      notification_title: notificationTitle(conversationType, conversation),
      notification_body: notificationBody(message, conversationType),
      notification_data: {
        route: 'chat',
        conversation_id: conversationId,
        message_id: message.id,
        group_id: message.group_id,
        sensitive:
          message.message_type === 'voice' ||
          ['helper_private', 'support_request'].includes(conversationType),
      },
      notification_priority: ['helper_private', 'support_request'].includes(
        conversationType,
      )
        ? 'high'
        : 'normal',
    });

    if (!error) created += 1;
  }

  return json({ created });
});

function messageIdFromPayload(payload: JsonMap): string | null {
  if (typeof payload.message_id === 'string') return payload.message_id;
  const record = payload.record as JsonMap | undefined;
  if (typeof record?.id === 'string') return record.id;
  return null;
}

function notificationType(conversationType: string): string {
  if (conversationType === 'prayer_group') return 'group_prayer_message';
  if (conversationType === 'group') return 'group_message';
  return 'helper_message';
}

function notificationTitle(conversationType: string, conversation: JsonMap | null): string {
  if (conversationType === 'prayer_group') return 'New prayer group message';
  if (conversationType === 'group') {
    return `New message in ${String(conversation?.title ?? 'your circle')}`;
  }
  if (conversationType === 'support_request') return 'New support message';
  return 'New helper message';
}

function notificationBody(message: JsonMap, conversationType: string): string {
  if (message.is_anonymous === true || message.message_type === 'voice') {
    return ['helper_private', 'support_request'].includes(conversationType)
      ? 'You have a private support update.'
      : 'You have a new safe-circle update.';
  }
  return ['helper_private', 'support_request'].includes(conversationType)
    ? 'You have a private support update.'
    : 'Open your circle to continue the conversation.';
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
