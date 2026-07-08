create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  plan_type text not null check (plan_type in ('user', 'church', 'coach', 'program')),
  billing_interval text not null default 'free' check (billing_interval in ('free', 'monthly', 'yearly', 'one_time')),
  price numeric(12, 2) not null default 0 check (price >= 0),
  currency text not null default 'GHS',
  trial_days integer not null default 0 check (trial_days >= 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.plan_features (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete cascade,
  feature_key text not null,
  feature_name text not null,
  feature_description text,
  feature_limit integer,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  unique (plan_id, feature_key)
);

create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  plan_id uuid references public.plans(id) on delete set null,
  entitlement_key text not null,
  entitlement_value jsonb not null default '{}',
  is_active boolean not null default true,
  starts_at timestamptz not null default now(),
  expires_at timestamptz,
  source text not null default 'free' check (source in ('free', 'iap', 'paystack', 'admin_grant', 'promo', 'manual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_id is not null or organization_id is not null)
);

create table if not exists public.paid_programs (
  id uuid primary key default gen_random_uuid(),
  creator_user_id uuid references auth.users(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  title text not null,
  slug text unique not null,
  description text,
  cover_image_url text,
  program_type text not null default 'general' check (program_type in ('recovery', 'prayer', 'fasting', 'bible_study', 'church', 'general')),
  price numeric(12, 2) not null default 0 check (price >= 0),
  currency text not null default 'GHS',
  is_premium_included boolean not null default false,
  status text not null default 'draft' check (status in ('draft', 'pending_review', 'active', 'hidden', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.program_modules (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.paid_programs(id) on delete cascade,
  title text not null,
  description text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.program_lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.program_modules(id) on delete cascade,
  title text not null,
  content text,
  audio_url text,
  video_url text,
  lesson_type text not null default 'text' check (lesson_type in ('text', 'audio', 'video', 'exercise')),
  duration_minutes integer not null default 0 check (duration_minutes >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.program_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  program_id uuid not null references public.paid_programs(id) on delete cascade,
  payment_id uuid references public.payments(id) on delete set null,
  access_status text not null default 'active' check (access_status in ('active', 'refunded', 'revoked')),
  purchased_at timestamptz not null default now(),
  expires_at timestamptz,
  unique (user_id, program_id)
);

create table if not exists public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  description text,
  discount_type text not null check (discount_type in ('percentage', 'fixed', 'free_trial')),
  discount_value numeric(12, 2) not null default 0 check (discount_value >= 0),
  applies_to_plan_id uuid references public.plans(id) on delete set null,
  max_redemptions integer check (max_redemptions is null or max_redemptions > 0),
  redeemed_count integer not null default 0 check (redeemed_count >= 0),
  valid_from timestamptz,
  valid_until timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.promo_redemptions (
  id uuid primary key default gen_random_uuid(),
  promo_code_id uuid not null references public.promo_codes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  redeemed_at timestamptz not null default now(),
  unique (promo_code_id, user_id)
);

create table if not exists public.feature_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  feature_key text not null,
  usage_count integer not null default 0 check (usage_count >= 0),
  usage_period text not null default 'monthly' check (usage_period in ('daily', 'weekly', 'monthly', 'lifetime')),
  period_start date not null default current_date,
  period_end date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, organization_id, feature_key, usage_period, period_start),
  check (user_id is not null or organization_id is not null)
);

create table if not exists public.paywall_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  screen text,
  feature_key text,
  event_type text not null check (event_type in ('viewed', 'clicked_upgrade', 'plan_selected', 'purchase_started', 'purchased', 'purchase_failed', 'dismissed', 'restored')),
  plan_code text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.revenue_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  event_type text not null,
  amount numeric(12, 2) not null default 0,
  currency text not null default 'GHS',
  source text not null,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.coach_commissions (
  id uuid primary key default gen_random_uuid(),
  helper_id uuid not null references public.helpers(id) on delete cascade,
  commission_type text not null default 'percentage' check (commission_type in ('percentage', 'fixed')),
  commission_value numeric(12, 2) not null default 20 check (commission_value >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coach_payouts (
  id uuid primary key default gen_random_uuid(),
  helper_id uuid not null references public.helpers(id) on delete cascade,
  amount numeric(12, 2) not null check (amount >= 0),
  currency text not null default 'GHS',
  status text not null default 'pending' check (status in ('pending', 'processing', 'paid', 'failed', 'cancelled')),
  payout_method text,
  payout_reference text,
  period_start date,
  period_end date,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.coach_earnings (
  id uuid primary key default gen_random_uuid(),
  helper_id uuid not null references public.helpers(id) on delete cascade,
  booking_id uuid references public.coach_bookings(id) on delete set null,
  payment_id uuid references public.payments(id) on delete set null,
  gross_amount numeric(12, 2) not null check (gross_amount >= 0),
  platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  net_amount numeric(12, 2) not null check (net_amount >= 0),
  currency text not null default 'GHS',
  status text not null default 'pending' check (status in ('pending', 'available', 'paid', 'reversed')),
  available_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (payment_id)
);

alter table public.subscriptions
  add column if not exists plan_id uuid references public.plans(id) on delete set null,
  add column if not exists plan_code text,
  add column if not exists provider_product_id text,
  add column if not exists provider_purchase_token text,
  add column if not exists cancel_at_period_end boolean not null default false,
  add column if not exists metadata jsonb not null default '{}';

update public.subscriptions
set plan_code = coalesce(plan_code, plan::text),
    provider = coalesce(provider, 'manual')
where plan_code is null or provider is null;

alter table public.subscriptions
  alter column plan_code set default 'free',
  alter column plan_code set not null,
  alter column provider set default 'manual',
  alter column provider set not null;

alter table public.subscriptions
  drop constraint if exists subscriptions_provider_check;

alter table public.subscriptions
  add constraint subscriptions_provider_check
  check (provider in ('app_store', 'google_play', 'paystack', 'manual'))
  not valid;

alter table public.payments
  add column if not exists subscription_id uuid references public.subscriptions(id) on delete set null,
  add column if not exists program_id uuid references public.paid_programs(id) on delete set null,
  add column if not exists provider_status text,
  add column if not exists payment_type text check (payment_type is null or payment_type in ('subscription', 'booking', 'program', 'church_plan', 'donation')),
  add column if not exists platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  add column if not exists provider_fee numeric(12, 2) not null default 0 check (provider_fee >= 0),
  add column if not exists net_amount numeric(12, 2) not null default 0 check (net_amount >= 0),
  add column if not exists verified_at timestamptz;

alter table public.payments
  drop constraint if exists payments_provider_check;

alter table public.payments
  add constraint payments_provider_check
  check (provider in ('paystack', 'app_store', 'google_play', 'manual'))
  not valid;

create index if not exists idx_plans_code_active on public.plans (code, is_active);
create index if not exists idx_plan_features_plan_feature on public.plan_features (plan_id, feature_key);
create index if not exists idx_entitlements_user_key_active on public.entitlements (user_id, entitlement_key, is_active);
create index if not exists idx_entitlements_org_key_active on public.entitlements (organization_id, entitlement_key, is_active);
create unique index if not exists idx_entitlements_user_active_unique
  on public.entitlements (
    user_id,
    entitlement_key,
    source,
    coalesce(plan_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where user_id is not null and is_active;
create unique index if not exists idx_entitlements_org_active_unique
  on public.entitlements (
    organization_id,
    entitlement_key,
    source,
    coalesce(plan_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where organization_id is not null and is_active;
create index if not exists idx_paid_programs_status_type on public.paid_programs (status, program_type, created_at desc);
create index if not exists idx_program_purchases_user_program on public.program_purchases (user_id, program_id, access_status);
create index if not exists idx_feature_usage_subject_key on public.feature_usage (user_id, organization_id, feature_key, usage_period, period_start);
create index if not exists idx_paywall_events_user_created on public.paywall_events (user_id, created_at desc);
create index if not exists idx_paywall_events_feature_type on public.paywall_events (feature_key, event_type, created_at desc);
create index if not exists idx_revenue_events_created_source on public.revenue_events (created_at desc, source);
create index if not exists idx_coach_earnings_helper_status on public.coach_earnings (helper_id, status, created_at desc);
create index if not exists idx_coach_payouts_helper_status on public.coach_payouts (helper_id, status, created_at desc);
create index if not exists idx_subscriptions_plan_code_status on public.subscriptions (plan_code, status);
create index if not exists idx_payments_type_status_created on public.payments (payment_type, status, created_at desc);

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'plans',
    'entitlements',
    'paid_programs',
    'program_modules',
    'program_lessons',
    'promo_codes',
    'feature_usage',
    'coach_commissions',
    'coach_payouts',
    'coach_earnings'
  ] loop
    execute format('drop trigger if exists set_%I_updated_at on public.%I', table_name, table_name);
    execute format('create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()', table_name, table_name);
  end loop;
end $$;

create or replace function public.verify_entitlement(user_uuid uuid, feature text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.entitlements e
    where e.user_id = user_uuid
      and e.entitlement_key = feature
      and e.is_active
      and e.starts_at <= now()
      and (e.expires_at is null or e.expires_at >= now())
  )
  or exists (
    select 1
    from public.subscriptions s
    join public.plans p on p.id = s.plan_id or p.code = s.plan_code
    join public.plan_features pf on pf.plan_id = p.id
    where s.user_id = user_uuid
      and s.status in ('active', 'trialing')
      and (s.current_period_end is null or s.current_period_end >= now())
      and pf.feature_key = feature
      and pf.is_enabled
      and p.is_active
  );
$$;

create or replace function public.verify_org_entitlement(org_uuid uuid, feature text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.entitlements e
    where e.organization_id = org_uuid
      and e.entitlement_key = feature
      and e.is_active
      and e.starts_at <= now()
      and (e.expires_at is null or e.expires_at >= now())
  )
  or exists (
    select 1
    from public.subscriptions s
    join public.plans p on p.id = s.plan_id or p.code = s.plan_code
    join public.plan_features pf on pf.plan_id = p.id
    where s.organization_id = org_uuid
      and s.status in ('active', 'trialing')
      and (s.current_period_end is null or s.current_period_end >= now())
      and pf.feature_key = feature
      and pf.is_enabled
      and p.is_active
  );
$$;

create or replace function public.grant_entitlements(subscription_uuid uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_count integer;
  updated_count integer;
begin
  with subscription_features as (
    select
      s.user_id,
      s.organization_id,
      p.id as plan_id,
      pf.feature_key as entitlement_key,
      jsonb_build_object('limit', pf.feature_limit) as entitlement_value,
      case
        when s.provider in ('app_store', 'google_play') then 'iap'
        when s.provider = 'paystack' then 'paystack'
        else 'manual'
      end as source,
      coalesce(s.current_period_start, now()) as starts_at,
      s.current_period_end as expires_at
    from public.subscriptions s
    join public.plans p on p.id = s.plan_id or p.code = s.plan_code
    join public.plan_features pf on pf.plan_id = p.id
    where s.id = subscription_uuid
      and s.status in ('active', 'trialing')
      and pf.is_enabled
  )
  update public.entitlements e
  set entitlement_value = sf.entitlement_value,
      starts_at = sf.starts_at,
      expires_at = sf.expires_at,
      is_active = true,
      updated_at = now()
  from subscription_features sf
  where e.entitlement_key = sf.entitlement_key
    and e.source = sf.source
    and e.plan_id = sf.plan_id
    and e.is_active
    and e.user_id is not distinct from sf.user_id
    and e.organization_id is not distinct from sf.organization_id;

  get diagnostics updated_count = row_count;

  with subscription_features as (
    select
      s.user_id,
      s.organization_id,
      p.id as plan_id,
      pf.feature_key as entitlement_key,
      jsonb_build_object('limit', pf.feature_limit) as entitlement_value,
      case
        when s.provider in ('app_store', 'google_play') then 'iap'
        when s.provider = 'paystack' then 'paystack'
        else 'manual'
      end as source,
      coalesce(s.current_period_start, now()) as starts_at,
      s.current_period_end as expires_at
    from public.subscriptions s
    join public.plans p on p.id = s.plan_id or p.code = s.plan_code
    join public.plan_features pf on pf.plan_id = p.id
    where s.id = subscription_uuid
      and s.status in ('active', 'trialing')
      and pf.is_enabled
  )
  insert into public.entitlements (
    user_id,
    organization_id,
    plan_id,
    entitlement_key,
    entitlement_value,
    source,
    starts_at,
    expires_at
  )
  select
    sf.user_id,
    sf.organization_id,
    sf.plan_id,
    sf.entitlement_key,
    sf.entitlement_value,
    sf.source,
    sf.starts_at,
    sf.expires_at
  from subscription_features sf
  where not exists (
    select 1
    from public.entitlements e
    where e.entitlement_key = sf.entitlement_key
      and e.source = sf.source
      and e.plan_id = sf.plan_id
      and e.is_active
      and e.user_id is not distinct from sf.user_id
      and e.organization_id is not distinct from sf.organization_id
  );

  get diagnostics inserted_count = row_count;
  return inserted_count + updated_count;
end;
$$;

create or replace function public.revoke_expired_entitlements()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.entitlements
  set is_active = false,
      updated_at = now()
  where is_active
    and expires_at is not null
    and expires_at < now();

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

create or replace function public.sync_subscription_status()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count integer;
begin
  update public.subscriptions
  set status = 'expired',
      updated_at = now()
  where status in ('active', 'trialing', 'past_due')
    and current_period_end is not null
    and current_period_end < now();

  perform public.revoke_expired_entitlements();
  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

create or replace function public.calculate_coach_commission(
  helper_uuid uuid,
  gross_amount numeric,
  provider_fee_amount numeric default 0
)
returns table (
  commission_percent numeric,
  platform_fee numeric,
  provider_fee numeric,
  net_amount numeric
)
language sql
stable
security definer
set search_path = public
as $$
  with commission as (
    select coalesce(
      (
        select cc.commission_value
        from public.coach_commissions cc
        where cc.helper_id = helper_uuid
          and cc.is_active
        order by cc.created_at desc
        limit 1
      ),
      (
        select nullif(value ->> 'percentage', '')::numeric
        from public.app_settings
        where key in ('coach_default_commission_percent', 'coach_commission_percentage')
        order by updated_at desc
        limit 1
      ),
      20
    ) as percentage
  )
  select
    percentage,
    round(gross_amount * percentage / 100, 2),
    coalesce(provider_fee_amount, 0),
    greatest(round(gross_amount - (gross_amount * percentage / 100) - coalesce(provider_fee_amount, 0), 2), 0)
  from commission;
$$;

create or replace function public.create_coach_earning(booking_uuid uuid, payment_uuid uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  booking_row public.coach_bookings%rowtype;
  payment_row public.payments%rowtype;
  commission_row record;
  earning_uuid uuid;
begin
  select * into booking_row from public.coach_bookings where id = booking_uuid;
  select * into payment_row from public.payments where id = payment_uuid;

  if booking_row.id is null or payment_row.id is null then
    raise exception 'Booking or payment not found.';
  end if;

  select * into commission_row
  from public.calculate_coach_commission(
    booking_row.helper_id,
    payment_row.amount,
    payment_row.provider_fee
  );

  insert into public.coach_earnings (
    helper_id,
    booking_id,
    payment_id,
    gross_amount,
    platform_fee,
    net_amount,
    currency,
    status,
    available_at
  )
  values (
    booking_row.helper_id,
    booking_uuid,
    payment_uuid,
    payment_row.amount,
    commission_row.platform_fee,
    commission_row.net_amount,
    payment_row.currency,
    'pending',
    now() + interval '7 days'
  )
  on conflict (payment_id) do update
  set platform_fee = excluded.platform_fee,
      net_amount = excluded.net_amount,
      updated_at = now()
  returning id into earning_uuid;

  return earning_uuid;
end;
$$;

create or replace function public.mark_earning_available(earning_uuid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.coach_earnings
  set status = 'available',
      updated_at = now()
  where id = earning_uuid
    and status = 'pending'
    and (available_at is null or available_at <= now());
end;
$$;

create or replace function public.create_payout_batch(
  helper_uuid uuid,
  start_date date,
  end_date date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  payout_uuid uuid;
  payout_amount numeric;
  payout_currency text;
begin
  select coalesce(sum(net_amount), 0), coalesce(max(currency), 'GHS')
  into payout_amount, payout_currency
  from public.coach_earnings
  where helper_id = helper_uuid
    and status = 'available'
    and created_at::date between start_date and end_date;

  if payout_amount <= 0 then
    raise exception 'No available earnings for payout.';
  end if;

  insert into public.coach_payouts (
    helper_id,
    amount,
    currency,
    status,
    period_start,
    period_end
  )
  values (
    helper_uuid,
    payout_amount,
    payout_currency,
    'pending',
    start_date,
    end_date
  )
  returning id into payout_uuid;

  return payout_uuid;
end;
$$;

create or replace function public.prepare_successful_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  booking_row public.coach_bookings%rowtype;
  commission_row record;
begin
  if new.status = 'successful' and old.status is distinct from new.status then
    new.verified_at = coalesce(new.verified_at, now());

    if new.booking_id is not null then
      select * into booking_row from public.coach_bookings where id = new.booking_id;
      if booking_row.id is not null then
        select * into commission_row
        from public.calculate_coach_commission(
          booking_row.helper_id,
          new.amount,
          new.provider_fee
        );

        new.platform_fee = commission_row.platform_fee;
        new.net_amount = commission_row.net_amount;
      end if;
    elsif new.net_amount = 0 then
      new.net_amount = greatest(new.amount - new.provider_fee - new.platform_fee, 0);
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.handle_successful_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'successful' and old.status is distinct from new.status then
    insert into public.revenue_events (
      user_id,
      organization_id,
      event_type,
      amount,
      currency,
      source,
      metadata
    )
    values (
      new.user_id,
      new.organization_id,
      coalesce(new.payment_type, 'payment') || '_successful',
      new.amount,
      new.currency,
      new.provider,
      jsonb_build_object('payment_id', new.id, 'provider_reference', new.provider_reference)
    );

    if new.subscription_id is not null then
      perform public.grant_entitlements(new.subscription_id);
    end if;

    if new.booking_id is not null then
      perform public.create_coach_earning(new.booking_id, new.id);
    end if;

    if new.program_id is not null and new.user_id is not null then
      insert into public.program_purchases (user_id, program_id, payment_id, access_status)
      values (new.user_id, new.program_id, new.id, 'active')
      on conflict (user_id, program_id) do update
      set access_status = 'active',
          payment_id = excluded.payment_id,
          purchased_at = now();
    end if;
  end if;

  return new;
end;
$$;

create or replace function public.protect_payment_immutability()
returns trigger
language plpgsql
as $$
begin
  if new.amount <> old.amount
    or new.currency <> old.currency
    or new.provider <> old.provider
    or coalesce(new.provider_reference, '') <> coalesce(old.provider_reference, '')
    or coalesce(new.user_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.user_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.organization_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.organization_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.booking_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.booking_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.subscription_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.subscription_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.program_id, '00000000-0000-0000-0000-000000000000'::uuid) <> coalesce(old.program_id, '00000000-0000-0000-0000-000000000000'::uuid)
    or coalesce(new.payment_type, '') <> coalesce(old.payment_type, '')
  then
    raise exception 'Payment ownership and financial source fields are immutable.';
  end if;

  return new;
end;
$$;

drop trigger if exists prepare_successful_payment on public.payments;
create trigger prepare_successful_payment
  before update on public.payments
  for each row execute function public.prepare_successful_payment();

drop trigger if exists handle_successful_payment on public.payments;
create trigger handle_successful_payment
  after update on public.payments
  for each row execute function public.handle_successful_payment();

alter table public.plans enable row level security;
alter table public.plan_features enable row level security;
alter table public.entitlements enable row level security;
alter table public.paid_programs enable row level security;
alter table public.program_modules enable row level security;
alter table public.program_lessons enable row level security;
alter table public.program_purchases enable row level security;
alter table public.promo_codes enable row level security;
alter table public.promo_redemptions enable row level security;
alter table public.feature_usage enable row level security;
alter table public.paywall_events enable row level security;
alter table public.revenue_events enable row level security;
alter table public.coach_commissions enable row level security;
alter table public.coach_payouts enable row level security;
alter table public.coach_earnings enable row level security;

drop policy if exists plans_read_active on public.plans;
create policy plans_read_active on public.plans
  for select to anon, authenticated
  using (is_active or public.is_admin(auth.uid()));

drop policy if exists plans_admin_all on public.plans;
create policy plans_admin_all on public.plans
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists plan_features_read_active on public.plan_features;
create policy plan_features_read_active on public.plan_features
  for select to anon, authenticated
  using (
    (
      is_enabled
      and exists (select 1 from public.plans p where p.id = plan_id and p.is_active)
    )
    or public.is_admin(auth.uid())
  );

drop policy if exists plan_features_admin_all on public.plan_features;
create policy plan_features_admin_all on public.plan_features
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists entitlements_select_subject on public.entitlements;
create policy entitlements_select_subject on public.entitlements
  for select to authenticated
  using (
    user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  );

drop policy if exists entitlements_admin_all on public.entitlements;
create policy entitlements_admin_all on public.entitlements
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists paid_programs_select_visible on public.paid_programs;
create policy paid_programs_select_visible on public.paid_programs
  for select to authenticated
  using (
    status = 'active'
    or creator_user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  );

drop policy if exists paid_programs_creator_admin_all on public.paid_programs;
create policy paid_programs_creator_admin_all on public.paid_programs
  for all to authenticated
  using (
    creator_user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  )
  with check (
    creator_user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  );

drop policy if exists program_modules_visible on public.program_modules;
create policy program_modules_visible on public.program_modules
  for select to authenticated
  using (
    exists (
      select 1 from public.paid_programs pp
      where pp.id = program_id
        and (
          pp.status = 'active'
          or pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  );

drop policy if exists program_modules_admin_creator_all on public.program_modules;
create policy program_modules_admin_creator_all on public.program_modules
  for all to authenticated
  using (
    exists (
      select 1 from public.paid_programs pp
      where pp.id = program_id
        and (
          pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  )
  with check (
    exists (
      select 1 from public.paid_programs pp
      where pp.id = program_id
        and (
          pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  );

drop policy if exists program_lessons_visible on public.program_lessons;
create policy program_lessons_visible on public.program_lessons
  for select to authenticated
  using (
    exists (
      select 1
      from public.program_modules pm
      join public.paid_programs pp on pp.id = pm.program_id
      where pm.id = module_id
        and (
          pp.price = 0
          or (
            pp.is_premium_included
            and public.verify_entitlement(auth.uid(), 'guided_programs')
          )
          or exists (
            select 1 from public.program_purchases pu
            where pu.program_id = pp.id
              and pu.user_id = auth.uid()
              and pu.access_status = 'active'
              and (pu.expires_at is null or pu.expires_at >= now())
          )
          or pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  );

drop policy if exists program_lessons_admin_creator_all on public.program_lessons;
create policy program_lessons_admin_creator_all on public.program_lessons
  for all to authenticated
  using (
    exists (
      select 1
      from public.program_modules pm
      join public.paid_programs pp on pp.id = pm.program_id
      where pm.id = module_id
        and (
          pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  )
  with check (
    exists (
      select 1
      from public.program_modules pm
      join public.paid_programs pp on pp.id = pm.program_id
      where pm.id = module_id
        and (
          pp.creator_user_id = auth.uid()
          or public.is_org_admin(pp.organization_id, auth.uid())
          or public.is_admin(auth.uid())
        )
    )
  );

drop policy if exists program_purchases_owner_read on public.program_purchases;
create policy program_purchases_owner_read on public.program_purchases
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists program_purchases_admin_all on public.program_purchases;
create policy program_purchases_admin_all on public.program_purchases
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists promo_codes_admin_all on public.promo_codes;
create policy promo_codes_admin_all on public.promo_codes
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists promo_redemptions_owner_read on public.promo_redemptions;
create policy promo_redemptions_owner_read on public.promo_redemptions
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists promo_redemptions_admin_all on public.promo_redemptions;
create policy promo_redemptions_admin_all on public.promo_redemptions
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists feature_usage_subject_all on public.feature_usage;
create policy feature_usage_subject_all on public.feature_usage
  for all to authenticated
  using (
    user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  )
  with check (
    user_id = auth.uid()
    or public.is_org_admin(organization_id, auth.uid())
    or public.is_admin(auth.uid())
  );

drop policy if exists paywall_events_insert_own on public.paywall_events;
create policy paywall_events_insert_own on public.paywall_events
  for insert to authenticated
  with check (user_id = auth.uid() or user_id is null);

drop policy if exists paywall_events_read_own_or_admin on public.paywall_events;
create policy paywall_events_read_own_or_admin on public.paywall_events
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists revenue_events_admin_read on public.revenue_events;
create policy revenue_events_admin_read on public.revenue_events
  for select to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists revenue_events_admin_insert on public.revenue_events;
create policy revenue_events_admin_insert on public.revenue_events
  for insert to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists coach_commissions_admin_all on public.coach_commissions;
create policy coach_commissions_admin_all on public.coach_commissions
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists coach_earnings_helper_read on public.coach_earnings;
create policy coach_earnings_helper_read on public.coach_earnings
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or exists (
      select 1 from public.helpers h
      where h.id = helper_id
        and h.user_id = auth.uid()
    )
  );

drop policy if exists coach_earnings_admin_all on public.coach_earnings;
create policy coach_earnings_admin_all on public.coach_earnings
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists coach_payouts_helper_read on public.coach_payouts;
create policy coach_payouts_helper_read on public.coach_payouts
  for select to authenticated
  using (
    public.is_admin(auth.uid())
    or exists (
      select 1 from public.helpers h
      where h.id = helper_id
        and h.user_id = auth.uid()
    )
  );

drop policy if exists coach_payouts_admin_all on public.coach_payouts;
create policy coach_payouts_admin_all on public.coach_payouts
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

create or replace view public.user_active_entitlements
with (security_invoker = true)
as
select
  e.user_id,
  e.organization_id,
  e.entitlement_key,
  e.entitlement_value,
  e.expires_at,
  p.code as plan_code,
  p.name as plan_name
from public.entitlements e
left join public.plans p on p.id = e.plan_id
where e.is_active
  and e.starts_at <= now()
  and (e.expires_at is null or e.expires_at >= now());

create or replace view public.helper_earnings_summary
with (security_invoker = true)
as
select
  helper_id,
  sum(gross_amount) as gross_earnings,
  sum(platform_fee) as platform_fees,
  sum(net_amount) as net_earnings,
  sum(net_amount) filter (where status = 'available') as available_balance,
  sum(net_amount) filter (where status = 'pending') as pending_balance,
  sum(net_amount) filter (where status = 'paid') as paid_balance,
  max(updated_at) as updated_at
from public.coach_earnings
group by helper_id;

create or replace view public.admin_daily_revenue
with (security_invoker = true)
as
select
  created_at::date as revenue_date,
  currency,
  source,
  sum(amount) as total_revenue,
  count(*) as event_count
from public.revenue_events
group by created_at::date, currency, source;

create or replace view public.admin_revenue_summary
with (security_invoker = true)
as
select
  coalesce(sum(amount), 0) as lifetime_revenue,
  coalesce(sum(amount) filter (where created_at::date = current_date), 0) as daily_revenue,
  coalesce(sum(amount) filter (where created_at >= date_trunc('month', now())), 0) as month_revenue,
  count(*) filter (where event_type like '%successful') as successful_events,
  count(*) filter (where event_type like '%failed') as failed_events
from public.revenue_events;

create or replace view public.admin_mrr_summary
with (security_invoker = true)
as
select
  coalesce(sum(
    case
      when p.billing_interval = 'monthly' then p.price
      when p.billing_interval = 'yearly' then p.price / 12
      else 0
    end
  ), 0) as mrr,
  coalesce(sum(
    case
      when p.billing_interval = 'monthly' then p.price * 12
      when p.billing_interval = 'yearly' then p.price
      else 0
    end
  ), 0) as arr,
  count(*) as active_subscriptions
from public.subscriptions s
join public.plans p on p.id = s.plan_id or p.code = s.plan_code
where s.status in ('active', 'trialing');

create or replace view public.admin_subscription_breakdown
with (security_invoker = true)
as
select
  coalesce(s.plan_code, s.plan::text) as plan_code,
  s.status,
  count(*) as subscription_count
from public.subscriptions s
group by coalesce(s.plan_code, s.plan::text), s.status;

create or replace view public.admin_coach_commission_summary
with (security_invoker = true)
as
select
  count(*) as earning_count,
  coalesce(sum(gross_amount), 0) as gross_bookings,
  coalesce(sum(platform_fee), 0) as platform_commission,
  coalesce(sum(net_amount), 0) as coach_net
from public.coach_earnings;

create or replace view public.admin_program_sales_summary
with (security_invoker = true)
as
select
  pp.id as program_id,
  pp.title,
  count(pu.id) as purchase_count,
  coalesce(sum(pay.amount), 0) as gross_sales
from public.paid_programs pp
left join public.program_purchases pu on pu.program_id = pp.id
left join public.payments pay on pay.id = pu.payment_id
group by pp.id, pp.title;

create or replace view public.admin_paywall_conversion
with (security_invoker = true)
as
select
  feature_key,
  count(*) filter (where event_type = 'viewed') as views,
  count(*) filter (where event_type = 'clicked_upgrade') as upgrade_clicks,
  count(*) filter (where event_type = 'purchased') as purchases,
  case
    when count(*) filter (where event_type = 'viewed') = 0 then 0
    else round(
      (count(*) filter (where event_type = 'purchased'))::numeric
      / (count(*) filter (where event_type = 'viewed'))::numeric
      * 100,
      2
    )
  end as conversion_rate
from public.paywall_events
group by feature_key;
