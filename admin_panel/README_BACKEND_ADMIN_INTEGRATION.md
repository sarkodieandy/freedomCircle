# FreedomCircle Admin Panel Integration Notes

## Scope
Laravel admin is the trusted server-side authority for moderation, payments, and entitlements.

## Required Environment Variables

Set only in server `.env`:

- `SUPABASE_DB_URL` (or host/user/pass/db/port)
- `SUPABASE_SERVICE_ROLE_KEY`
- `PAYSTACK_SECRET_KEY`
- `PAYSTACK_WEBHOOK_SECRET`

Never expose these values to Flutter clients.

## Admin Domains

Implement/administer modules for:

- Users and profiles
- Groups and group moderation
- Group messages moderation
- Community posts/comments moderation
- Prayer requests moderation
- Helpers/coaches verification
- Reports review and safety actions
- Subscriptions/plans/features/entitlements
- Payments and webhook verification
- Paid programs and content
- Quiet Time categories/sessions/steps
- Audit logs

## Payment Rules

- Flutter creates placeholder pending payment record only.
- Laravel verifies webhook signatures from Paystack.
- Laravel updates payment status and grants entitlements transactionally.
- Never trust client-reported payment success.

## Entitlements Rules

- Grant/revoke only server-side.
- Keep immutable audit trail.
- Validate plan-feature mapping before assignment.

## Moderation Rules

- Reports can trigger hide/remove content and user block actions.
- Preserve moderation metadata in audit logs.
- Apply role checks for all admin actions.

## API/Workflow TODOs

- Add explicit admin endpoints/jobs for:
  - webhook processing
  - entitlement sync
  - helper approval
  - content moderation queue
  - Quiet Time catalog publishing
  - paid program publishing
