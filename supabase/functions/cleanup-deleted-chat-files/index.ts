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

  const { dryRun = false, limit = 100 } = await request.json().catch(() => ({}));
  const cappedLimit = Math.min(Math.max(Number(limit) || 100, 1), 500);

  const deletedRecordings = await cleanupRecordings(Boolean(dryRun), cappedLimit);
  const deletedAttachments = await cleanupMessageAttachments(
    Boolean(dryRun),
    cappedLimit,
  );

  return json({
    dryRun: Boolean(dryRun),
    deletedRecordings,
    deletedAttachments,
  });
});

async function cleanupRecordings(dryRun: boolean, limit: number): Promise<number> {
  const { data, error } = await supabase
    .from('chat_recordings')
    .select('id,file_path')
    .in('status', ['deleted', 'hidden'])
    .limit(limit);

  if (error) throw error;
  if (!data?.length) return 0;
  if (dryRun) return data.length;

  const paths = data
    .map((row) => row.file_path)
    .filter((path): path is string => typeof path === 'string' && path.length > 0);

  if (paths.length) {
    await supabase.storage.from('chat-voice-notes').remove(paths);
  }

  return paths.length;
}

async function cleanupMessageAttachments(dryRun: boolean, limit: number): Promise<number> {
  const { data, error } = await supabase
    .from('chat_messages')
    .select('id,message_type,attachment_path')
    .in('status', ['deleted', 'hidden'])
    .not('attachment_path', 'is', null)
    .limit(limit);

  if (error) throw error;
  if (!data?.length) return 0;
  if (dryRun) return data.length;

  const byBucket = new Map<string, string[]>();
  for (const row of data) {
    const path = row.attachment_path;
    if (typeof path !== 'string' || path.length === 0) continue;
    const bucket = bucketForMessageType(String(row.message_type));
    byBucket.set(bucket, [...(byBucket.get(bucket) ?? []), path]);
  }

  let deleted = 0;
  for (const [bucket, paths] of byBucket) {
    if (!paths.length) continue;
    await supabase.storage.from(bucket).remove(paths);
    deleted += paths.length;
  }

  return deleted;
}

function bucketForMessageType(messageType: string): string {
  if (messageType === 'voice') return 'chat-voice-notes';
  if (messageType === 'image') return 'chat-images';
  return 'chat-attachments';
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
