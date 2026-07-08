import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type JsonMap = Record<string, unknown>;

type RevenueCatEventPayload = {
  event?: {
    id?: string;
    type?: string;
    app_user_id?: string;
    original_app_user_id?: string;
    product_id?: string;
    entitlement_ids?: string[];
    period_type?: string;
    purchased_at_ms?: number;
    expiration_at_ms?: number;
    store?: string;
    environment?: string;
    aliases?: string[];
  };
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET') ?? '';

const supabase = createClient(supabaseUrl, serviceRoleKey);

serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  if (!isAuthorized(request)) {
    return json({ error: 'Unauthorized' }, 401);
  }

  const payload = (await request.json().catch(() => ({}))) as RevenueCatEventPayload;
  const event = payload.event;
  if (!event?.id || !event.type || !event.app_user_id) {
    return json({ error: 'Invalid RevenueCat event payload' }, 400);
  }

  const userId = normalizeUserId(event.app_user_id);
  const purchasedAt = toIso(event.purchased_at_ms);
  const expirationAt = toIso(event.expiration_at_ms);
  const entitlementIds = event.entitlement_ids ?? [];

  const existingEvent = await supabase
    .from('revenuecat_events')
    .select('id')
    .eq('event_id', event.id)
    .maybeSingle();

  if (existingEvent.data?.id) {
    return json({ processed: true, duplicate: true }, 200);
  }

  const eventInsert = await supabase.from('revenuecat_events').insert({
    event_id: event.id,
    app_user_id: event.app_user_id,
    user_id: userId,
    event_type: event.type,
    product_id: event.product_id,
    entitlement_ids: entitlementIds,
    period_type: event.period_type,
    purchased_at: purchasedAt,
    expiration_at: expirationAt,
    environment: event.environment,
    store: event.store,
    raw_event: payload,
  });

  if (eventInsert.error) {
    return json({ error: eventInsert.error.message }, 500);
  }

  if (!userId) {
    return json({ processed: true, warning: 'No UUID app_user_id mapping.' }, 200);
  }

  const premiumStillActive = isPremiumEventActive(event.type, expirationAt);

  const customerUpdate = await supabase.from('revenuecat_customers').upsert(
    {
      user_id: userId,
      revenuecat_app_user_id: event.app_user_id,
      original_app_user_id: event.original_app_user_id,
      management_url: null,
      latest_customer_info: payload,
      is_premium: premiumStillActive,
      latest_expiration_at: expirationAt,
      last_synced_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'user_id' },
  );

  if (customerUpdate.error) {
    return json({ error: customerUpdate.error.message }, 500);
  }

  const subscriptionStatus = mapSubscriptionStatus(event.type, premiumStillActive);

  const subscriptionUpdate = await supabase.from('subscriptions').upsert(
    {
      user_id: userId,
      plan_code: premiumStillActive ? 'premium_revenuecat' : 'free',
      status: subscriptionStatus,
      provider: 'revenuecat',
      provider_product_id: event.product_id,
      provider_subscription_id: event.id,
      provider_customer_id: event.app_user_id,
      current_period_start: purchasedAt,
      current_period_end: expirationAt,
      metadata: payload,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'user_id' },
  );

  if (subscriptionUpdate.error) {
    return json({ error: subscriptionUpdate.error.message }, 500);
  }

  if (premiumStillActive) {
    const upsertEntitlements = await supabase.rpc(
      'upsert_revenuecat_premium_entitlements',
      {
        target_user_id: userId,
        target_product_id: event.product_id ?? null,
        entitlement_expires_at: expirationAt,
        source_payload: payload,
      },
    );

    if (upsertEntitlements.error) {
      return json({ error: upsertEntitlements.error.message }, 500);
    }
  } else {
    const revokeEntitlements = await supabase.rpc('revoke_revenuecat_entitlements', {
      target_user_id: userId,
    });

    if (revokeEntitlements.error) {
      return json({ error: revokeEntitlements.error.message }, 500);
    }
  }

  const notificationInsert = await supabase.rpc('create_notification', {
    target_user_id: userId,
    notification_type: notificationTypeFor(event.type, premiumStillActive),
    notification_title: notificationTitleFor(event.type, premiumStillActive),
    notification_body: notificationBodyFor(event.type, premiumStillActive),
    notification_data: {
      source: 'revenuecat',
      event_id: event.id,
      product_id: event.product_id,
      status: subscriptionStatus,
    },
    notification_priority:
      event.type === 'BILLING_ISSUE' ? 'high' : 'normal',
  });

  if (notificationInsert.error) {
    return json({ error: notificationInsert.error.message }, 500);
  }

  const revenueEventInsert = await supabase.from('revenue_events').insert({
    user_id: userId,
    event_type: analyticsEventTypeFor(event.type),
    amount: 0,
    currency: 'USD',
    source: 'revenuecat',
    metadata: {
      event_id: event.id,
      product_id: event.product_id,
      environment: event.environment,
      store: event.store,
      premium_active: premiumStillActive,
    },
  });

  if (revenueEventInsert.error) {
    return json({ error: revenueEventInsert.error.message }, 500);
  }

  return json({ processed: true }, 200);
});

