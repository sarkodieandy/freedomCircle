import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/app_profile_header.dart';
import '../../core/widgets/app_metric_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../data/models/helper_profile.dart';
import '../../data/providers/repository_provider.dart';
import '../../data/repositories/freedom_repository.dart';
import '../groups/groups_screen.dart';
import '../helpers/helper_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../recovery/recovery_tracker_screen.dart';
import '../safety/safety_screen.dart';
import '../settings/settings_screen.dart';
import '../subscriptions/subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FreedomRepository _repository = RepositoryProvider.freedomRepository();
  late final Future<List<HelperProfile>> _helpersFuture;

  @override
  void initState() {
    super.initState();
    _helpersFuture = _repository.helpers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<HelperProfile>>(
          future: _helpersFuture,
          builder: (context, snapshot) {
            final helper = snapshot.data?.isNotEmpty == true
                ? snapshot.data!.first
                : null;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
              children: [
                AppProfileHeader(
                  name: 'Andy Mensah',
                  username: '@andyfaith • Anonymous mode enabled',
                  avatarUrl: AppImages.avatarTwo,
                  isPremium: false,
                  onSettings: () => pushScreen(context, const SettingsScreen()),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      const ProgressRing(
                        progress: .57,
                        size: 82,
                        color: AppColors.gold,
                        label: '12d',
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Spiritual progress: recovery, prayer, Bible, and fasting rhythm are moving steadily.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My goals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      const _GoalRow('Recovery support', '12 / 21 days', .57),
                      const _GoalRow(
                        'Prayer discipline',
                        '5 / 7 this week',
                        .71,
                      ),
                      const _GoalRow('Bible study', 'John 8 today', .64),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppMetricCard(
                  title: 'Milestones',
                  value: '7-day consistency badge',
                  icon: Icons.workspace_premium_rounded,
                ),
                const SizedBox(height: 12),
                const AppMetricCard(
                  title: 'Groups',
                  value: '3 joined accountability circles',
                  icon: Icons.groups_rounded,
                ),
                const SizedBox(height: 16),
                if (helper != null)
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'My helper: ${helper.name}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => pushScreen(
                            context,
                            HelperProfileScreen(helper: helper),
                          ),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  )
                else
                  const AppCard(child: Text('No helper connected yet.')),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (snapshot.hasError)
                  AppCard(
                    child: Text(
                      'Could not load helper profile from backend yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy settings',
                  subtitle: 'Anonymous mode, sharing, visibility',
                  onTap: () => pushScreen(context, const SettingsScreen()),
                ),
                SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Check-ins, prayer, group sessions',
                  onTap: () => pushScreen(context, const NotificationsScreen()),
                ),
                SettingsTile(
                  icon: Icons.track_changes_rounded,
                  title: 'My goals',
                  subtitle: 'Recovery, prayer, fasting, Bible study',
                  onTap: () =>
                      pushScreen(context, const RecoveryTrackerScreen()),
                ),
                SettingsTile(
                  icon: Icons.groups_rounded,
                  title: 'My groups',
                  subtitle: '3 joined circles',
                  onTap: () => pushScreen(context, const GroupsScreen()),
                ),
                SettingsTile(
                  icon: Icons.verified_user_rounded,
                  title: 'My helper',
                  subtitle: helper?.name ?? 'No helper assigned',
                  onTap: () {
                    if (helper == null) {
                      showComingSoon(context, 'No helper assigned yet');
                      return;
                    }
                    pushScreen(context, HelperProfileScreen(helper: helper));
                  },
                ),
                SettingsTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Subscription',
                  subtitle: 'Free plan',
                  onTap: () => pushScreen(context, const SubscriptionScreen()),
                ),
                SettingsTile(
                  icon: Icons.security_rounded,
                  title: 'Security',
                  subtitle: 'Password, sessions, account protection',
                  onTap: () => pushScreen(context, const SettingsScreen()),
                ),
                SettingsTile(
                  icon: Icons.help_rounded,
                  title: 'Help and support',
                  subtitle: 'Safety, support, and contact options',
                  onTap: () => pushScreen(context, const SafetyScreen()),
                ),
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete account',
                  subtitle: 'Remove personal data and private logs',
                  destructive: true,
                  onTap: () => showComingSoon(context, 'Delete account'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(this.title, this.value, this.progress);

  final String title;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            color: AppColors.green,
            backgroundColor: AppColors.softGreen,
          ),
        ],
      ),
    );
  }
}
