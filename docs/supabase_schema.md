# FreedomCircle Supabase Schema

FreedomCircle uses Supabase Auth for app users and PostgreSQL tables for product
data. The schema now lives in organized migrations under `supabase/migrations`.
Every public table has Row Level Security enabled in `0011_rls_policies.sql`.

Core tables:

- `profiles`: app user profile, role, anonymous mode, church metadata.
- `organizations` and `organization_members`: churches, ministries, and member
  administration.
- `user_onboarding_preferences`: private setup choices.
- `recovery_categories`: prayer discipline, fasting, Bible study, screen discipline, recovery support, and other focus areas.
- `user_recovery_goals`: user-owned goals, privacy level, streaks, and status.
- `recovery_logs`: private stayed-strong, struggled, and reset logs.
- `prayer_logs`, `fasting_logs`, `bible_study_logs`, `daily_checkins`: private
  spiritual discipline and check-in tracking.
- `groups`: accountability, church, premium, and private groups.
- `group_members`: membership role and approval status.
- `group_messages`: realtime chat messages with anonymous mode.
- `group_prayer_requests`, `group_checkins`, `group_resources`: group prayer
  wall, accountability check-ins, and shared resources.
- `community_posts`: moderated support wall posts.
- `post_comments` and `post_reactions`: comments and prayer/amen/encouragement
  reactions.
- `prayer_requests`: user and group prayer requests with answered status.
- `prayer_interactions`: "I prayed" events.
- `helpers`: verified helper/coach profiles and availability.
- `helper_availability`, `helper_reviews`, `support_requests`: scheduling,
  reviews, and private support requests.
- `coach_bookings`: support session requests and booking state.
- `journal_entries`: owner-only private journal entries.
- `plans` and `plan_features`: user, church, coach, and program plan catalog with database-driven feature flags and limits.
- `subscriptions`: user, premium, and organization plan state across App Store, Google Play, Paystack, and manual/admin sources.
- `payments`: pending and server-verified provider payment history for subscriptions, bookings, church plans, programs, and donations.
- `entitlements`: active user and organization feature access granted by subscriptions, admin grants, Paystack, in-app purchase verification, or promos.
- `paid_programs`, `program_modules`, `program_lessons`, and `program_purchases`: free, premium-included, and paid guided program access.
- `promo_codes`, `promo_redemptions`, `feature_usage`, `paywall_events`, and `revenue_events`: growth, conversion, usage-limit, and revenue tracking.
- `coach_commissions`, `coach_earnings`, and `coach_payouts`: helper marketplace commission and payout accounting.
- `notifications`: user-owned notification inbox.
- `reports`, `user_blocks`, `audit_logs`: safety, blocking, and moderation
  history.
- `app_content`, `app_settings`: admin-managed app copy, pricing, and content.

Supabase Realtime targets:

- `group_messages` for live chat.
- `group_members` for online/presence metadata.
- `prayer_requests` and `community_posts` for moderated live updates after approval.

Laravel admin connection:

- Laravel should use server-side database credentials, never the Supabase anon key.
- Admin actions should happen server-side through Filament resources or internal services.
- The admin panel should manage reports, helpers, groups, posts, prayer requests, subscriptions, and payments.

Client read views:

- `public_group_cards`
- `helper_public_profiles`
- `community_feed_posts`
- `user_dashboard_summary`
- `group_leaderboard_view`
- `user_subscription_status`
- `user_active_entitlements`
- `helper_earnings_summary`
- `admin_revenue_summary`
- `admin_mrr_summary`
- `admin_daily_revenue`
- `admin_subscription_breakdown`
- `admin_coach_commission_summary`
- `admin_program_sales_summary`
- `admin_paywall_conversion`

Private recovery logs and journal entries are not exposed through realtime or
public views.
