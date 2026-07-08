import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type JsonMap = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const supabase = createClient(supabaseUrl, serviceRoleKey);

serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const { notification_id } = await request.json().catch(() => ({}));
  if (!notification_id || typeof notification_id !== 'string') {
    return json({ error: 'notification_id is required' }, 400);
  }

  const { data: notification, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('id', notification_id)
    .maybeSingle();

  if (error) return json({ error: error.message }, 500);
  if (!notification) return json({ error: 'Notification not found' }, 404);

  const userId = notification.user_id as string;
  const preferences = await loadPreferences(userId);
  if (!shouldSendPush(notification, preferences)) {
    await logDelivery(notification_id, userId, 'push', null, 'skipped', null, 'Disabled by user preferences or quiet hours.');
    return json({ sent: 0, skipped: true });
  }

  const { data: tokens, error: tokenError } = await supabase
    .from('user_push_tokens')
    .select('*')
    .eq('user_id', userId)
    .eq('is_active', true);

  if (tokenError) return json({ error: tokenError.message }, 500);
  if (!tokens?.length) {
    await logDelivery(notification_id, userId, 'push', null, 'skipped', null, 'No active push tokens.');
    return json({ sent: 0, skipped: true });
  }

  let sent = 0;
  let failed = 0;

  for (const token of tokens) {
    const provider = (token.provider ?? 'fcm') as string;
    try {
      const result = provider === 'apns'
        ? await sendApns(token.push_token, notification)
        : await sendFcm(token.push_token, notification);
      sent += 1;
      await logDelivery(notification_id, userId, 'push', provider, 'sent', result, null);
    } catch (sendError) {
      failed += 1;
      await logDelivery(
        notification_id,
        userId,
        'push',
        provider,
        'failed',
        null,
        sendError instanceof Error ? sendError.message : String(sendError),
      );
    }
  }

  return json({ sent, failed });
});

async function loadPreferences(userId: string): Promise<JsonMap> {
  const { data } = await supabase
    .from('notification_preferences')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  return data ?? { push_enabled: true };
}

function shouldSendPush(notification: JsonMap, preferences: JsonMap): boolean {
  if (preferences.push_enabled === false) return false;
  if (preferences.quiet_hours_enabled === true && isQuietHour(preferences)) {
    return false;
  }

  const type = String(notification.type ?? 'system');
  if (type.includes('group') && preferences.group_messages === false) return false;
  if (type.includes('prayer') && preferences.prayer_requests === false) return false;
  if (type.includes('community') && preferences.community_replies === false) return false;
  if ((type.includes('helper') || type.includes('booking')) && preferences.helper_messages === false) return false;
  if (type.includes('booking') && preferences.booking_updates === false) return false;
  if (type.includes('recovery') && preferences.recovery_reminders === false) return false;
  if ((type.includes('quiet') || type.includes('bible')) && preferences.quiet_time_reminders === false) return false;
  if (type.includes('fasting') && preferences.fasting_reminders === false) return false;
  if ((type.includes('subscription') || type.includes('payment')) && preferences.subscription_alerts === false) return false;
  if (type.includes('church') && preferences.church_announcements === false) return false;

  return true;
}

function isQuietHour(preferences: JsonMap): boolean {
  const start = String(preferences.quiet_hours_start ?? '');
  const end = String(preferences.quiet_hours_end ?? '');
  if (!start || !end) return false;

  const now = new Date();
  const current = `${String(now.getUTCHours()).padStart(2, '0')}:${String(now.getUTCMinutes()).padStart(2, '0')}:00`;

  if (start <= end) {
    return current >= start && current <= end;
  }
  return current >= start || current <= end;
}

async function sendFcm(pushToken: string, notification: JsonMap): Promise<string | null> {
  const projectId = requireEnv('FCM_PROJECT_ID');
  const accessToken = await googleAccessToken();
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: pushToken,
        notification: {
          title: String(notification.title ?? 'FreedomCircle'),
          body: pushBody(notification),
        },
        data: stringifyData(notification.data as JsonMap | null),
      },
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(JSON.stringify(body));
  }
  return body.name ?? null;
}

async function sendApns(pushToken: string, notification: JsonMap): Promise<string | null> {
  const keyId = requireEnv('APNS_KEY_ID');
  const teamId = requireEnv('APNS_TEAM_ID');
  const bundleId = requireEnv('APNS_BUNDLE_ID');
  const privateKey = requireEnv('APNS_PRIVATE_KEY').replaceAll('\\n', '\n');
  const signingKey = await importPrivateKey(privateKey, 'ECDSA');
  const jwt = await create(
    { alg: 'ES256', kid: keyId },
    { iss: teamId, iat: Math.floor(Date.now() / 1000) },
    signingKey,
  );

  const response = await fetch(`https://api.push.apple.com/3/device/${pushToken}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-topic': bundleId,
      'apns-push-type': 'alert',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      aps: {
        alert: {
          title: String(notification.title ?? 'FreedomCircle'),
          body: pushBody(notification),
        },
        sound: 'default',
      },
      data: notification.data ?? {},
    }),
  });

  if (!response.ok) {
    throw new Error(await response.text());
  }
  return response.headers.get('apns-id');
}

async function googleAccessToken(): Promise<string> {
  const clientEmail = requireEnv('FCM_CLIENT_EMAIL');
  const privateKey = requireEnv('FCM_PRIVATE_KEY').replaceAll('\\n', '\n');
  const signingKey = await importPrivateKey(privateKey, 'RSASSA-PKCS1-v1_5');
  const now = Math.floor(Date.now() / 1000);
  const assertion = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    },
    signingKey,
  );

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  const body = await response.json();
  if (!response.ok) {
    throw new Error(JSON.stringify(body));
  }
  return body.access_token;
}

async function importPrivateKey(pem: string, algorithm: 'RSASSA-PKCS1-v1_5' | 'ECDSA'): Promise<CryptoKey> {
  const keyData = pemToArrayBuffer(pem);
  const params = algorithm === 'ECDSA'
    ? { name: 'ECDSA', namedCurve: 'P-256' }
    : { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };
  return crypto.subtle.importKey('pkcs8', keyData, params, false, ['sign']);
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

function pushBody(notification: JsonMap): string {
  const data = notification.data as JsonMap | null;
  if (String(data?.sensitive ?? 'false') === 'true') {
    return 'You have a new private update in FreedomCircle.';
  }
  return String(notification.body ?? 'You have a new update in FreedomCircle.');
}

function stringifyData(data: JsonMap | null): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(data ?? {})) {
    if (value !== null && value !== undefined) result[key] = String(value);
  }
  return result;
}

async function logDelivery(
  notificationId: string,
  userId: string,
  deliveryType: string,
  provider: string | null,
  status: string,
  providerMessageId: string | null,
  errorMessage: string | null,
) {
  await supabase.from('notification_delivery_logs').insert({
    notification_id: notificationId,
    user_id: userId,
    delivery_type: deliveryType,
    provider,
    status,
    provider_message_id: providerMessageId,
    error_message: errorMessage,
    sent_at: status === 'sent' ? new Date().toISOString() : null,
  });
}

function requireEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) throw new Error(`${key} is not configured`);
  return value;
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
