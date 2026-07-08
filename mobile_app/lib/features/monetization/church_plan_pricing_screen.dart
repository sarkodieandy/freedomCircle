import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/monetization_models.dart';

class ChurchPlanPricingScreen extends StatelessWidget {
  const ChurchPlanPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Church plans',
      subtitle: 'Private groups, member care, reporting, and admin roles.',
      withBack: true,
      children: [
        FutureBuilder<List<MonetizationPlan>>(
          future: MonetizationService.instance.plans(type: 'church'),
          builder: (context, snapshot) {
            final plans = (snapshot.data ?? MonetizationService.mockPlans)
                .where((plan) => plan.planType == 'church')
                .toList();
            return Column(
              children: [
                for (final plan in plans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ChurchPlanCard(plan: plan),
                  ),
              ],
            );
          },
        ),
        AppCard(
          color: AppColors.softGreen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Church billing should route through Laravel and Paystack so receipts, invoices, webhooks, and entitlements are verified server-side.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChurchPlanCard extends StatelessWidget {
  const _ChurchPlanCard({required this.plan});

  final MonetizationPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPro = plan.code == 'church_pro';

    return AppCard(
      color: isPro ? AppColors.darkSurface : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isPro ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
              if (isPro)
                const StatusBadge(
                  label: 'Pro',
                  color: AppColors.gold,
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.priceLabel}/month',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isPro ? AppColors.gold : AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isPro ? Colors.white.withValues(alpha: .76) : null,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmallTag(
                label: plan.code == 'church_starter'
                    ? '100 members'
                    : 'More members',
              ),
              const SmallTag(label: 'Private groups'),
              const SmallTag(label: 'Reports'),
              if (plan.code != 'church_starter')
                const SmallTag(label: 'Admin roles'),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Start Church Plan',
            icon: Icons.church_rounded,
            color: isPro ? AppColors.gold : AppColors.green,
            foregroundColor: isPro ? AppColors.navy : Colors.white,
            onPressed: () =>
                showComingSoon(context, 'Laravel Paystack checkout'),
          ),
        ],
      ),
    );
  }
}
