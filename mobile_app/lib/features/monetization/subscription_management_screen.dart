import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import 'church_plan_pricing_screen.dart';
import 'premium_paywall_screen.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Subscription',
      subtitle: 'Manage plan access, renewal, purchases, and billing status.',
      withBack: true,
      children: [
        AppCard(
          color: AppColors.darkSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatusBadge(
                label: 'Current plan',
                color: AppColors.gold,
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 14),
              Text(
                'Free',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Basic recovery tracker, limited groups, prayer wall, and daily devotion.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .76),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan features',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _PlanFeature('Basic recovery tracker'),
              const _PlanFeature('Limited group joins'),
              const _PlanFeature('Prayer and community wall'),
              const _PlanFeature('Basic private journal entries'),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Unlock Premium',
                icon: Icons.lock_open_rounded,
                color: AppColors.gold,
                foregroundColor: AppColors.navy,
                onPressed: () =>
                    pushScreen(context, const PremiumPaywallScreen()),
              ),
            ),
          ],
        ),
        SecondaryButton(
          label: 'Upgrade Organization',
          icon: Icons.church_rounded,
          onPressed: () => pushScreen(context, const ChurchPlanPricingScreen()),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Billing', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                'Premium digital subscriptions should be managed through App Store or Google Play. Church plans, coach bookings, and paid programs are verified through Laravel/Paystack.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => showComingSoon(context, 'Payment history'),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Payment history'),
              ),
              TextButton.icon(
                onPressed: () => showComingSoon(context, 'Restore purchases'),
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore purchases'),
              ),
              TextButton.icon(
                onPressed: () => showComingSoon(context, 'Cancel instructions'),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Cancel instructions'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.green,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
