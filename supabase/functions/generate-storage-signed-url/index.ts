import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type JsonMap = Record<string, unknown>;

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const admin = createClient(supabaseUrl, serviceRoleKey);

const chatBuckets = new Set(['chat-voice-notes', 'chat-attachments', 'chat-images']);

serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) return json({ error: 'Missing Authorization header' }, 401);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: 'Invalid user token' }, 401);

  const { bucket, path, expiresIn = 300 } = await request.json().catch(() => ({}));
  if (typeof bucket !== 'string' || typeof path !== 'string') {
    return json({ error: 'bucket and path are required' }, 400);
  }
  if (!chatBuckets.has(bucket)) return json({ error: 'Unsupported bucket' }, 400);

  const conversationId = path.split('/')[0];
  if (!conversationId) return json({ error: 'Invalid chat storage path' }, 400);

  const { data: allowed, error: accessError } = await admin.rpc('is_chat_participant', {
    conversation_uuid: conversationId,
    user_uuid: userData.user.id,
  });
  if (accessError) return json({ error: accessError.message }, 500);
  if (allowed !== true) return json({ error: 'Conversation access denied' }, 403);

  const safeExpiry = Math.min(Math.max(Number(expiresIn) || 300, 60), 900);
  const { data, error } = await admin.storage
    .from(bucket)
    .createSignedUrl(path, safeExpiry);

  if (error) return json({ error: error.message }, 500);
  return json({ signedUrl: data.signedUrl, expiresIn: safeExpiry });
});

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
