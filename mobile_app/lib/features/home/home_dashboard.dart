import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/animations/fade_slide_in.dart';
import '../../core/services/app_state.dart';
import '../../core/widgets/empty_states_screen.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/remote_image.dart';
import '../../data/models/accountability_group.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../checkin/daily_check_in_sheet.dart';
import '../helpers/coach_directory_screen.dart';
import '../groups/group_detail_screen.dart';
import '../journal/journal_screen.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/widgets/notification_badge.dart';
import '../prayer/prayer_wall_screen.dart';
import '../quiet_time/quiet_time_home_screen.dart';
import '../recovery/recovery_tracker_screen.dart';
import '../search/search_screen.dart';
import '../subscriptions/subscription_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<AccountabilityGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _repository.groups();
  }

  AccountabilityGroup? _groupAt(List<AccountabilityGroup> groups, int index) {
    if (groups.isEmpty || index < 0 || index >= groups.length) return null;
    return groups[index];
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<AccountabilityGroup>>(
          future: _groupsFuture,
          builder: (context, snapshot) {
            final groups = snapshot.data ?? const <AccountabilityGroup>[];
            final firstGroup = _groupAt(groups, 0);
            final secondGroup = _groupAt(groups, 1) ?? firstGroup;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, Andy',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Today: ${appState.selectedFocus}, honest check-in, prayer at ${appState.reminderTime}.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () =>
                          pushScreen(context, const NotificationsScreen()),
                      icon: const NotificationBadge(
                        child: Icon(Icons.notifications_none_rounded),
                      ),
                      tooltip: 'Notifications',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: _TodayFocusCard(
                    onCheckIn: () => showDailyCheckInSheet(context),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Recovery',
                          value: '12 days',
                          progress: .57,
                          accent: AppColors.support,
                          onTap: () => pushScreen(
                            context,
                            const RecoveryTrackerScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.volunteer_activism_rounded,
                          title: 'Prayer',
                          value: '5/7',
                          progress: .71,
                          accent: AppColors.green,
                          onTap: () =>
                              pushScreen(context, const PrayerWallScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Row(
                    children: const [
                      Expanded(
                        child: _MiniTrackerCard(
                          icon: Icons.auto_stories_rounded,
                          title: 'Bible',
                          value: 'John 8',
                          accent: AppColors.gold,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _MiniTrackerCard(
                          icon: Icons.restaurant_rounded,
                          title: 'Fasting',
                          value: 'Fri 6 AM',
                          accent: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: 'Suggested circle',
                  action: 'View all',
                  onAction: () => widget.onOpenTab(1),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (firstGroup != null)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 190),
                    child: _DashboardGroupCard(
                      groupName: firstGroup.name,
                      description: firstGroup.description,
                      imageUrl: firstGroup.imageUrl,
                      online: firstGroup.online,
                      onTap: () => pushScreen(
                        context,
                        GroupDetailScreen(group: firstGroup),
                      ),
                    ),
                  )
                else
                  const EmptyStateCard(
                    icon: Icons.groups_outlined,
                    title: 'No suggested circles yet',
                    body:
                        'Groups from the backend will appear here once available.',
                    action: 'Refresh',
                  ),
                const SizedBox(height: 18),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 240),
                  child: _VerseCard(),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.softGreen,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.video_call_rounded,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Youth recovery circle',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Group session today at 7:30 PM',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: secondGroup == null
                            ? null
                            : () => pushScreen(
                                context,
                                GroupDetailScreen(group: secondGroup),
                              ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _QuickActionGrid(
                  actions: [
                    _QuickAction(
                      'Journal',
                      Icons.edit_note_rounded,
                      () => pushScreen(context, const JournalScreen()),
                    ),
                    _QuickAction(
                      'Helpers',
                      Icons.verified_user_rounded,
                      () => pushScreen(context, const CoachDirectoryScreen()),
                    ),
                    _QuickAction(
                      'Search',
                      Icons.search_rounded,
                      () => pushScreen(context, const SearchScreen()),
                    ),
                    _QuickAction(
                      'Quiet Time',
                      Icons.self_improvement_rounded,
                      () => pushScreen(context, const QuietTimeHomeScreen()),
                    ),
                    _QuickAction(
                      'Premium',
                      Icons.workspace_premium_rounded,
                      () => pushScreen(context, const SubscriptionScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      pushScreen(context, const EmptyStatesScreen()),
                  icon: const Icon(Icons.auto_awesome_motion_rounded),
                  label: const Text('Preview loading and empty states'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  const _TodayFocusCard({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 178,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: RemoteImage(
                    imageUrl: AppImages.praying,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      color: AppColors.navy.withValues(alpha: .18),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  right: 18,
                  child: Text(
                    'Today’s spiritual focus',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppColors.navy.withValues(alpha: .36),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before the day gets loud, choose honesty and one small act of faith.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Daily check-in',
                  icon: Icons.check_circle_rounded,
                  onPressed: onCheckIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final double progress;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const Spacer(),
              ProgressRing(progress: progress, size: 50, color: accent),
            ],
          ),
          const SizedBox(height: 14),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _MiniTrackerCard extends StatelessWidget {
  const _MiniTrackerCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGroupCard extends StatelessWidget {
  const _DashboardGroupCard({
    required this.groupName,
    required this.description,
    required this.imageUrl,
    required this.online,
    required this.onTap,
  });

  final String groupName;
  final String description;
  final String imageUrl;
  final int online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RemoteImage(
                    imageUrl: imageUrl,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: StatusBadge(
                    label: '$online online',
                    color: AppColors.green,
                    icon: Icons.circle,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.gold),
          const SizedBox(height: 14),
          Text(
            '“The truth will set you free.”',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'John 8:32',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return AppCard(
          onTap: action.onTap,
          child: Row(
            children: [
              Icon(action.icon, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
