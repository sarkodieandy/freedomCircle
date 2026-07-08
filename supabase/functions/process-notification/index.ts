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
  const notificationId = notificationIdFromPayload(payload);
  if (!notificationId) {
    return json({ error: 'notification_id is required' }, 400);
  }

  const { data: notification, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('id', notificationId)
    .maybeSingle();

  if (error) return json({ error: error.message }, 500);
  if (!notification) return json({ error: 'Notification not found' }, 404);

  const { data: template } = await supabase
    .from('notification_templates')
    .select('*')
    .eq('key', notification.type)
    .maybeSingle();

  if (template?.is_push_enabled === false) {
    await supabase.from('notification_delivery_logs').insert({
      notification_id: notificationId,
      user_id: notification.user_id,
      delivery_type: 'push',
      status: 'skipped',
      error_message: 'Push disabled for template.',
    });
    return json({ processed: true, push: 'skipped' });
  }

  const response = await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ notification_id: notificationId }),
  });

  const body = await response.json().catch(() => ({}));
  return json({ processed: response.ok, push: body }, response.ok ? 200 : 500);
});

function notificationIdFromPayload(payload: JsonMap): string | null {
  if (typeof payload.notification_id === 'string') return payload.notification_id;
  const record = payload.record as JsonMap | undefined;
  if (typeof record?.id === 'string') return record.id;
  return null;
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
