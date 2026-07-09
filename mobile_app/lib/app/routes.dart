import 'package:flutter/material.dart';

import 'app_router.dart';
import '../core/utils/app_logger.dart';
import '../data/models/accountability_group.dart';
import '../data/models/helper_profile.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/group_chat_screen.dart';
import '../features/helpers/coach_directory_screen.dart';
import '../features/helpers/booking_screen.dart';
import '../features/helpers/helper_profile_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/monetization/admin_revenue_dashboard_screen.dart';
import '../features/monetization/church_plan_pricing_screen.dart';
import '../features/monetization/coach_earnings_screen.dart';
import '../features/monetization/paid_program_detail_screen.dart';
import '../features/monetization/premium_paywall_screen.dart';
import '../features/monetization/subscription_management_screen.dart';
import '../features/notifications/notification_detail_screen.dart';
import '../features/notifications/notification_preferences_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/launch_flow.dart';
import '../features/quiet_time/quiet_time_history_screen.dart';
import '../features/quiet_time/quiet_time_home_screen.dart';
import '../features/recovery/recovery_tracker_screen.dart';
import '../features/safety/safety_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/subscriptions/subscription_screen.dart';
import '../features/groups/create_group_screen.dart';
import '../features/groups/group_detail_screen.dart';
import '../data/models/notification_item.dart';
import 'navigation_shell.dart';

class AppRoutes {
  const AppRoutes._();

