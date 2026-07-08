# FreedomCircle Laravel Supabase Admin

The Laravel admin panel should connect to the same Supabase PostgreSQL project using server-side credentials only.

Use server-only environment variables:

```env
SUPABASE_URL=https://bwfwzhzjvggntmyceezs.supabase.co
SUPABASE_SERVICE_ROLE_KEY=server_only_do_not_use_in_flutter
SUPABASE_DB_URL=postgresql_connection_string_here
```

Never expose the service role key, database password, payment secrets, or Supabase access token to Flutter.

## Admin Responsibilities

- User and profile moderation
- Helper/coach verification
- Group moderation and member support
- Report review and safety escalation
- Subscription and payment verification
- App content and settings management
- Audit log review

## Payment Rule

Flutter may create a pending payment request, but Laravel must verify Paystack or any provider callback before setting `payments.status = successful`. On success, Laravel should update `payments` and related `subscriptions`; Supabase triggers then grant rows in `entitlements`, create paid program purchases, record revenue events, and create coach earnings.
