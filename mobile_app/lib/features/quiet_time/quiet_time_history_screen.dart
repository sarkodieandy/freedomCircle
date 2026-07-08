import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../monetization/feature_locked_modal.dart';
import 'quiet_time_repository.dart';

class QuietTimeHistoryScreen extends StatefulWidget {
  const QuietTimeHistoryScreen({super.key});

  @override
  State<QuietTimeHistoryScreen> createState() => _QuietTimeHistoryScreenState();
}

class _QuietTimeHistoryScreenState extends State<QuietTimeHistoryScreen> {
  final QuietTimeRepository _repository = const QuietTimeRepository();
  late final Future _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _repository.historySummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiet Time history')),
      body: SafeArea(
        child: FutureBuilder(
          future: _historyFuture,
          builder: (context, snapshot) {
            final summary =
                snapshot.data ?? QuietTimeRepository.mockHistorySummary;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Sessions completed',
                        value: '${summary.totalSessions}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Total minutes',
                        value: '${summary.totalMinutes}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _StatCard(
                  label: 'Current Quiet Time streak',
                  value: '${summary.currentStreak} days',
                  icon: Icons.local_fire_department_rounded,
                  accent: AppColors.gold,
                ),
                const SizedBox(height: 14),
                Text(
                  'Recent sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < summary.recentHistory.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .92, end: 1),
                    duration: Duration(milliseconds: 180 + (i * 36)),
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                summary.recentHistory[i].sessionTitle ??
                                    'Quiet session',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${(summary.recentHistory[i].durationCompletedSeconds / 60).round()}m',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Favorite sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                for (final item in summary.favorites)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.support,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.sessionTitle ?? 'Favorite quiet session',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Mood improvement summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in summary.moodSummary.entries)
                        StatusBadge(
                          label:
                              '${entry.key.replaceAll('_', ' ')} • ${entry.value}',
                          color: AppColors.softGreen,
                          icon: Icons.trending_up_rounded,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<bool>(
                  future: _repository.canAccessAdvancedInsights(),
                  builder: (context, premiumSnapshot) {
                    final unlocked = premiumSnapshot.data == true;
                    return AppCard(
                      color: unlocked ? AppColors.softGreen : AppColors.card,
                      onTap: unlocked
                          ? () => showComingSoon(
                              context,
                              'Advanced insights chart',
                            )
                          : () => FeatureLockedModal.show(
                              context,
                              featureKey: 'quiet_time_advanced_insights',
                              featureName: 'Quiet Time advanced insights',
                              reason:
                                  'Track deeper mood patterns, streak quality, and reflection trends.',
                              benefits: const [
                                'Mood trend dashboard',
                                'Streak quality insights',
                                'Session completion patterns',
                              ],
                              screen: 'quiet_time_history',
                            ),
                      child: Row(
                        children: [
                          AnimatedScale(
                            scale: unlocked ? 1 : 1.02,
                            duration: const Duration(milliseconds: 400),
                            child: Icon(
                              unlocked
                                  ? Icons.insights_rounded
                                  : Icons.lock_rounded,
                              color: unlocked
                                  ? AppColors.green
                                  : AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Premium insight lock',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  unlocked
                                      ? 'Advanced insights are enabled.'
                                      : 'Unlock advanced analytics for deeper reflection patterns.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: unlocked ? 'Unlocked' : 'Premium',
                            color: unlocked
                                ? AppColors.success
                                : AppColors.gold,
                            icon: unlocked
                                ? Icons.verified_rounded
                                : Icons.workspace_premium_rounded,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.icon,
    this.accent = AppColors.green,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
