import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
import '../utils/app_logger.dart';
import '../../data/models/revenuecat_models.dart';
import '../../data/supabase/supabase_service.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  final StreamController<CustomerPremiumStatus> _premiumStatusController =
      StreamController<CustomerPremiumStatus>.broadcast();

  bool _isInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;
  final Map<String, Package> _packageByIdentifier = {};

  bool get isInitialized => _isInitialized;

  bool get isConfigured {
    try {
      RevenueCatConfig.apiKeyForPlatform(
        isIOS: Platform.isIOS,
        isAndroid: Platform.isAndroid,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<CustomerPremiumStatus> get premiumStatusStream =>
      _premiumStatusController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isConfigured) {
      AppLogger.warning(
        'RevenueCat initialization skipped (missing API key)',
        tag: 'REVENUECAT',
        data: {'help': RevenueCatConfig.dartDefineHelp},
      );
      return;
    }

    AppLogger.info('RevenueCat configure started', tag: 'REVENUECAT');

    final apiKey = RevenueCatConfig.apiKeyForPlatform(
      isIOS: Platform.isIOS,
      isAndroid: Platform.isAndroid,
    );

    await Purchases.setLogLevel(LogLevel.warn);

    final userId = SupabaseService.currentUserId;
    final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(configuration);
    AppLogger.info(
      'RevenueCat configure success',
      tag: 'REVENUECAT',
      data: {'user_id_present': userId != null},
    );

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      AppLogger.info('CustomerInfo fetched', tag: 'REVENUECAT');
      final mapped = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(mapped);
    });

    _authSubscription = SupabaseService.authStateChanges.listen((state) async {
      final sessionUserId = state.session?.user.id;
      if (sessionUserId != null) {
        AppLogger.info(
          'RevenueCat login with Supabase user id started',
          tag: 'REVENUECAT',
          data: {'user_id': sessionUserId},
        );
        await logIn(sessionUserId);
        await getCustomerStatus();
      } else {
        await logOut();
      }
    });

    if (userId != null) {
      await logIn(userId);
      final status = await getCustomerStatus();
      _premiumStatusController.add(status);
    }

    _isInitialized = true;
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _premiumStatusController.close();
  }

  Future<void> logIn(String userId) async {
    if (!_isInitialized) {
      AppLogger.warning(
        'RevenueCat login skipped (SDK not initialized)',
        tag: 'REVENUECAT',
      );
      return;
    }

    AppLogger.info(
      'RevenueCat login with Supabase user id started',
      tag: 'REVENUECAT',
      data: {'user_id': userId},
    );
    await Purchases.logIn(userId);
    AppLogger.info(
      'RevenueCat login with Supabase user id success',
      tag: 'REVENUECAT',
      data: {'user_id': userId},
    );
  }

  Future<void> logOut() async {
    if (!_isInitialized) {
      AppLogger.warning(
        'RevenueCat logout skipped (SDK not initialized)',
        tag: 'REVENUECAT',
      );
      return;
    }

    AppLogger.info('RevenueCat logout started', tag: 'REVENUECAT');
    await Purchases.logOut();
    final userId = SupabaseService.currentUserId;
    if (userId != null && !_premiumStatusController.isClosed) {
      _premiumStatusController.add(CustomerPremiumStatus.empty(userId));
    }
    AppLogger.info('RevenueCat logout success', tag: 'REVENUECAT');
  }

  Future<RevenueCatOfferingState> getOfferings() async {
    if (!_isInitialized) {
      return const RevenueCatOfferingState(
        loading: false,
        offeringId: RevenueCatConfig.defaultOfferingId,
        packages: [],
        error: 'Subscriptions are currently unavailable on this build.',
      );
    }

    try {
      AppLogger.info('Offering fetch started', tag: 'REVENUECAT');
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(RevenueCatConfig.defaultOfferingId) ??
          offerings.current;

      if (offering == null) {
        AppLogger.warning(
          'Offering fetch failed',
          tag: 'REVENUECAT',
          data: {'reason': 'no_active_offering'},
        );
        return const RevenueCatOfferingState(
          loading: false,
          offeringId: RevenueCatConfig.defaultOfferingId,
          packages: [],
          error: 'No active RevenueCat offering found.',
        );
      }

      _packageByIdentifier.clear();
      final packages = offering.availablePackages.map((item) {
        _packageByIdentifier[item.identifier] = item;
        return AppSubscriptionPackage(
          identifier: item.identifier,
          productId: item.storeProduct.identifier,
          title: item.storeProduct.title,
          description: item.storeProduct.description,
          price: item.storeProduct.price,
          currencyCode: item.storeProduct.currencyCode,
          priceString: item.storeProduct.priceString,
          packageType: item.packageType.name,
        );
      }).toList();

      return RevenueCatOfferingState(
        loading: false,
        offeringId: offering.identifier,
        packages: packages,
      );
    } catch (error) {
      AppLogger.error(
        'Offering fetch failure',
        tag: 'REVENUECAT',
        error: error,
      );
      return RevenueCatOfferingState(
        loading: false,
        offeringId: RevenueCatConfig.defaultOfferingId,
        packages: const [],
        error: 'Could not load subscriptions. Please try again.',
      );
    }
  }

  Future<CustomerPremiumStatus> getCustomerStatus() async {
    if (!_isInitialized) {
      final userId = SupabaseService.currentUserId ?? 'guest';
      final status = CustomerPremiumStatus.empty(userId);
      if (!_premiumStatusController.isClosed) {
        _premiumStatusController.add(status);
      }
      return status;
    }

    AppLogger.info('CustomerInfo fetched', tag: 'REVENUECAT');
    final customerInfo = await Purchases.getCustomerInfo();
    final mapped = _mapCustomerInfo(
      userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
      customerInfo: customerInfo,
    );
    if (!_premiumStatusController.isClosed) {
      _premiumStatusController.add(mapped);
    }
    AppLogger.info(
      mapped.isPremium
          ? 'Premium entitlement active'
          : 'Premium entitlement inactive',
      tag: 'REVENUECAT',
      data: {'user_id': mapped.userId},
    );
    return mapped;
  }

  Future<bool> isPremium() async {
    if (!_isInitialized) return false;

    final status = await getCustomerStatus();
    return status.isPremium;
  }

  Future<PurchaseResult> purchasePackage(AppSubscriptionPackage package) async {
    if (!_isInitialized) {
      return const PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: 'Subscriptions are unavailable in this app build.',
      );
    }

    AppLogger.info(
      'Package selected',
      tag: 'REVENUECAT',
      data: {'package_id': package.identifier, 'product_id': package.productId},
    );
    final rcPackage = _packageByIdentifier[package.identifier];
    if (rcPackage == null) {
      return const PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: 'Selected package is unavailable. Reload and try again.',
      );
    }

    try {
      AppLogger.info(
        'Purchase started',
        tag: 'PAYMENT',
        data: {'plan': package.productId},
      );
      final customerInfo = await Purchases.purchasePackage(rcPackage);
      final status = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(status);
      AppLogger.info(
        'Purchase success',
        tag: 'PAYMENT',
        data: {'plan': package.productId},
      );
      return PurchaseResult(
        success: status.isPremium,
        cancelled: false,
        status: status.isPremium ? 'success' : 'completed_without_premium',
        customerStatus: status,
      );
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.info(
          'Purchase cancelled',
          tag: 'PAYMENT',
          data: {'plan': package.productId},
        );
        return const PurchaseResult(
          success: false,
          cancelled: true,
          status: 'cancelled',
          message: 'Purchase cancelled.',
        );
      }
      AppLogger.error(
        'Purchase failure',
        tag: 'PAYMENT',
        error: error,
        data: {'plan': package.productId},
      );
      return PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: error.message ?? 'Purchase failed. Please try again.',
      );
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    if (!_isInitialized) {
      return const PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: 'Subscriptions are unavailable in this app build.',
      );
    }

    try {
      AppLogger.info('Restore started', tag: 'PAYMENT');
      final customerInfo = await Purchases.restorePurchases();
      final status = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(status);
      if (status.isPremium) {
        AppLogger.info('Restore success', tag: 'PAYMENT');
        return PurchaseResult(
          success: true,
          cancelled: false,
          status: 'restored',
          customerStatus: status,
          message: 'Purchases restored successfully.',
        );
      }
      AppLogger.warning(
        'Restore failed',
        tag: 'PAYMENT',
        data: {'reason': 'no_active_purchase'},
      );
      return PurchaseResult(
        success: false,
        cancelled: false,
        status: 'no_active_purchase',
        customerStatus: status,
        message: 'No active purchases were found to restore.',
      );
    } on PlatformException catch (error) {
      AppLogger.error('Restore failed', tag: 'PAYMENT', error: error);
      return PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: error.message ?? 'Restore failed. Please try again.',
      );
    }
  }

  CustomerPremiumStatus _mapCustomerInfo({
    required String userId,
    required CustomerInfo customerInfo,
  }) {
    final activeEntitlements = customerInfo.entitlements.active.keys.toList(
      growable: false,
    );
    final activeProductIds = customerInfo.activeSubscriptions.toList(
      growable: false,
    );
    final expirationDateRaw = customerInfo
        .entitlements
        .all[RevenueCatConfig.entitlementPremium]
        ?.expirationDate;

    return CustomerPremiumStatus(
      userId: userId,
      isPremium: activeEntitlements.contains(
        RevenueCatConfig.entitlementPremium,
      ),
      activeEntitlements: activeEntitlements,
      activeProductIds: activeProductIds,
      latestExpirationDate: expirationDateRaw == null
          ? null
          : DateTime.tryParse(expirationDateRaw),
      originalAppUserId: customerInfo.originalAppUserId,
      managementUrl: customerInfo.managementURL,
      updatedAt: DateTime.now(),
    );
  }
}
