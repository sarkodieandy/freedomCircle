create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  plan public.subscription_plan not null,
  status public.subscription_status not null default 'active',
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  started_at timestamptz not null default now(),
  current_period_start timestamptz,
  current_period_end timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (user_id is not null or organization_id is not null)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  booking_id uuid references public.coach_bookings(id) on delete set null,
  amount numeric(12, 2) not null check (amount >= 0),
  currency text not null default 'GHS',
  provider text not null,
  provider_reference text unique,
  status public.payment_status not null default 'pending',
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.premium_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete cascade,
  entitlement_key text not null,
  active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, organization_id, entitlement_key),
  check (user_id is not null or organization_id is not null)
);

alter table public.coach_bookings
  add constraint coach_bookings_payment_fk
  foreign key (payment_id) references public.payments(id) on delete set null;
