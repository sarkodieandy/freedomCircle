# FreedomCircle Laravel Admin Panel Notes

This folder is reserved for the separate Laravel/Filament admin panel. Supabase
admin setup details are in `README_SUPABASE_ADMIN.md`.
Monetization architecture and payment boundaries are documented in
`../README_MONETIZATION.md`.

Recommended setup:

1. Create a Laravel app in `admin_panel`.
2. Install Filament for admin resources.
3. Use Laravel Sanctum for admin authentication.
4. Connect Laravel to the Supabase PostgreSQL database with server-side credentials.
5. Never use the Supabase public anon key for admin moderation or payment actions.

Admin resources to create:

- Users and profiles
- Helpers/coaches and verification reviews
- Accountability groups and group members
- Community posts and comments
- Prayer requests and answered prayers
- Reports and flagged users
- Subscriptions and payments
- Plans and plan features
- Entitlements and manual grants
- Coach commissions, earnings, and payouts
- Paid programs, program purchases, and promo codes
- Revenue reports and paywall analytics
- App banners, devotion plans, and recovery plans

Suggested Filament resources:

- `PlanResource`
- `PlanFeatureResource`
- `ProfileResource`
- `HelperResource`
- `GroupResource`
- `CommunityPostResource`
- `PrayerRequestResource`
- `ReportResource`
- `SubscriptionResource`
- `PaymentResource`
- `EntitlementResource`
- `CoachCommissionResource`
- `CoachEarningResource`
- `CoachPayoutResource`
- `PaidProgramResource`
- `ProgramPurchaseResource`
- `PromoCodeResource`
- `RevenueReportResource`

Operational notes:

- Reports should be reviewed before content is removed where possible.
- Sensitive user recovery logs should not be exposed in broad admin tables.
- Admin audit logging is prepared through the `audit_logs` table and moderation
  triggers. Laravel should add explicit audit entries for custom admin actions.
- Paystack webhooks should route to `routes/api.php` and
  `PaystackWebhookController`; payment success must not be accepted from
  Flutter.
