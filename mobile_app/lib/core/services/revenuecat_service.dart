import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/revenuecat_config.dart';
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

  Stream<CustomerPremiumStatus> get premiumStatusStream =>
      _premiumStatusController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = RevenueCatConfig.apiKeyForPlatform(
      isIOS: Platform.isIOS,
      isAndroid: Platform.isAndroid,
    );

    await Purchases.setLogLevel(LogLevel.warn);

    final userId = SupabaseService.currentUserId;
    final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(configuration);

    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      final mapped = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(mapped);
    });

    _authSubscription = SupabaseService.authStateChanges.listen((state) async {
      final sessionUserId = state.session?.user.id;
      if (sessionUserId != null) {
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
    await Purchases.logIn(userId);
  }

  Future<void> logOut() async {
    await Purchases.logOut();
    final userId = SupabaseService.currentUserId;
    if (userId != null && !_premiumStatusController.isClosed) {
      _premiumStatusController.add(CustomerPremiumStatus.empty(userId));
    }
  }

  Future<RevenueCatOfferingState> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(RevenueCatConfig.defaultOfferingId) ??
          offerings.current;

      if (offering == null) {
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
      return RevenueCatOfferingState(
        loading: false,
        offeringId: RevenueCatConfig.defaultOfferingId,
        packages: const [],
        error: 'Could not load subscriptions. Please try again.',
      );
    }
  }

  Future<CustomerPremiumStatus> getCustomerStatus() async {
    final customerInfo = await Purchases.getCustomerInfo();
    final mapped = _mapCustomerInfo(
      userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
      customerInfo: customerInfo,
    );
    if (!_premiumStatusController.isClosed) {
      _premiumStatusController.add(mapped);
    }
    return mapped;
  }

  Future<bool> isPremium() async {
    final status = await getCustomerStatus();
    return status.isPremium;
  }

  Future<PurchaseResult> purchasePackage(AppSubscriptionPackage package) async {
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
      final customerInfo = await Purchases.purchasePackage(rcPackage);
      final status = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(status);
      return PurchaseResult(
        success: status.isPremium,
        cancelled: false,
        status: status.isPremium ? 'success' : 'completed_without_premium',
        customerStatus: status,
      );
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(
          success: false,
          cancelled: true,
          status: 'cancelled',
          message: 'Purchase cancelled.',
        );
      }
      return PurchaseResult(
        success: false,
        cancelled: false,
        status: 'failed',
        message: error.message ?? 'Purchase failed. Please try again.',
      );
    }
  }

  Future<PurchaseResult> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final status = _mapCustomerInfo(
        userId: SupabaseService.currentUserId ?? customerInfo.originalAppUserId,
        customerInfo: customerInfo,
      );
      _premiumStatusController.add(status);
      if (status.isPremium) {
        return PurchaseResult(
          success: true,
          cancelled: false,
          status: 'restored',
          customerStatus: status,
          message: 'Purchases restored successfully.',
        );
      }
      return PurchaseResult(
        success: false,
        cancelled: false,
        status: 'no_active_purchase',
        customerStatus: status,
        message: 'No active purchases were found to restore.',
      );
    } on PlatformException catch (error) {
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
