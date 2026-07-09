import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/images.dart';
import '../../core/config/revenuecat_config.dart';
import '../../core/services/monetization_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/remote_image.dart';
import '../../core/widgets/screen_shell.dart';
import '../../core/widgets/app_section_header.dart';
import '../../data/models/revenuecat_models.dart';
import '../../data/repositories/subscription_repository.dart';

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
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

    final weekly = _findWeekly(offerings.packages);
    final monthly = _findMonthly(offerings.packages);
    final yearlyPackage = _findYearly(offerings.packages);
    final defaultPackage = yearlyPackage ?? monthly ?? weekly;

    setState(() {
      _offeringState = offerings;
      _loading = false;
      _selectedPackageId =
          defaultPackage?.identifier ??
          offerings.packages.firstOrNull?.identifier;
    });
  }

  AppSubscriptionPackage? _findWeekly(List<AppSubscriptionPackage> packages) {
    for (final package in packages) {
      final id = package.identifier.toLowerCase();
      final type = package.packageType.toLowerCase();
      final product = package.productId.toLowerCase();
      if (product == RevenueCatConfig.productPremiumWeekly ||
          id.contains('week') ||
          type.contains('weekly') ||
          product.contains('week')) {
        return package;
      }
    }
    return null;
  }

  AppSubscriptionPackage? _findMonthly(List<AppSubscriptionPackage> packages) {
    for (final package in packages) {
      final id = package.identifier.toLowerCase();
      final type = package.packageType.toLowerCase();
      final product = package.productId.toLowerCase();
      if (product == RevenueCatConfig.productPremiumMonthly ||
          id.contains('month') ||
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
      if (product == RevenueCatConfig.productPremiumYearly ||
          id.contains('year') ||
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
    final package = _offeringState.packages.firstWhere(
      (item) => item.identifier == packageId,
      orElse: () => AppSubscriptionPackage(
        identifier: packageId,
        productId: packageId,
        title: packageId,
        description: '',
        price: 0,
        currencyCode: 'USD',
        priceString: packageId,
        packageType: 'unknown',
      ),
    );
    final product = package.productId.toLowerCase();
    return product == RevenueCatConfig.productPremiumYearly ||
        product.contains('year') ||
        package.packageType.toLowerCase().contains('year') ||
        package.identifier.toLowerCase().contains('year');
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

    await MonetizationService.instance.trackUpgradeClick(
      'premium_paywall',
      selected.productId,
    );

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
          ? 'No problem. You can upgrade whenever you are ready.'
          : (result.success
                ? 'Premium activated. Keep growing with consistency.'
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
    final weekly = _findWeekly(_offeringState.packages);
    final monthly = _findMonthly(_offeringState.packages);
    final yearlyPackage = _findYearly(_offeringState.packages);
    final prioritized = <AppSubscriptionPackage?>[
      weekly,
      monthly,
      yearlyPackage,
    ].whereType<AppSubscriptionPackage>();
    final visiblePackages = [
      ...prioritized,
      ..._offeringState.packages.where(
        (item) =>
            item.identifier != weekly?.identifier &&
            item.identifier != monthly?.identifier &&
            item.identifier != yearlyPackage?.identifier,
      ),
    ];

    return ScreenShell(
      title: 'Unlock Premium',
      subtitle:
          'Build consistent habits with deeper support, richer insights, and full guided access.',
      withBack: true,
      children: [
        AppCard(
          color: AppColors.darkSurface,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 184,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: RemoteImage(
                        imageUrl: AppImages.journaling,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        overlayColor: Color(0x55172033),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: const StatusBadge(
                        label: 'Premium',
                        color: AppColors.gold,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paleGold,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: const Text(
                          'Yearly best value',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grow deeper with steady premium support.',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Unlimited goals, full Quiet Time library, premium groups, helper matching, and guided devotion and recovery plans.',
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
        if (yearlyPackage != null)
          const Padding(
            padding: EdgeInsets.only(top: 2, bottom: 8),
            child: Text(
              'Weekly: 3 USD • Monthly: 10 USD • Yearly: 30 USD',
              textAlign: TextAlign.center,
            ),
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
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    supportingCopy: _planSupportCopy(package),
                    onSelect: () => setState(() {
                      _selectedPackageId = package.identifier;
                    }),
                  ),
                ),
            ],
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Included with Premium',
                subtitle:
                    'Everything you need for consistent spiritual growth.',
              ),
              const SizedBox(height: AppSpacing.md),
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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            TextButton(
              onPressed: () => showComingSoon(context, 'Terms of Service'),
              child: const Text('Terms'),
            ),
            TextButton(
              onPressed: () => showComingSoon(context, 'Privacy Policy'),
              child: const Text('Privacy'),
            ),
          ],
        ),
        if (_statusMessage != null)
          Text(
            _statusMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        Text(
          'Secure purchase through App Store or Google Play for digital premium access. Terms and privacy apply.',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  String _planSupportCopy(AppSubscriptionPackage package) {
    final product = package.productId.toLowerCase();
    if (product == RevenueCatConfig.productPremiumWeekly ||
        product.contains('week')) {
      return 'Try Premium for a week and unlock deeper support.';
    }
    if (product == RevenueCatConfig.productPremiumYearly ||
        product.contains('year')) {
      return 'Best value for your full growth journey.';
    }
    return 'Stay consistent with full monthly access.';
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({
    required this.package,
    required this.selected,
    required this.highlighted,
    required this.onSelect,
    required this.supportingCopy,
    this.yearlySavings,
  });

  final AppSubscriptionPackage package;
  final bool selected;
  final bool highlighted;
  final VoidCallback onSelect;
  final String supportingCopy;
  final String? yearlySavings;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.015 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AppCard(
        onTap: onSelect,
        color: selected
            ? AppColors.softGreen
            : (highlighted ? AppColors.softCream : AppColors.card),
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
                    label: 'Best Value',
                    color: AppColors.gold,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              package.priceString,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: selected ? AppColors.deepGreen : AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(supportingCopy, style: AppTextStyles.body),
            if (highlighted && yearlySavings != null) ...[
              const SizedBox(height: 6),
              Text(
                yearlySavings!,
                style: AppTextStyles.caption.copyWith(color: AppColors.gold),
              ),
            ],
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
                  style: AppTextStyles.body.copyWith(
                    color: selected ? AppColors.green : AppColors.mutedText,
                  ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppIconContainer(
            icon: icon,
            color: AppColors.gold,
            size: 30,
            iconSize: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
