import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/app_state.dart';
import '../community/community_wall_screen.dart';
import '../checkin/daily_check_in_sheet.dart';
import '../groups/groups_screen.dart';
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

  @override
  void initState() {
    super.initState();
    breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: .94,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    breathingController.dispose();
    super.dispose();
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.forum_outlined),
                selectedIcon: Icon(Icons.forum_rounded),
                label: 'Community',
              ),
              NavigationDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism_rounded),
                label: 'Prayer',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
