import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/revenuecat_models.dart';
import '../../data/repositories/subscription_repository.dart';
import 'church_plan_pricing_screen.dart';
import 'premium_paywall_screen.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  final SubscriptionRepository _subscriptionRepository =
      const SubscriptionRepository();
  bool _loading = true;
  bool _restoring = false;
  String? _statusMessage;
  CustomerPremiumStatus? _status;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    try {
      final status = await _subscriptionRepository.getCustomerStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not load subscription status right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _statusMessage = null;
    });

    final result = await _subscriptionRepository.restorePurchases();
    await _refreshStatus();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _statusMessage =
          result.message ??
          (result.success
              ? 'Purchases restored successfully.'
              : 'No active purchases were found.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isPremium = status?.isPremium ?? false;
    final activeProduct = status?.activeProductIds.isNotEmpty == true
        ? status!.activeProductIds.first
        : 'Free plan';
    final renewal = status?.latestExpirationDate;

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
              if (_loading)
                const CircularProgressIndicator()
              else
                Text(
                  isPremium ? 'Premium' : 'Free',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              const SizedBox(height: 6),
              Text(
                isPremium
                    ? 'Premium is active on this account.'
                    : 'Basic recovery tracker, limited groups, prayer wall, and daily devotion.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .76),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Product: $activeProduct',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: .9),
                ),
              ),
              if (renewal != null)
                Text(
                  'Renews/Expires: ${renewal.toLocal()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .9),
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
              if (status?.managementUrl != null)
                TextButton.icon(
                  onPressed: () => showComingSoon(
                    context,
                    'Open subscription management link: ${status!.managementUrl}',
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Manage in store'),
                ),
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
                onPressed: _restoring ? null : _restorePurchases,
                icon: const Icon(Icons.restore_rounded),
                label: Text(_restoring ? 'Restoring...' : 'Restore purchases'),
              ),
              TextButton.icon(
                onPressed: _refreshStatus,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh status'),
              ),
              TextButton.icon(
                onPressed: () => showComingSoon(context, 'Cancel instructions'),
                icon: const Icon(Icons.info_outline_rounded),
                label: const Text('Cancel instructions'),
              ),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _statusMessage!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
