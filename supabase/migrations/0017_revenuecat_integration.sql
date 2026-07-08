create table if not exists public.revenuecat_customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  revenuecat_app_user_id text unique not null,
  original_app_user_id text,
  management_url text,
  latest_customer_info jsonb not null default '{}',
  is_premium boolean not null default false,
  latest_expiration_at timestamptz,
  last_synced_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.revenuecat_events (
  id uuid primary key default gen_random_uuid(),
  event_id text unique not null,
  app_user_id text not null,
  user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  product_id text,
  entitlement_ids text[] not null default '{}',
  period_type text,
  purchased_at timestamptz,
  expiration_at timestamptz,
  environment text,
  store text,
  raw_event jsonb not null,
  processed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.user_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source text not null default 'revenuecat',
  entitlement_key text not null,
  is_active boolean not null default true,
  product_id text,
  starts_at timestamptz,
  expires_at timestamptz,
  raw_source jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, source, entitlement_key)
);

alter table public.subscriptions
  add column if not exists provider_product_id text,
  add column if not exists provider_subscription_id text,
  add column if not exists provider_customer_id text,
  add column if not exists current_period_start timestamptz,
  add column if not exists current_period_end timestamptz,
  add column if not exists metadata jsonb not null default '{}';

alter table public.subscriptions
  drop constraint if exists subscriptions_provider_check;

alter table public.subscriptions
  add constraint subscriptions_provider_check
  check (provider in ('app_store', 'google_play', 'paystack', 'manual', 'revenuecat'))
  not valid;

alter table public.paywall_events
  drop constraint if exists paywall_events_event_type_check;

alter table public.paywall_events
  add constraint paywall_events_event_type_check
  check (
    event_type in (
      'viewed',
      'clicked_upgrade',
      'plan_selected',
      'purchase_started',
      'purchased',
      'purchase_failed',
      'dismissed',
      'restored',
      'selected_package',
      'purchase_cancelled',
      'purchase_success',
      'restore_started',
      'restore_success',
      'restore_failed'
    )
  )
  not valid;

alter table public.revenue_events
  drop constraint if exists revenue_events_source_check;

alter table public.revenue_events
  add constraint revenue_events_source_check
  check (source in ('paystack', 'app_store', 'google_play', 'manual', 'revenuecat'))
  not valid;

create index if not exists idx_revenuecat_customers_user_id
  on public.revenuecat_customers (user_id);
create index if not exists idx_revenuecat_customers_app_user_id
  on public.revenuecat_customers (revenuecat_app_user_id);
create index if not exists idx_revenuecat_customers_premium
  on public.revenuecat_customers (is_premium, updated_at desc);

create index if not exists idx_revenuecat_events_user_type
  on public.revenuecat_events (user_id, event_type, created_at desc);
create index if not exists idx_revenuecat_events_app_user_id
  on public.revenuecat_events (app_user_id, created_at desc);
create index if not exists idx_revenuecat_events_event_type
  on public.revenuecat_events (event_type, created_at desc);

create index if not exists idx_user_entitlements_user_active
  on public.user_entitlements (user_id, entitlement_key, is_active);

drop trigger if exists set_revenuecat_customers_updated_at on public.revenuecat_customers;
create trigger set_revenuecat_customers_updated_at
before update on public.revenuecat_customers
for each row execute function public.set_updated_at();

drop trigger if exists set_user_entitlements_updated_at on public.user_entitlements;
create trigger set_user_entitlements_updated_at
before update on public.user_entitlements
for each row execute function public.set_updated_at();

alter table public.revenuecat_customers enable row level security;
alter table public.revenuecat_events enable row level security;
alter table public.user_entitlements enable row level security;

drop policy if exists revenuecat_customers_select_own on public.revenuecat_customers;
create policy revenuecat_customers_select_own
on public.revenuecat_customers
for select
using (auth.uid() = user_id);

drop policy if exists user_entitlements_select_own on public.user_entitlements;
create policy user_entitlements_select_own
on public.user_entitlements
for select
using (auth.uid() = user_id);

drop policy if exists subscriptions_select_own on public.subscriptions;
create policy subscriptions_select_own
on public.subscriptions
for select
using (auth.uid() = user_id);

drop policy if exists revenuecat_events_select_own on public.revenuecat_events;
create policy revenuecat_events_select_own
on public.revenuecat_events
for select
using (auth.uid() = user_id);

create or replace function public.revoke_revenuecat_entitlements(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.user_entitlements
  set is_active = false,
      updated_at = now()
  where user_id = target_user_id
    and source = 'revenuecat'
    and entitlement_key in (
      'premium_access',
      'recovery_goals_unlimited',
      'advanced_recovery_insights',
      'premium_groups',
      'unlimited_journal',
      'quiet_time_premium_library',
      'quiet_time_advanced_insights',
      'helper_matching',
      'guided_programs',
      'private_anonymous_controls'
    );
end;
$$;

create or replace function public.upsert_revenuecat_premium_entitlements(
  target_user_id uuid,
  target_product_id text,
  entitlement_expires_at timestamptz,
  source_payload jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  feature_key text;
  feature_keys text[] := array[
    'premium_access',
    'recovery_goals_unlimited',
    'advanced_recovery_insights',
    'premium_groups',
    'unlimited_journal',
    'quiet_time_premium_library',
    'quiet_time_advanced_insights',
    'helper_matching',
    'guided_programs',
    'private_anonymous_controls'
  ];
begin
  foreach feature_key in array feature_keys
  loop
    insert into public.user_entitlements (
      user_id,
      source,
      entitlement_key,
      is_active,
      product_id,
      starts_at,
      expires_at,
      raw_source
    ) values (
      target_user_id,
      'revenuecat',
      feature_key,
      true,
      target_product_id,
      now(),
      entitlement_expires_at,
      source_payload
    )
    on conflict (user_id, source, entitlement_key)
    do update
      set is_active = true,
          product_id = excluded.product_id,
          starts_at = excluded.starts_at,
          expires_at = excluded.expires_at,
          raw_source = excluded.raw_source,
          updated_at = now();
  end loop;
end;
$$;
