# FreedomCircle Backend Connection Guide

## Environment Variables

### Flutter (`mobile_app`)
Pass secrets at runtime, never commit keys:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `USE_MOCK_DATA` (optional, default: `false`)

Run example:

```bash
cd mobile_app
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=USE_MOCK_DATA=false
```

### Laravel (`admin_panel`)
Keep secure server-side credentials in `.env` only:

- `SUPABASE_DB_URL` or direct Postgres credentials
- `SUPABASE_SERVICE_ROLE_KEY` (server only)
- `PAYSTACK_SECRET_KEY`
- `PAYSTACK_WEBHOOK_SECRET`

## Supabase Initialization

- Flutter config: `mobile_app/lib/data/supabase/supabase_config.dart`
- Flutter service: `mobile_app/lib/data/supabase/supabase_service.dart`

`SupabaseService` exposes:

- `isLoggedIn`
- `currentUserId`
- `currentUser`
- `currentSession`
- `authStateChanges`
- `signOut()`
- `refreshSession()`

## Repository Structure

Primary repository layer lives in:

- `mobile_app/lib/data/repositories/`

UI should call controllers/providers, then repositories, then Supabase.
Direct Supabase calls from UI should be removed progressively.

## Feature-to-Table Mapping (Current)

- Auth: `auth.users`, `profiles`
- Onboarding: `user_onboarding_preferences`, `profiles.onboarding_completed`
- Recovery: `recovery_categories`, `user_recovery_goals`, `recovery_logs`, `recovery_milestones`
- Check-ins: `daily_checkins`, `group_checkins`
- Prayer: `prayer_requests`, `prayer_interactions`
- Groups: `groups`, `group_members`, `group_messages`, `group_resources`
- Community: `community_posts`, `post_comments`, `post_reactions`
- Helpers/Support: `helpers`, `helper_availability`, `support_requests`
- Booking/Payments: `coach_bookings`, `payments`
- Journal: `journal_entries`
- Quiet Time: `quiet_time_categories`, `quiet_time_sessions`, `quiet_time_steps`, `quiet_time_history`, `quiet_time_favorites`
- Subscriptions/Monetization: `plans`, `plan_features`, `subscriptions`, `entitlements`, `paywall_events`
- Notifications: `notifications`, `notification_preferences`, `user_push_tokens`
- Safety: `reports`, `user_blocks`

## Realtime Usage

- Implemented streams:
  - `group_messages`
  - `notifications`
- Placeholder streams (to migrate to Presence/Broadcast):
  - typing events
  - group presence

Never expose private journals, private recovery logs, or private check-ins over shared realtime channels.

## Storage Usage

Bucket intent:

- `avatars`
- `group-covers`
- `organization-assets`
- `community-attachments`
- `journal-attachments`
- `helper-documents`
- `app-content`

Current upload helper exists for avatar upload in `ProfileRepository.uploadAvatar`.

## Payments and Verification

Rules:

- Flutter must never trust payment success by itself.
- Flutter can only create `pending` payment placeholders.
- Laravel verifies Paystack webhook signatures and marks final payment status server-side.
- Entitlements must be granted/revoked server-side only.

## RLS Testing Checklist

1. Login/signup and profile bootstrap
2. Save onboarding and confirm routing behavior
3. Create recovery goal/log and verify owner-only visibility
4. Daily check-in create/update
5. Join group and test private group access
6. Send group message and realtime receipt
7. Community post/comment/reaction
8. Create prayer request and interaction
9. Helper profile and booking create
10. Journal create/read and verify owner-only access
11. Quiet Time completion writes history
12. Paywall event tracking write
13. Notifications read/realtime
14. Report and block user workflows
15. Logout

RLS must enforce:

- No cross-user journal access
- No cross-user private recovery/check-in access
- No private group chat access for non-members
- No self-granted premium entitlement
- No client-side payment success mutation

## Mock Data Policy

- Controlled by `USE_MOCK_DATA` define via `AppEnv.useMockData`.
- Do not silently mix random mock data with live backend data.

## Production TODOs

- Replace remaining UI `showComingSoon(...)` handlers with concrete flows where backend exists.
- Complete auth OTP target wiring (email/phone capture + verify route path).
- Move any feature-local Supabase repository logic into `data/repositories` layer.
- Implement full Presence/Broadcast channels for typing/online indicators.
- Add robust form-level validation and field-level error mapping on all forms.
- Add full integration tests for repository methods and RLS behavior.
