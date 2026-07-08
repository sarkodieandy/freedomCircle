import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type JsonMap = Record<string, unknown>;

type OtpAction = 'send' | 'verify';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const africasTalkingApiKey = Deno.env.get('AFRICASTALKING_API_KEY') ?? '';
const africasTalkingUsername = Deno.env.get('AFRICASTALKING_USERNAME') ?? 'sandbox';
const africasTalkingSenderId = Deno.env.get('AFRICASTALKING_SENDER_ID') ?? '';
const africasTalkingAppName = Deno.env.get('AFRICASTALKING_APP_NAME') ?? 'Doc consult';
const otpHashSecret = Deno.env.get('OTP_HASH_SECRET') ?? serviceRoleKey;

const OTP_LENGTH = 6;
const OTP_TTL_MINUTES = 10;
const OTP_MAX_ATTEMPTS = 5;
const OTP_RESEND_COOLDOWN_SECONDS = 45;

const supabase = createClient(supabaseUrl, serviceRoleKey);

serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ message: 'Method not allowed' }, 405);
  }

  const payload = (await request.json().catch(() => ({}))) as JsonMap;
  const action = String(payload.action ?? '') as OtpAction;

  if (action !== 'send' && action !== 'verify') {
    return json({ message: 'action must be send or verify' }, 400);
  }

  const phoneRaw = String(payload.phone ?? '').trim();
  const purpose = String(payload.purpose ?? 'auth_login').trim() || 'auth_login';
  const userId = optionalString(payload.user_id);

  try {
    const phoneE164 = normalizePhone(phoneRaw);

    if (action === 'send') {
      const result = await sendOtp({ phoneE164, purpose, userId });
      return json(result, 200);
    }

    const code = String(payload.code ?? '').trim();
    if (!/^\d{6}$/.test(code)) {
      return json({ verified: false, message: 'OTP code must be 6 digits.' }, 422);
    }

    const verifyResult = await verifyOtp({ phoneE164, code, purpose, userId });
    return json(verifyResult, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'OTP operation failed.';
    return json({ message, verified: false }, 422);
  }
});

async function sendOtp(args: {
  phoneE164: string;
  purpose: string;
  userId: string | null;
}): Promise<JsonMap> {
  if (!africasTalkingApiKey) {
    throw new Error("Africa's Talking API key is not configured.");
  }

  const lastOtp = await latestOtp(args.phoneE164, args.purpose);
  if (lastOtp?.created_at) {
    const elapsed = Date.now() - new Date(lastOtp.created_at).getTime();
    if (elapsed < OTP_RESEND_COOLDOWN_SECONDS * 1000) {
      throw new Error('Please wait before requesting another OTP.');
    }
  }

  const otpCode = generateOtp();
  const message = `Your ${africasTalkingAppName} OTP is ${otpCode}. It expires in 10 minutes.`;
  await sendSms(args.phoneE164, message);

  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

  const insert = await supabase.from('otp_verifications').insert({
    phone_e164: args.phoneE164,
    purpose: args.purpose,
    provider: 'africastalking',
    code_hash: await hashOtp(args.phoneE164, otpCode),
    attempts_remaining: OTP_MAX_ATTEMPTS,
    status: 'pending',
    expires_at: expiresAt,
    metadata: {
      user_id: args.userId,
      channel: 'sms',
    },
  });

  if (insert.error) {
    throw new Error(insert.error.message);
  }

  return {
    message: 'OTP sent successfully.',
    expires_in_seconds: OTP_TTL_MINUTES * 60,
    retry_in_seconds: OTP_RESEND_COOLDOWN_SECONDS,
  };
}

async function verifyOtp(args: {
  phoneE164: string;
  code: string;
  purpose: string;
  userId: string | null;
}): Promise<JsonMap> {
  const otp = await latestOtp(args.phoneE164, args.purpose);

  if (!otp) {
    throw new Error('No OTP request found.');
  }

  const otpId = String(otp.id ?? '');
  if (!otpId) {
    throw new Error('OTP record is invalid.');
  }

  if (String(otp.status ?? '') !== 'pending') {
    throw new Error('OTP is no longer valid.');
  }

  if (new Date(String(otp.expires_at)).getTime() < Date.now()) {
    await updateOtp(otpId, { status: 'expired' });
    throw new Error('OTP has expired.');
  }

  const attemptsRemaining = Number(otp.attempts_remaining ?? 0);
  if (attemptsRemaining <= 0) {
    await updateOtp(otpId, { status: 'locked' });
    throw new Error('Too many attempts. Request a new OTP.');
  }

  const expected = String(otp.code_hash ?? '');
  const provided = await hashOtp(args.phoneE164, args.code);

  if (expected !== provided) {
    const nextAttempts = Math.max(0, attemptsRemaining - 1);
    await updateOtp(otpId, {
      attempts_remaining: nextAttempts,
      status: nextAttempts === 0 ? 'locked' : 'pending',
    });

    throw new Error('Invalid OTP code.');
  }

  await updateOtp(otpId, {
    status: 'verified',
    verified_at: new Date().toISOString(),
    metadata: {
      user_id: args.userId,
      verified_with: 'sms',
      channel: 'sms',
    },
  });

  return {
    verified: true,
    message: 'OTP verified successfully.',
  };
}

async function latestOtp(phoneE164: string, purpose: string): Promise<JsonMap | null> {
  const result = await supabase
    .from('otp_verifications')
    .select('*')
    .eq('phone_e164', phoneE164)
    .eq('purpose', purpose)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (result.error) {
    throw new Error(result.error.message);
  }

  return (result.data as JsonMap | null) ?? null;
}

async function updateOtp(otpId: string, values: JsonMap): Promise<void> {
  const result = await supabase.from('otp_verifications').update(values).eq('id', otpId);
  if (result.error) {
    throw new Error(result.error.message);
  }
}

async function sendSms(phoneE164: string, message: string): Promise<void> {
  const body = new URLSearchParams();
  body.set('username', africasTalkingUsername);
  body.set('to', phoneE164);
  body.set('message', message);
  if (africasTalkingSenderId) {
    body.set('from', africasTalkingSenderId);
  }

  const response = await fetch('https://api.africastalking.com/version1/messaging', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      apiKey: africasTalkingApiKey,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Failed to send OTP SMS: ${text}`);
  }

  const data = (await response.json()) as JsonMap;
  const recipients = (((data.SMSMessageData as JsonMap | undefined)?.Recipients ?? []) as unknown[]) ?? [];
  if (!Array.isArray(recipients) || recipients.length === 0) {
    throw new Error('Africa\'s Talking did not return recipients.');
  }
}

function generateOtp(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 1000000;
  return value.toString().padStart(OTP_LENGTH, '0');
}

async function hashOtp(phoneE164: string, otpCode: string): Promise<string> {
  const data = new TextEncoder().encode(`${phoneE164}:${otpCode}`);
  const keyData = new TextEncoder().encode(otpHashSecret);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, data);
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function normalizePhone(phone: string): string {
  let clean = phone.replace(/\s+/g, '');
  if (!clean) {
    throw new Error('Phone number is required.');
  }

  if (!clean.startsWith('+')) {
    if (clean.startsWith('0')) {
      clean = `+233${clean.slice(1)}`;
    } else {
      clean = `+${clean}`;
    }
  }

  if (!/^\+[1-9][0-9]{7,14}$/.test(clean)) {
    throw new Error('Phone number must be in valid international format.');
  }

  return clean;
}

function optionalString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed ? trimmed : null;
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    },
  });
}
