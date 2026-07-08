import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/monetization_models.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  bool yearly = false;
  String selectedPlan = 'premium_monthly';
  late Future<List<MonetizationPlan>> plansFuture;

  @override
  void initState() {
    super.initState();
    plansFuture = MonetizationService.instance.plans(type: 'user');
    MonetizationService.instance.trackPaywallView(
      'premium_paywall',
      'premium_upgrade',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Unlock Premium',
      subtitle: 'Deeper insight, unlimited private growth, and guided support.',
      withBack: true,
      children: [
        AppCard(
          color: AppColors.darkSurface,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 168,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: RemoteImage(
                        imageUrl: AppImages.journaling,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        overlayColor: Color(0x55172033),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: StatusBadge(
                        label: 'Premium',
                        color: AppColors.gold,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock deeper insights for your growth journey.',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unlimited recovery goals, advanced insights, premium accountability circles, private journals, helper matching, and guided plans.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .74),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Monthly')),
            ButtonSegment(value: true, label: Text('Yearly')),
          ],
          selected: {yearly},
          onSelectionChanged: (value) {
            setState(() {
              yearly = value.first;
              selectedPlan = yearly ? 'premium_yearly' : 'premium_monthly';
            });
          },
        ),
        FutureBuilder<List<MonetizationPlan>>(
          future: plansFuture,
          builder: (context, snapshot) {
            final plans = snapshot.data ?? MonetizationService.mockPlans;
            final premiumPlans = plans
                .where((plan) => plan.code.startsWith('premium_'))
                .toList();

            return Column(
              children: [
                for (final plan in premiumPlans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PremiumPlanCard(
                      plan: plan,
                      selected: selectedPlan == plan.code,
                      highlighted: plan.code == 'premium_yearly',
                      onSelect: () => setState(() {
                        selectedPlan = plan.code;
                        yearly = plan.code == 'premium_yearly';
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Included with Premium',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _FeatureLine(
                Icons.insights_rounded,
                'Advanced recovery insights',
              ),
              const _FeatureLine(
                Icons.groups_rounded,
                'Premium accountability groups',
              ),
              const _FeatureLine(
                Icons.edit_note_rounded,
                'Unlimited private journals',
              ),
              const _FeatureLine(
                Icons.volunteer_activism_rounded,
                'Guided recovery and devotion plans',
              ),
            ],
          ),
        ),
        PrimaryButton(
          label: 'Continue',
          icon: Icons.lock_rounded,
          color: AppColors.gold,
          foregroundColor: AppColors.navy,
          onPressed: () {
            MonetizationService.instance.trackUpgradeClick(
              'premium_paywall',
              selectedPlan,
            );
            showComingSoon(context, 'In-app purchase checkout');
          },
        ),
        TextButton(
          onPressed: () => showComingSoon(context, 'Restore purchases'),
          child: const Text('Restore purchases'),
        ),
        Text(
          'Secure purchase through App Store or Google Play for digital premium access. Terms and privacy apply.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({
    required this.plan,
    required this.selected,
    required this.highlighted,
    required this.onSelect,
  });

  final MonetizationPlan plan;
  final bool selected;
  final bool highlighted;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.015 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AppCard(
        onTap: onSelect,
        color: highlighted ? AppColors.softGreen : AppColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (highlighted)
                  const StatusBadge(
                    label: 'Best value',
                    color: AppColors.gold,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.priceLabel}/${plan.billingInterval == 'yearly' ? 'year' : 'month'}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.green),
            ),
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.circle_outlined,
                  color: selected ? AppColors.green : AppColors.mutedText,
                ),
                const SizedBox(width: 8),
                Text(
                  selected ? 'Selected' : 'Tap to select',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
