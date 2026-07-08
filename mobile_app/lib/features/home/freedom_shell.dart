import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/routes.dart';
import '../../core/services/app_state.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../community/community_wall_screen.dart';
import '../checkin/daily_check_in_sheet.dart';
import '../groups/groups_screen.dart';
import '../notifications/widgets/notification_badge.dart';
import '../prayer/prayer_wall_screen.dart';
import '../profile/profile_screen.dart';
import 'home_dashboard.dart';

class FreedomShell extends StatefulWidget {
  const FreedomShell({super.key});

  @override
  State<FreedomShell> createState() => _FreedomShellState();
}

class _FreedomShellState extends State<FreedomShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController breathingController;
  final NotificationRepository _notificationRepository =
      const NotificationRepository();
  final Set<String> _seenNotificationIds = {};
  StreamSubscription<List<NotificationItem>>? _notificationSubscription;
  bool _seededNotifications = false;

  @override
  void initState() {
    super.initState();
    breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: .94,
      upperBound: 1.04,
    )..repeat(reverse: true);
    _notificationSubscription = _notificationRepository
        .listenToNotifications()
        .listen(_handleNotificationUpdates);
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    breathingController.dispose();
    super.dispose();
  }

  void _handleNotificationUpdates(List<NotificationItem> notifications) {
    if (!_seededNotifications) {
      _seenNotificationIds.addAll(
        notifications.map((notification) => notification.id),
      );
      _seededNotifications = true;
      return;
    }

    final fresh = notifications
        .where(
          (notification) => !_seenNotificationIds.contains(notification.id),
        )
        .toList();
    _seenNotificationIds.addAll(
      notifications.map((notification) => notification.id),
    );

    final important = fresh.where(
      (notification) =>
          notification.priority == 'high' || notification.priority == 'urgent',
    );
    if (!mounted || important.isEmpty) return;

    final notification = important.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification.body ?? notification.title),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final screens = [
      HomeDashboard(onOpenTab: appState.selectTab),
      const GroupsScreen(),
      const CommunityWallScreen(),
      const PrayerWallScreen(asRootTab: true),
      const ProfileScreen(),
    ];

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: appState.selectedTab, children: screens),
          floatingActionButton: ScaleTransition(
            scale: breathingController,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.support,
              foregroundColor: Colors.white,
              onPressed: () => showDailyCheckInSheet(context),
              icon: const Icon(Icons.front_hand_rounded),
              label: const Text('Support'),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: appState.selectedTab,
            onDestinationSelected: appState.selectTab,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Groups',
              ),
              const NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                selectedIcon: Icon(Icons.forum_rounded),
                label: 'Community',
              ),
              const NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism_rounded),
                label: 'Prayer',
              ),
              const NavigationDestination(
                icon: NotificationBadge(
                  child: Icon(Icons.person_outline_rounded),
                ),
                selectedIcon: NotificationBadge(
                  child: Icon(Icons.person_rounded),
                ),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
