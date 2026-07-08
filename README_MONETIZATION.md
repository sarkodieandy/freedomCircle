# FreedomCircle Monetization Architecture

FreedomCircle monetization is split across Flutter, Supabase, and Laravel so users cannot unlock premium access from the client and payment success is always verified by a trusted server.

## Provider Responsibilities

App Store and Google Play handle digital in-app purchases:

- Premium Monthly and Premium Yearly subscriptions.
- Digital premium groups, guided programs, advanced insights, and personal app features.
- Purchase restoration from the mobile app.
- Receipt or purchase-token validation should be completed server-side before Supabase subscriptions are activated.

Paystack handles server/web payments:

- Church and organization SaaS plans.
- Paid helper/coach bookings.
- Paid programs sold outside store-managed in-app purchase rules.
- Web/admin payment links, receipts, and manual payment review.

Laravel handles trusted payment operations:

- Creates Paystack checkout sessions from server-side routes.
- Receives `/api/webhooks/paystack`.
- Verifies Paystack webhook signatures.
- Re-verifies transactions with Paystack before marking payments successful.
- Updates `payments`, creates or updates `subscriptions`, and lets Supabase triggers grant entitlements, program purchases, revenue events, and coach earnings.

Flutter handles product presentation only:

- Reads plans, feature access, programs, and revenue previews from Supabase.
- Shows premium paywalls and upgrade prompts.
- Creates only pending payment requests where needed.
- Never marks a payment successful and never inserts entitlements.

## Entitlement Flow

1. A user, church admin, or helper starts a checkout.
2. Flutter or Laravel creates a pending `payments` row with the correct owner, type, provider reference, and related `subscription_id`, `booking_id`, or `program_id`.
3. Paystack, App Store, or Google Play confirms payment to trusted server code.
4. Laravel or a server-side verifier updates the payment to `successful`.
5. Supabase trigger `handle_successful_payment()` logs `revenue_events`, grants plan entitlements, creates `coach_earnings`, or creates `program_purchases`.
6. Flutter checks access only through `MonetizationService`, backed by `verify_entitlement()` and `verify_org_entitlement()`.

## RLS Protection

- Users can read only their own payments, subscriptions, program purchases, and entitlements.
- Organization admins can read their organization monetization records.
- Helpers can read their own earnings and payouts.
- Only admin/service-role server code can edit plans, prices, commissions, payouts, revenue events, and entitlements.
- Client inserts into `payments` are limited to pending user-owned requests.
- Payment source fields are immutable after creation, so a client cannot swap amount, owner, booking, program, or subscription during verification.

## Coach Commissions

Coach booking revenue uses:

```text
gross_amount = payment.amount
platform_fee = gross_amount * commission_percentage / 100
provider_fee = provider fee from Paystack when available
net_amount = gross_amount - platform_fee - provider_fee
```

The default commission percentage lives in `app_settings.coach_default_commission_percent`. Admins can override a helper with `coach_commissions`. Successful booking payments create `coach_earnings`; available earnings can be grouped with `create_payout_batch()`.

## Church Subscriptions

Church Starter, Growth, and Pro are organization plans billed through Laravel and Paystack. Successful payment updates the organization subscription and grants organization entitlements such as private groups, announcements, reports, admin roles, helper assignment, and branding.

## Paid Programs

Programs can be free, premium-included, or one-time paid. A successful program payment creates `program_purchases`. Premium-included programs still check `guided_programs`; paid programs remain separate purchases unless `is_premium_included = true`.

## Testing Free vs Premium

Recommended checks:

- Free account can use community, prayer wall, basic check-ins, limited journals, limited goals, and limited group joins.
- Free account sees a soft paywall for advanced insights, unlimited journals, helper matching, premium groups, and premium-included programs.
- Premium account passes `MonetizationService.hasFeature()` for seeded premium features.
- Church admin without active organization subscription cannot access private church SaaS features.
- Active church subscription passes `verify_org_entitlement()`.
- Paid booking payment creates coach earnings only after server-verified success.
- Paid program access appears only after `program_purchases.access_status = active`.

## Secret Handling

- Keep Supabase service-role keys, Supabase access tokens, Paystack secret keys, App Store shared secrets, and Google Play service credentials out of source control.
- Use `.env.example` with placeholders only.
- Rotate secrets in the provider dashboard, then update production environment variables.
- After rotation, redeploy Laravel/server functions and run a webhook smoke test.
- Never put secrets in Flutter, seed files, migrations, docs, screenshots, or command history.

## Admin Modules

The Laravel admin panel should expose:

- Plans and plan features.
- Subscriptions and payments.
- Entitlements and manual grants.
- Coach commissions, earnings, and payouts.
- Paid programs and program purchases.
- Promo codes and redemptions.
- Revenue reports and paywall analytics.

The scaffolded files are:

- `admin_panel/app/Services/SupabaseAdminService.php`
- `admin_panel/app/Http/Controllers/Webhooks/PaystackWebhookController.php`
- `admin_panel/routes/api.php`

## Local Validation

Run:

```sh
cd mobile_app
dart format lib test
flutter analyze
flutter test
```

For Supabase:

```sh
supabase db reset
supabase db lint --local
```

Local Supabase validation requires Docker. Remote deploy should use `supabase db push` only after reviewing migrations and environment configuration.
