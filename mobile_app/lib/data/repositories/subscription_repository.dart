import '../../core/errors/app_exception.dart';
import '../../core/services/revenuecat_service.dart';
import '../models/revenuecat_models.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class SubscriptionRepository extends SupabaseRepository {
  const SubscriptionRepository({super.supabaseClient});

  Future<List<AppSubscriptionPackage>> getAvailablePackages() async {
    final offerings = await RevenueCatService.instance.getOfferings();
    if (offerings.error != null) {
      throw ValidationException(offerings.error!);
    }
    return offerings.packages;
  }

  Future<CustomerPremiumStatus> getCustomerStatus() {
    return RevenueCatService.instance.getCustomerStatus();
  }

  Future<bool> isPremium() {
    return RevenueCatService.instance.isPremium();
  }

  Future<PurchaseResult> purchasePackage(AppSubscriptionPackage package) async {
    await RevenueCatService.instance.getOfferings();
    final result = await RevenueCatService.instance.purchasePackage(package);
    if (result.success) {
      await syncPremiumStatusToSupabase();
    }
    return result;
  }

  Future<PurchaseResult> restorePurchases() async {
    final result = await RevenueCatService.instance.restorePurchases();
    if (result.success) {
      await syncPremiumStatusToSupabase();
    }
    return result;
  }

  Future<void> syncPremiumStatusToSupabase() {
    return guard(() async {
      final status = await RevenueCatService.instance.getCustomerStatus();
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        throw const AuthException(
          'Sign in before syncing subscription status.',
        );
      }

      try {
        await client.from('revenuecat_customers').upsert({
          'user_id': userId,
          'revenuecat_app_user_id': userId,
          'original_app_user_id': status.originalAppUserId,
          'management_url': status.managementUrl,
          'latest_customer_info': status.toMap(),
          'is_premium': status.isPremium,
          'latest_expiration_at': status.latestExpirationDate
              ?.toIso8601String(),
          'last_synced_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (_) {
        // Client-side sync is best-effort; authoritative entitlements come from
        // webhook verification on server-side infrastructure.
      }
    });
  }

  Stream<CustomerPremiumStatus> watchPremiumStatus() {
    return RevenueCatService.instance.premiumStatusStream;
  }
}
