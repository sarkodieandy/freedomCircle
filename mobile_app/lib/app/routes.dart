import 'package:flutter/material.dart';

import '../features/chat/chat_list_screen.dart';
import '../features/helpers/coach_directory_screen.dart';
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
import '../features/quiet_time/quiet_time_history_screen.dart';
import '../features/quiet_time/quiet_time_home_screen.dart';
import '../features/safety/safety_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/subscriptions/subscription_screen.dart';
import '../data/models/notification_item.dart';

class AppRoutes {
  const AppRoutes._();

  static const search = '/search';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const notificationDetail = '/notification-detail';
  static const notificationPreferences = '/notification-preferences';
  static const safety = '/safety';
  static const chat = '/chat';
  static const helpers = '/helpers';
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
    final page = switch (settings.name) {
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
