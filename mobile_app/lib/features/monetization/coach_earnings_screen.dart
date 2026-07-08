import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/monetization_models.dart';

class CoachEarningsScreen extends StatelessWidget {
  const CoachEarningsScreen({super.key, this.helperId = 'mock-helper'});

  final String helperId;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Coach earnings',
      subtitle: 'Gross bookings, platform fees, net earnings, and payouts.',
      withBack: true,
      children: [
        FutureBuilder<CoachEarningsSummary>(
          future: MonetizationService.instance.coachEarningsSummary(helperId),
          builder: (context, snapshot) {
            final summary =
                snapshot.data ?? MonetizationService.mockCoachEarnings;
            return Column(
              children: [
                _BalanceHero(summary: summary),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Gross',
                        value: summary.grossEarnings,
                        icon: Icons.payments_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Platform fee',
                        value: summary.platformFees,
                        icon: Icons.percent_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Pending',
                        value: summary.pendingBalance,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Paid',
                        value: summary.paidBalance,
                        icon: Icons.verified_rounded,
                      ),
                    ),
                  ],
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
                'Recent bookings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _BookingEarningTile(
                'Recovery support call',
                'GHS 60',
                'Available',
              ),
              const _BookingEarningTile(
                'Weekly accountability',
                'GHS 120',
                'Pending',
              ),
              const _BookingEarningTile('Intro session', 'GHS 0', 'Free'),
            ],
          ),
        ),
        PrimaryButton(
          label: 'Request payout',
          icon: Icons.account_balance_wallet_rounded,
          onPressed: () => showComingSoon(context, 'Payout request'),
        ),
        TextButton(
          onPressed: () => showComingSoon(context, 'Payout history'),
          child: const Text('Payout history'),
        ),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final CoachEarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.darkSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(
            label: 'Available',
            color: AppColors.gold,
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 14),
          Text(
            'GHS ${summary.availableBalance}',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Net earnings are available after session completion and review window.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .72),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final num value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('GHS $value', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _BookingEarningTile extends StatelessWidget {
  const _BookingEarningTile(this.title, this.amount, this.status);

  final String title;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
          Text(amount, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          SmallTag(label: status),
        ],
      ),
    );
  }
}
