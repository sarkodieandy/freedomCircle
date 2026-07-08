import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import 'premium_paywall_screen.dart';

class FeatureLockedModal extends StatelessWidget {
  const FeatureLockedModal({
    super.key,
    required this.featureKey,
    required this.featureName,
    required this.reason,
    required this.benefits,
    this.screen = 'feature_locked_modal',
  });

  final String featureKey;
  final String featureName;
  final String reason;
  final List<String> benefits;
  final String screen;

  static Future<void> show(
    BuildContext context, {
    required String featureKey,
    required String featureName,
    required String reason,
    required List<String> benefits,
    String screen = 'feature_locked_modal',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeatureLockedModal(
        featureKey: featureKey,
        featureName: featureName,
        reason: reason,
        benefits: benefits,
        screen: screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    MonetizationService.instance.trackPaywallView(screen, featureKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .96, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: .16),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge(
                label: 'Premium',
                color: AppColors.gold,
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 16),
              Text(
                featureName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(reason, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              for (final benefit in benefits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.green,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          benefit,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Unlock Premium',
                icon: Icons.lock_open_rounded,
                color: AppColors.gold,
                foregroundColor: AppColors.navy,
                onPressed: () {
                  MonetizationService.instance.trackUpgradeClick(
                    screen,
                    'premium_monthly',
                  );
                  Navigator.pop(context);
                  pushScreen(context, const PremiumPaywallScreen());
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