  static const launch = '/launch';
  static const authWelcome = '/auth/welcome';
  static const auth = '/auth';
  static const setup = '/setup';
  static const home = '/home';
  static const groups = '/groups';
  static const groupsCreate = '/groups/create';
  static const groupDetail = '/groups/detail';
  static const groupChat = '/groups/chat';
  static const community = '/community';
  static const prayer = '/prayer';
  static const profile = '/profile';
  static const recovery = '/recovery';
  static const search = '/search';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const notificationDetail = '/notification-detail';
  static const notificationPreferences = '/notification-preferences';
  static const safety = '/safety';
  static const chat = '/chat';
  static const helpers = '/helpers';
  static const helperProfile = '/helpers/profile';
  static const booking = '/helpers/booking';
  static const journal = '/journal';
  static const subscriptions = '/subscriptions';
  static const premium = '/premium';
  static const subscriptionManagement = '/subscription-management';
  static const churchPlans = '/church-plans';
  static const coachEarnings = '/coach-earnings';
  static const paidProgram = '/paid-program';
  static const revenueDashboard = '/revenue-dashboard';
  static const quietTime = '/quiet-time';
  static const quietTimeHistory = '/quiet-time-history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    AppLogger.navigation(
      'onGenerateRoute called',
      data: {
        'route': settings.name,
        'args_type': settings.arguments?.runtimeType.toString(),
      },
    );

    final isKnownRoute = {
      AppRoutes.launch,
      AppRoutes.authWelcome,
      AppRoutes.auth,
      AppRoutes.setup,
      AppRoutes.home,
      AppRoutes.groups,
      AppRoutes.groupsCreate,
      AppRoutes.groupDetail,
      AppRoutes.groupChat,
      AppRoutes.community,
      AppRoutes.prayer,
      AppRoutes.profile,
      AppRoutes.recovery,
      AppRoutes.search,
      AppRoutes.settings,
      AppRoutes.notifications,
      AppRoutes.notificationPreferences,
      AppRoutes.notificationDetail,
      AppRoutes.safety,
      AppRoutes.chat,
      AppRoutes.helpers,
      AppRoutes.helperProfile,
      AppRoutes.booking,
      AppRoutes.journal,
      AppRoutes.subscriptions,
      AppRoutes.premium,
      AppRoutes.subscriptionManagement,
      AppRoutes.churchPlans,
      AppRoutes.coachEarnings,
      AppRoutes.paidProgram,
      AppRoutes.revenueDashboard,
      AppRoutes.quietTime,
      AppRoutes.quietTimeHistory,
    }.contains(settings.name);

    if (!isKnownRoute) {
      AppLogger.warning(
        'Missing route fallback used',
        tag: 'NAVIGATION',
        data: {'route': settings.name},
      );
    }

    final homeArgs = settings.arguments is NavigationShellRouteArgs
        ? settings.arguments as NavigationShellRouteArgs
        : settings.arguments is int
        ? NavigationShellRouteArgs(initialTab: settings.arguments as int)
        : const NavigationShellRouteArgs();

    final page = switch (settings.name) {
      AppRoutes.launch => const LaunchFlow(),
      AppRoutes.authWelcome => const LaunchFlow(),
      AppRoutes.auth => const LaunchFlow(),
      AppRoutes.setup => const LaunchFlow(),
      AppRoutes.home => NavigationShell(initialTab: homeArgs.initialTab),
      AppRoutes.groups => const NavigationShell(initialTab: 1),
      AppRoutes.groupsCreate => const CreateGroupScreen(),
      AppRoutes.groupDetail =>
        settings.arguments is AccountabilityGroup
            ? GroupDetailScreen(
                group: settings.arguments! as AccountabilityGroup,
              )
            : settings.arguments is GroupDetailRouteArgs
            ? GroupDetailScreen(
                group: (settings.arguments! as GroupDetailRouteArgs).group,
              )
            : const NavigationShell(initialTab: 1),
      AppRoutes.groupChat =>
        settings.arguments is GroupChatRouteArgs
            ? GroupChatScreen(
                groupId: (settings.arguments! as GroupChatRouteArgs).groupId,
                title: (settings.arguments! as GroupChatRouteArgs).title,
                prayerGroup:
                    (settings.arguments! as GroupChatRouteArgs).prayerGroup,
              )
            : const ChatListScreen(),
      AppRoutes.community => const NavigationShell(initialTab: 2),
      AppRoutes.prayer => const NavigationShell(initialTab: 3),
      AppRoutes.profile => const NavigationShell(initialTab: 4),
      AppRoutes.recovery => const RecoveryTrackerScreen(),
      AppRoutes.search => const SearchScreen(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.notifications => const NotificationsScreen(),
      AppRoutes.notificationPreferences =>
        const NotificationPreferencesScreen(),
      AppRoutes.notificationDetail =>
        settings.arguments is NotificationItem
            ? NotificationDetailScreen(
                notification: settings.arguments! as NotificationItem,
              )
            : const NotificationsScreen(),
      AppRoutes.safety => const SafetyScreen(),
      AppRoutes.chat => const ChatListScreen(),
      AppRoutes.helpers => const CoachDirectoryScreen(),
      AppRoutes.helperProfile =>
        settings.arguments is HelperProfile
            ? HelperProfileScreen(helper: settings.arguments! as HelperProfile)
            : settings.arguments is HelperProfileRouteArgs
            ? HelperProfileScreen(
                helper: (settings.arguments! as HelperProfileRouteArgs).helper,
              )
            : const CoachDirectoryScreen(),
      AppRoutes.booking =>
        settings.arguments is HelperProfile
            ? BookingScreen(helper: settings.arguments! as HelperProfile)
            : settings.arguments is BookingRouteArgs
            ? BookingScreen(
                helper: (settings.arguments! as BookingRouteArgs).helper,
              )
            : const CoachDirectoryScreen(),
      AppRoutes.journal => const JournalScreen(),
      AppRoutes.subscriptions => const SubscriptionScreen(),
      AppRoutes.premium => const PremiumPaywallScreen(),
      AppRoutes.subscriptionManagement => const SubscriptionManagementScreen(),
      AppRoutes.churchPlans => const ChurchPlanPricingScreen(),
      AppRoutes.coachEarnings => const CoachEarningsScreen(),
      AppRoutes.paidProgram => const PaidProgramDetailScreen(),
      AppRoutes.revenueDashboard => const AdminRevenueDashboardScreen(),
      AppRoutes.quietTime => const QuietTimeHomeScreen(),
      AppRoutes.quietTimeHistory => const QuietTimeHistoryScreen(),
      _ => const SearchScreen(),
    };

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, animation, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, .04),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}
