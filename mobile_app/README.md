# FreedomCircle Flutter App

FreedomCircle uses Supabase for auth, database, realtime, and storage. The app
does not hardcode Supabase secrets.

## Running With Supabase

Pass Supabase config at runtime:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://bwfwzhzjvggntmyceezs.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_or_publishable_key_here
```

Do not put the service role key, database URL, Supabase access token, or payment
provider secrets in Flutter. Those belong only in Laravel/backend runtime
configuration.

Push notification provider secrets also stay out of Flutter. The mobile app can
register a device token in `user_push_tokens`, but FCM/APNs delivery runs through
Supabase Edge Functions or Laravel server code.

## Data Layer

- `lib/data/supabase`: Supabase config and initialization.
- `lib/data/models`: typed models for profiles, recovery, groups, community,
  prayer, helpers, journals, subscriptions, payments, notifications, and reports.
- `lib/data/repositories`: Supabase-ready repositories with CRUD and realtime
  streams.
- `lib/data/providers`: lightweight repository provider for switching mock data
  to Supabase-backed data.

Use `community_feed_posts` for community reads so anonymous posts do not expose
author identity to normal client queries.

Notifications use `NotificationRepository.listenToNotifications()` and
`listenToUnreadCount()` for Supabase Realtime updates scoped to the signed-in
user.
