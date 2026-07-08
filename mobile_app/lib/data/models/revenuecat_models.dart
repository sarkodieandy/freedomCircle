import 'model_helpers.dart';

class AppSubscriptionPackage {
  const AppSubscriptionPackage({
    required this.identifier,
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.priceString,
    required this.packageType,
  });

  final String identifier;
  final String productId;
  final String title;
  final String description;
  final double price;
  final String currencyCode;
  final String priceString;
  final String packageType;
}

class CustomerPremiumStatus {
  const CustomerPremiumStatus({
    required this.userId,
    required this.isPremium,
    required this.activeEntitlements,
    required this.activeProductIds,
    required this.updatedAt,
    this.latestExpirationDate,
    this.originalAppUserId,
    this.managementUrl,
  });

  final String userId;
  final bool isPremium;
  final List<String> activeEntitlements;
  final List<String> activeProductIds;
  final DateTime? latestExpirationDate;
  final String? originalAppUserId;
  final String? managementUrl;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'is_premium': isPremium,
      'active_entitlements': activeEntitlements,
      'active_product_ids': activeProductIds,
      'latest_expiration_date': latestExpirationDate?.toIso8601String(),
      'original_app_user_id': originalAppUserId,
      'management_url': managementUrl,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomerPremiumStatus.fromMap(JsonMap map) {
    return CustomerPremiumStatus(
      userId: readString(map, 'user_id'),
      isPremium: readBool(map, 'is_premium'),
      activeEntitlements: readStringList(map, 'active_entitlements'),
      activeProductIds: readStringList(map, 'active_product_ids'),
      latestExpirationDate: map['latest_expiration_date'] == null
          ? null
          : DateTime.tryParse(readString(map, 'latest_expiration_date')),
      originalAppUserId: readNullableString(map, 'original_app_user_id'),
      managementUrl: readNullableString(map, 'management_url'),
      updatedAt: readDateTime(map, 'updated_at', fallback: DateTime.now()),
    );
  }

  static CustomerPremiumStatus empty(String userId) {
    return CustomerPremiumStatus(
      userId: userId,
      isPremium: false,
      activeEntitlements: const [],
      activeProductIds: const [],
      updatedAt: DateTime.now(),
    );
  }
}

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.cancelled,
    required this.status,
    this.message,
    this.customerStatus,
  });

  final bool success;
  final bool cancelled;
  final String status;
  final String? message;
  final CustomerPremiumStatus? customerStatus;
}

class RevenueCatOfferingState {
  const RevenueCatOfferingState({
    required this.loading,
    required this.offeringId,
    required this.packages,
    this.error,
    this.selectedPackageId,
  });

  final bool loading;
  final String offeringId;
  final List<AppSubscriptionPackage> packages;
  final String? error;
  final String? selectedPackageId;

  RevenueCatOfferingState copyWith({
    bool? loading,
    String? offeringId,
    List<AppSubscriptionPackage>? packages,
    String? error,
    String? selectedPackageId,
  }) {
    return RevenueCatOfferingState(
      loading: loading ?? this.loading,
      offeringId: offeringId ?? this.offeringId,
      packages: packages ?? this.packages,
      error: error,
      selectedPackageId: selectedPackageId ?? this.selectedPackageId,
    );
  }

  static const empty = RevenueCatOfferingState(
    loading: false,
    offeringId: 'default',
    packages: [],
  );
}
