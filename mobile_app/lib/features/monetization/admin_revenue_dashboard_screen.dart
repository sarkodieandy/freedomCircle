import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/monetization_models.dart';

class AdminRevenueDashboardScreen extends StatelessWidget {
  const AdminRevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Revenue dashboard',
      subtitle: 'Admin preview for monetization health and conversion.',
      withBack: true,
      children: [
        FutureBuilder<AdminRevenueSummary>(
          future: MonetizationService.instance.adminRevenueSummary(),
          builder: (context, snapshot) {
            final summary =
                snapshot.data ?? MonetizationService.mockAdminRevenue;
            return Column(
              children: [
                AppCard(
                  color: AppColors.darkSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusBadge(
                        label: 'Admin only',
                        color: AppColors.gold,
                        icon: Icons.admin_panel_settings_rounded,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'GHS ${summary.mrr}',
                        style: Theme.of(
                          context,
                        ).textTheme.displaySmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monthly recurring revenue. ARR: GHS ${summary.arr}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: .74),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _RevenueMetric(
                      'Today',
                      summary.dailyRevenue,
                      Icons.today_rounded,
                    ),
                    _RevenueMetric(
                      'This month',
                      summary.monthRevenue,
                      Icons.calendar_month_rounded,
                    ),
                    _RevenueMetric(
                      'Successful',
                      summary.successfulEvents,
                      Icons.check_circle_rounded,
                    ),
                    _RevenueMetric(
                      'Failed',
                      summary.failedEvents,
                      Icons.error_outline_rounded,
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
                'Revenue sources',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _SourceRow('User subscriptions', 'App Store / Google Play'),
              const _SourceRow('Church subscriptions', 'Laravel / Paystack'),
              const _SourceRow(
                'Coach commission',
                'Paystack verified bookings',
              ),
              const _SourceRow('Program sales', 'Paid program purchases'),
              const _SourceRow(
                'Refunds / failed payments',
                'Admin review queue',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueMetric extends StatelessWidget {
  const _RevenueMetric(this.label, this.value, this.icon);

  final String label;
  final Object value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.green),
          const Spacer(),
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow(this.label, this.source);

  final String label;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.arrow_right_rounded, color: AppColors.gold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(source, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