function isAuthorized(request: Request): boolean {
  if (!webhookSecret) return false;
  const auth = request.headers.get('authorization') ?? '';
  const expected = `Bearer ${webhookSecret}`;
  return auth === expected;
}

function normalizeUserId(appUserId: string): string | null {
  const uuidRegex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(appUserId) ? appUserId : null;
}

function toIso(value?: number): string | null {
  if (!value || Number.isNaN(value)) return null;
  return new Date(value).toISOString();
}

function isPremiumEventActive(type: string, expirationAt: string | null): boolean {
  if (
    [
      'INITIAL_PURCHASE',
      'RENEWAL',
      'UNCANCELLATION',
      'NON_RENEWING_PURCHASE',
      'PRODUCT_CHANGE',
      'TRANSFER',
      'SUBSCRIPTION_PAUSED',
    ].includes(type)
  ) {
    return true;
  }

  if (type === 'BILLING_ISSUE') {
    return expirationAt != null && new Date(expirationAt).getTime() > Date.now();
  }

  if (type === 'CANCELLATION') {
    return expirationAt != null && new Date(expirationAt).getTime() > Date.now();
  }

  return false;
}

function mapSubscriptionStatus(type: string, isPremium: boolean): string {
  if (type === 'BILLING_ISSUE') return isPremium ? 'active' : 'past_due';
  if (type === 'CANCELLATION') return isPremium ? 'active' : 'cancelled';
  if (type === 'EXPIRATION') return 'expired';
  return isPremium ? 'active' : 'inactive';
}

function notificationTypeFor(type: string, isPremium: boolean): string {
  if (type === 'BILLING_ISSUE') return 'payment_failed';
  if (type === 'EXPIRATION') return 'subscription_cancelled';
  if (type === 'CANCELLATION' && !isPremium) return 'subscription_cancelled';
  if (type === 'CANCELLATION' && isPremium) return 'subscription_expiring';
  return 'subscription_success';
}

function notificationTitleFor(type: string, isPremium: boolean): string {
  if (type === 'BILLING_ISSUE') return 'Subscription issue';
  if (type === 'EXPIRATION' || (type === 'CANCELLATION' && !isPremium)) {
    return 'Subscription cancelled';
  }
  if (type === 'CANCELLATION' && isPremium) {
    return 'Subscription expiring';
  }
  return 'Premium activated';
}

function notificationBodyFor(type: string, isPremium: boolean): string {
  if (type === 'BILLING_ISSUE') {
    return 'Please review your subscription to keep Premium active.';
  }
  if (type === 'EXPIRATION' || (type === 'CANCELLATION' && !isPremium)) {
    return 'Your Premium access is no longer active.';
  }
  if (type === 'CANCELLATION' && isPremium) {
    return 'Your Premium access will remain active until the current period ends.';
  }
  return 'Your Premium access is now active.';
}

function analyticsEventTypeFor(type: string): string {
  switch (type) {
    case 'INITIAL_PURCHASE':
      return 'subscription_started';
    case 'RENEWAL':
      return 'subscription_renewed';
    case 'CANCELLATION':
      return 'subscription_cancelled';
    case 'EXPIRATION':
      return 'subscription_expired';
    case 'BILLING_ISSUE':
      return 'billing_issue';
    default:
      return 'subscription_updated';
  }
}

function json(body: JsonMap, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
