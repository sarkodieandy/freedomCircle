# FreedomCircle Screen Coverage

This checklist maps the product prompt to the implemented Flutter files.

- Splash Screen: `mobile_app/lib/features/onboarding/splash_screen.dart`
- Onboarding Flow: `mobile_app/lib/features/onboarding/onboarding_screen.dart`
- Auth Welcome: `mobile_app/lib/features/auth/auth_welcome_screen.dart`
- Login/Register: `mobile_app/lib/features/auth/auth_screen.dart`
- Forgot Password: `mobile_app/lib/features/auth/forgot_password_screen.dart`
- OTP Verification: `mobile_app/lib/features/auth/otp_verification_screen.dart`
- Personal Setup Flow: `mobile_app/lib/features/onboarding/setup_flow_screen.dart`
- Home Dashboard: `mobile_app/lib/features/home/home_dashboard.dart`
- Daily Check-in: `mobile_app/lib/features/checkin/daily_check_in_sheet.dart`
- Recovery Tracker: `mobile_app/lib/features/recovery/recovery_tracker_screen.dart`
- Accountability Groups: `mobile_app/lib/features/groups/groups_screen.dart`
- Group Detail: `mobile_app/lib/features/groups/group_detail_screen.dart`
- Group Chat: `mobile_app/lib/features/chat/chat_screen.dart`
- Community Wall: `mobile_app/lib/features/community/community_wall_screen.dart`
- Prayer Wall: `mobile_app/lib/features/prayer/prayer_wall_screen.dart`
- Helper/Coach Directory: `mobile_app/lib/features/helpers/coach_directory_screen.dart`
- Helper/Coach Profile: `mobile_app/lib/features/helpers/helper_profile_screen.dart`
- Booking Flow: `mobile_app/lib/features/helpers/booking_screen.dart`
- Journal: `mobile_app/lib/features/journal/journal_screen.dart`
- Subscription/Pricing: `mobile_app/lib/features/subscriptions/subscription_screen.dart`
- Profile: `mobile_app/lib/features/profile/profile_screen.dart`
- Settings: `mobile_app/lib/features/settings/settings_screen.dart`
- Notifications: `mobile_app/lib/features/notifications/notifications_screen.dart`
- Reports and Safety: `mobile_app/lib/features/safety/safety_screen.dart`
- Global Search: `mobile_app/lib/features/search/search_screen.dart`
- Empty/Loading/Error/Offline States: `mobile_app/lib/core/widgets/empty_states_screen.dart` and `mobile_app/lib/core/widgets/common_widgets.dart`

Navigation coverage:

- Main bottom navigation includes Home, Groups, Community, Prayer, and Profile.
- Home links to Recovery, Prayer, Groups, Journal, Helpers, Search, Subscription, Notifications, and state previews.
- Group Detail links to full Chat.
- Helper Profile links to Booking.
- Profile links to Goals/Recovery, Groups, Helper, Subscription, Settings, Notifications, and Safety.

Backend/admin coverage:

- Supabase-ready data models live in `mobile_app/lib/data/models/`.
- Repository boundary lives in `mobile_app/lib/data/repositories/freedom_repository.dart`.
- Supabase service boundary lives in `mobile_app/lib/data/supabase/supabase_service.dart`.
- SQL schema migration lives in `supabase/migrations/20260707000000_initial_freedomcircle_schema.sql`.
- Laravel admin notes live in `admin_panel/README.md`.
