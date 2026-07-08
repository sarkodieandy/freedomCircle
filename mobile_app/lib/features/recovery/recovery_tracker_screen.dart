import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/screen_shell.dart';
import '../checkin/daily_check_in_sheet.dart';
import '../monetization/feature_locked_modal.dart';

class RecoveryTrackerScreen extends StatelessWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Recovery tracker',
      subtitle: 'Support and accountability without shame.',
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current streak',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '12 days',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Goal: 21 days • 57% complete',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const ProgressRing(
                    progress: .57,
                    size: 96,
                    color: AppColors.support,
                    label: '57%',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Stayed strong',
                      icon: Icons.check_rounded,
                      onPressed: () => _showMilestoneDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Private log',
                      icon: Icons.edit_note_rounded,
                      onPressed: () => _showPrivateLogSheet(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _RecoveryCalendarCard(),
        const SizedBox(height: 18),
        const _TriggerInsightCard(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _BadgePill(label: '1 day', unlocked: true),
            _BadgePill(label: '3 days', unlocked: true),
            _BadgePill(label: '7 days', unlocked: true),
            _BadgePill(label: '30 days', unlocked: false),
            _BadgePill(label: '90 days', unlocked: false),
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.support),
              const SizedBox(height: 12),
              Text(
                'Reset with grace. Continue with strength.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You are not your struggle. Reflect, pray, reset, and continue.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Reflection journal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What did I notice today?',
                  hintStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: 'Open check-in',
                icon: Icons.check_circle_rounded,
                onPressed: () => showDailyCheckInSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecoveryCalendarCard extends StatelessWidget {
  const _RecoveryCalendarCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress calendar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: 35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final active = index < 25 && index % 6 != 0;
              final color = active
                  ? Color.lerp(
                      AppColors.softGreen,
                      AppColors.success,
                      (index % 8 + 1) / 9,
                    )!
                  : AppColors.inkSoft;
              return AnimatedContainer(
                duration: Duration(milliseconds: 180 + index * 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TriggerInsightCard extends StatelessWidget {
  const _TriggerInsightCard();

  Future<void> _openInsights(BuildContext context) async {
    final allowed = await MonetizationService.instance.canUseAdvancedInsights();
    if (!context.mounted) return;
    if (!allowed) {
      await FeatureLockedModal.show(
        context,
        featureKey: 'advanced_recovery_insights',
        featureName: 'Unlock deeper insights for your growth journey.',
        reason:
            'Advanced charts, trigger insights, and weekly reports are Premium features.',
        benefits: const [
          'See trigger and mood patterns clearly',
          'Review weekly recovery reports',
          'Track streaks with deeper context',
        ],
        screen: 'recovery_tracker',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = [
      ('Late-night scrolling', .74, AppColors.support),
      ('Stress', .52, AppColors.gold),
      ('Isolation', .38, AppColors.green),
    ];

    return AppCard(
      onTap: () => _openInsights(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Trigger and mood insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Premium',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${(item.$2 * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: item.$2,
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: AppColors.inkSoft,
                    color: item.$3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.gold.withValues(alpha: .18)
            : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: unlocked ? AppColors.gold : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked
                ? Icons.workspace_premium_rounded
                : Icons.lock_outline_rounded,
            color: unlocked ? AppColors.gold : AppColors.mutedText,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

void _showPrivateLogSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 22,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            'Private struggle log',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'You are not your struggle. Reflect, pray, reset, and continue.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Trigger',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Mood',
              prefixIcon: Icon(Icons.sentiment_neutral_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Private note',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save private log',
            icon: Icons.lock_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

void _showMilestoneDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: TweenAnimationBuilder<double>(
        tween: Tween(begin: .72, end: 1),
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutBack,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: AppColors.gold,
          size: 54,
        ),
      ),
      title: const Text('Milestone unlocked'),
      content: const Text(
        'Streak saved. The next badge is closer than it was yesterday.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}
