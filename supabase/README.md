# FreedomCircle Supabase

This folder contains the production Supabase schema for FreedomCircle: auth profiles, organizations, recovery tracking, prayer and fasting logs, groups, chat, community posts, helpers, bookings, subscriptions, payments, monetization plans, entitlements, paid programs, coach earnings, notifications, reports, storage, realtime, indexes, and RLS.

## Secrets

Do not commit real Supabase keys. Keep local values in an untracked `.env` or terminal environment.

Required local variables:

```sh
SUPABASE_ACCESS_TOKEN=local_cli_only
SUPABASE_URL=https://bwfwzhzjvggntmyceezs.supabase.co
SUPABASE_ANON_KEY=your_anon_or_publishable_key_here
SUPABASE_SERVICE_ROLE_KEY=server_only_do_not_use_in_flutter
SUPABASE_DB_URL=postgresql_connection_string_here
```

## CLI Workflow

```sh
supabase login
supabase link --project-ref bwfwzhzjvggntmyceezs
supabase migration new initial_schema
supabase db reset
supabase db push
supabase db push --include-seed
supabase gen types typescript --project-id bwfwzhzjvggntmyceezs
```

All remote schema changes should go through migration files. Do not edit the remote database manually unless the same change is captured in a migration immediately after.

## Realtime

Realtime is enabled for:

- `group_messages`
- `group_members`
- `notifications`
- `prayer_interactions`
- `community_posts`

Use Supabase Broadcast/Presence from the Flutter client for typing indicators, group online presence, and live support room previews. Private recovery logs and journal entries are not added to realtime.

## Storage Buckets

Configured buckets:

- `avatars`: public read, owner folder write.
- `group-covers`: public read, group owner/moderator write.
- `organization-assets`: public read, organization admin write.
- `community-attachments`: authenticated read, owner folder write.
- `journal-attachments`: owner-only.
- `helper-documents`: helper owner or admin only.
- `app-content`: public read, admin write.

## Security Notes

- Every public table has RLS enabled.
- Private journals, private recovery logs, spiritual logs, and personal check-ins are owner-only.
- Group chat and group resources require approved membership.
- Payment success is server verified. Flutter can create a pending payment request, but Laravel/backend must verify the provider callback and update final status.
- Monetization access is controlled by `plans`, `plan_features`, `subscriptions`, `entitlements`, and the `verify_entitlement()` / `verify_org_entitlement()` functions.
- Successful trusted payment updates trigger revenue logging, entitlement grants, coach earnings, and paid program purchases.
- Anonymous community feed reads should use `community_feed_posts`, which hides author identity for anonymous posts.
