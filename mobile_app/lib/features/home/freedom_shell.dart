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
  const FreedomShell({super.key, this.initialTab = 0});

  final int initialTab;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = AppStateScope.of(context);
      final index = widget.initialTab.clamp(0, 4);
      if (appState.selectedTab != index) {
        appState.selectTab(index);
      }
    });
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
        final quickLinks = [
          (AppRoutes.search, 'Search', Icons.search_rounded),
          (
            AppRoutes.notifications,
            'Notifications',
            Icons.notifications_rounded,
          ),
          (AppRoutes.settings, 'Settings', Icons.settings_rounded),
          (AppRoutes.chat, 'Chats', Icons.chat_bubble_rounded),
          (AppRoutes.journal, 'Journal', Icons.edit_note_rounded),
          (AppRoutes.quietTime, 'Quiet Time', Icons.self_improvement_rounded),
          (
            AppRoutes.subscriptions,
            'Subscriptions',
            Icons.workspace_premium_rounded,
          ),
        ];

        return Scaffold(
          body: IndexedStack(index: appState.selectedTab, children: screens),
          endDrawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                children: [
                  const ListTile(
                    title: Text('Quick access'),
                    subtitle: Text('Navigate every core screen directly.'),
                  ),
                  for (final link in quickLinks)
                    ListTile(
                      leading: Icon(link.$3),
                      title: Text(link.$2),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, link.$1);
                      },
                    ),
                  const Divider(height: 22),
                  ListTile(
                    leading: const Icon(Icons.home_rounded),
                    title: const Text('Home tab'),
                    onTap: () {
                      Navigator.pop(context);
                      appState.selectTab(0);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_rounded),
                    title: const Text('Groups tab'),
                    onTap: () {
                      Navigator.pop(context);
                      appState.selectTab(1);
                    },
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Builder(
            builder: (fabContext) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'shell_menu_fab',
                  onPressed: () => Scaffold.of(fabContext).openEndDrawer(),
                  child: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.support.withValues(alpha: .22),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ScaleTransition(
                    scale: breathingController,
                    child: FloatingActionButton.extended(
                      heroTag: 'shell_support_fab',
                      backgroundColor: AppColors.support,
                      foregroundColor: Colors.white,
                      onPressed: () => showDailyCheckInSheet(context),
                      icon: const Icon(Icons.front_hand_rounded),
                      label: const Text('Support'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.line),
            ),
            child: NavigationBar(
              selectedIndex: appState.selectedTab,
              onDestinationSelected: appState.selectTab,
              backgroundColor: Colors.transparent,
              elevation: 0,
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
          ),
        );
      },
    );
  }
}
