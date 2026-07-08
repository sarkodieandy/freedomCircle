create table if not exists public.otp_verifications (
  id uuid primary key default gen_random_uuid(),
  phone_e164 text not null,
  purpose text not null default 'auth_login',
  provider text not null default 'africastalking',
  code_hash text not null,
  attempts_remaining integer not null default 5 check (attempts_remaining >= 0),
  status text not null default 'pending' check (status in ('pending', 'verified', 'expired', 'locked')),
  expires_at timestamptz not null,
  verified_at timestamptz,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_otp_verifications_phone_status_created
  on public.otp_verifications (phone_e164, status, created_at desc);

create index if not exists idx_otp_verifications_expires_at
  on public.otp_verifications (expires_at);

drop trigger if exists set_otp_verifications_updated_at on public.otp_verifications;
create trigger set_otp_verifications_updated_at
before update on public.otp_verifications
for each row execute function public.set_updated_at();

alter table public.otp_verifications enable row level security;
