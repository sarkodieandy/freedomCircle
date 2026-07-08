# FreedomCircle RevenueCat Integration

This document explains how mobile subscriptions are implemented with RevenueCat and synced to Supabase.

## Architecture

- Mobile app subscriptions: RevenueCat + App Store / Google Play.
- Source of truth for mobile subscription entitlement: RevenueCat customer entitlement `premium`.
- Backend sync: RevenueCat webhook -> Supabase Edge Function `revenuecat-webhook` -> Supabase tables.
- Flutter never uses Supabase service role and never grants premium entitlements authoritatively.
- Paystack/Laravel remains for coach bookings, church SaaS billing, and web/server payments.

## RevenueCat Dashboard Setup

1. Create a RevenueCat project for FreedomCircle.
2. Add iOS app.
3. Add Android app.
4. Configure App Store Connect products.
5. Configure Google Play subscription products.
6. Create entitlement:
   - identifier: `premium`
   - display name: Premium Access
7. Create offering:
   - identifier: `default`
8. Add packages:
   - monthly package
   - annual package
9. Map products to packages.
10. Configure webhook URL to Supabase function endpoint.
11. Configure webhook authorization secret in server environment only.

## Product ID Placeholders

Replace these placeholders with your real App Store / Google Play IDs:

- `freedomcircle_premium_monthly`
- `freedomcircle_premium_yearly`

## Flutter Configuration

Do not hardcode keys in source files.

Use `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=REVENUECAT_IOS_API_KEY=... \
  --dart-define=REVENUECAT_ANDROID_API_KEY=...
```

Files:

- `mobile_app/lib/core/config/revenuecat_config.dart`
- `mobile_app/lib/core/services/revenuecat_service.dart`
- `mobile_app/lib/data/repositories/subscription_repository.dart`

## Identity Mapping

- RevenueCat `appUserID` must be Supabase auth user UUID.
- Do not use email as `appUserID`.

Login flow:

1. Supabase auth signs in.
2. Read Supabase user UUID.
3. RevenueCat `logIn(userUUID)`.
4. Refresh `CustomerInfo`.
5. Sync to Supabase.

Logout flow:

1. Clear local premium cache.
2. RevenueCat `logOut()`.
3. Supabase sign out.

## Supabase Schema and Security

Migration: `supabase/migrations/0017_revenuecat_integration.sql`

Tables:

- `revenuecat_customers`
- `revenuecat_events`
- `user_entitlements`
- `subscriptions` updated for provider `revenuecat`

RLS:

- Users can read only their own `revenuecat_customers` row.
- Users can read only their own `user_entitlements` rows.
- Users can read only their own `subscriptions` row.
- Users cannot authoritatively create premium entitlements.

## Webhook Sync

Function: `supabase/functions/revenuecat-webhook/index.ts`

Environment variables (server-only):

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `REVENUECAT_WEBHOOK_SECRET`

Webhook processing responsibilities:

1. Verify auth header.
2. Parse event.
3. Idempotency check by `event_id`.
4. Persist raw event in `revenuecat_events`.
5. Upsert `revenuecat_customers`.
6. Upsert `subscriptions` provider state.
7. Upsert/revoke `user_entitlements` by entitlement activity.
8. Insert subscription notification.
9. Insert `revenue_events` analytics entry.

Handled event types:

- `INITIAL_PURCHASE`
- `RENEWAL`
- `CANCELLATION`
- `UNCANCELLATION`
- `NON_RENEWING_PURCHASE`
- `EXPIRATION`
- `BILLING_ISSUE`
- `PRODUCT_CHANGE`
- `TRANSFER`
- `SUBSCRIPTION_PAUSED`

## Paywall and Subscription UI

RevenueCat-driven screens:

- `mobile_app/lib/features/monetization/premium_paywall_screen.dart`
- `mobile_app/lib/features/monetization/subscription_management_screen.dart`

Behavior:

- Offerings load from RevenueCat (not hardcoded prices).
- Localized price strings shown from store product metadata.
- Purchase, cancel, fail, and restore states handled gracefully.
- Restore purchase flow supported.
- Premium status refresh supported.

## Feature Gating

`MonetizationService` combines:

- RevenueCat premium status
- Supabase entitlement checks
- Supabase app setting limits (free caps)

Premium feature keys:

- `premium_access`
- `recovery_goals_unlimited`
- `advanced_recovery_insights`
- `premium_groups`
- `unlimited_journal`
- `quiet_time_premium_library`
- `quiet_time_advanced_insights`
- `helper_matching`
- `guided_programs`
- `private_anonymous_controls`

## Offline Behavior

- App can use last known cached premium status for UI hints.
- Server-side privileged actions still require backend verification.
- Restore purchases requires network.

## Testing Checklist

1. RevenueCat initializes on iOS and Android.
2. Missing RevenueCat key throws clear dev error.
3. Supabase UUID used as RevenueCat `appUserID`.
4. Login triggers RevenueCat `logIn`.
5. Logout clears local premium state.
6. Offerings load from RevenueCat.
7. Monthly and yearly localized prices display.
8. Purchase start/cancel/success/failure flow works.
9. Restore purchases works.
10. Premium unlock reflects in UI and entitlements.
11. Webhook verifies authorization.
12. Webhook idempotency works (`event_id` unique).
13. Webhook updates customers/events/subscriptions/entitlements.
14. Expiration removes premium when entitlement no longer active.
15. RLS blocks user-side entitlement tampering.

## App Store / Google Play Tasks Remaining

- Create real subscription products in App Store Connect and Google Play Console.
- Ensure products are approved and available for sandbox/test tracks.
- Map product IDs to RevenueCat packages.
- Test on physical devices with sandbox testers.

## Secret Rotation

- Rotate `REVENUECAT_WEBHOOK_SECRET` in RevenueCat dashboard and server env together.
- Rotate Supabase service role key only in server environment and function config.
- Never ship secrets in Flutter source.