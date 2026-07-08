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
import '../../data/models/revenuecat_models.dart';
import '../../data/repositories/subscription_repository.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  bool yearly = false;
  bool _loading = true;
  bool _buying = false;
  bool _restoring = false;
  String? _selectedPackageId;
  String? _statusMessage;
  RevenueCatOfferingState _offeringState = RevenueCatOfferingState.empty;

  final SubscriptionRepository _subscriptionRepository =
      const SubscriptionRepository();

  @override
  void initState() {
    super.initState();
    MonetizationService.instance.trackPaywallView(
      'premium_paywall',
      'premium_upgrade',
    );
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _loading = true;
      _statusMessage = null;
    });
    final offerings = await _subscriptionRepository
        .getAvailablePackages()
        .then(
          (packages) => RevenueCatOfferingState(
            loading: false,
            offeringId: 'default',
            packages: packages,
          ),
        )
        .catchError((_) {
          return const RevenueCatOfferingState(
            loading: false,
            offeringId: 'default',
            packages: [],
            error: 'We could not load subscription offerings right now.',
          );
        });

    if (!mounted) return;

    final monthly = _findMonthly(offerings.packages);
    setState(() {
      _offeringState = offerings;
      _loading = false;
      _selectedPackageId =
          monthly?.identifier ?? offerings.packages.firstOrNull?.identifier;
      yearly = _isYearly(_selectedPackageId);
    });
  }

  AppSubscriptionPackage? _findMonthly(List<AppSubscriptionPackage> packages) {
    for (final package in packages) {
      final id = package.identifier.toLowerCase();
      final type = package.packageType.toLowerCase();
      final product = package.productId.toLowerCase();
      if (id.contains('month') ||
          type.contains('monthly') ||
          product.contains('month')) {
        return package;
      }
    }
    return null;
  }

  AppSubscriptionPackage? _findYearly(List<AppSubscriptionPackage> packages) {
    for (final package in packages) {
      final id = package.identifier.toLowerCase();
      final type = package.packageType.toLowerCase();
      final product = package.productId.toLowerCase();
      if (id.contains('year') ||
          type.contains('annual') ||
          type.contains('yearly') ||
          product.contains('year')) {
        return package;
      }
    }
    return null;
  }

  bool _isYearly(String? packageId) {
    if (packageId == null) return false;
    final lower = packageId.toLowerCase();
    return lower.contains('annual') || lower.contains('year');
  }

  Future<void> _purchaseSelected() async {
    if (_buying || _selectedPackageId == null) return;
    final selected = _offeringState.packages.firstWhere(
      (package) => package.identifier == _selectedPackageId,
      orElse: () => _offeringState.packages.first,
    );

    setState(() {
      _buying = true;
      _statusMessage = null;
    });

    await MonetizationService.instance.trackPurchaseStarted(
      'premium_paywall',
      selected.productId,
    );
    final result = await _subscriptionRepository.purchasePackage(selected);
    await MonetizationService.instance.trackPurchaseResult(
      screen: 'premium_paywall',
      planCode: selected.productId,
      result: result,
    );

    if (!mounted) return;

    setState(() {
      _buying = false;
      _statusMessage = result.cancelled
          ? 'Purchase cancelled. You can try again any time.'
          : (result.success
                ? 'Premium activated.'
                : (result.message ?? 'Purchase failed. Please try again.'));
    });

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restorePurchases() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _statusMessage = null;
    });

    await MonetizationService.instance.trackRestoreStarted('premium_paywall');
    final result = await _subscriptionRepository.restorePurchases();
    await MonetizationService.instance.trackRestoreResult(
      'premium_paywall',
      result,
    );

    if (!mounted) return;

    setState(() {
      _restoring = false;
      _statusMessage =
          result.message ??
          (result.success
              ? 'Restore complete.'
              : 'No active purchases were found.');
    });

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  String _yearlySavingsLabel(
    AppSubscriptionPackage monthly,
    AppSubscriptionPackage yearly,
  ) {
    final annualizedMonthly = monthly.price * 12;
    if (annualizedMonthly <= yearly.price || annualizedMonthly == 0) {
      return 'Best value';
    }
    final savingsPercent =
        ((annualizedMonthly - yearly.price) / annualizedMonthly * 100).round();
    return 'Save $savingsPercent%';
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _findMonthly(_offeringState.packages);
    final yearlyPackage = _findYearly(_offeringState.packages);
    final visiblePackages = _offeringState.packages;

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
          onSelectionChanged: _offeringState.packages.isEmpty
              ? null
              : (value) {
                  setState(() {
                    yearly = value.first;
                    final preferred = yearly
                        ? (yearlyPackage ?? monthly)
                        : (monthly ?? yearlyPackage);
                    _selectedPackageId = preferred?.identifier;
                  });
                },
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_offeringState.error != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _offeringState.error!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: _loadOfferings,
                ),
              ],
            ),
          )
        else if (visiblePackages.isEmpty)
          const EmptyStateCard(
            icon: Icons.price_check_rounded,
            title: 'No plans available yet',
            body:
                'Subscription plans are not available right now. Please check back shortly.',
            action: 'Retry',
          )
        else
          Column(
            children: [
              for (final package in visiblePackages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PremiumPlanCard(
                    package: package,
                    selected: _selectedPackageId == package.identifier,
                    highlighted: _isYearly(package.identifier),
                    yearlySavings:
                        (_isYearly(package.identifier) &&
                            monthly != null &&
                            yearlyPackage != null)
                        ? _yearlySavingsLabel(monthly, yearlyPackage)
                        : null,
                    onSelect: () => setState(() {
                      _selectedPackageId = package.identifier;
                      yearly = _isYearly(package.identifier);
                    }),
                  ),
                ),
            ],
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
          label: _buying ? 'Processing...' : 'Continue',
          icon: Icons.lock_rounded,
          color: AppColors.gold,
          foregroundColor: AppColors.navy,
          onPressed: () {
            if (_buying || _offeringState.packages.isEmpty) {
              return;
            }
            _purchaseSelected();
          },
        ),
        TextButton(
          onPressed: _restoring ? null : () => _restorePurchases(),
          child: Text(_restoring ? 'Restoring...' : 'Restore purchases'),
        ),
        if (_statusMessage != null)
          Text(
            _statusMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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
    required this.package,
    required this.selected,
    required this.highlighted,
    required this.onSelect,
    this.yearlySavings,
  });

  final AppSubscriptionPackage package;
  final bool selected;
  final bool highlighted;
  final VoidCallback onSelect;
  final String? yearlySavings;

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
                    package.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (highlighted)
                  StatusBadge(
                    label: yearlySavings ?? 'Most Popular',
                    color: AppColors.gold,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              package.priceString,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: AppColors.green),
            ),
            const SizedBox(height: 8),
            Text(
              package.description,
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
