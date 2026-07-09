import '../../core/errors/app_exception.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/utils/app_logger.dart';
import '../models/revenuecat_models.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class SubscriptionRepository extends SupabaseRepository {
  const SubscriptionRepository({super.supabaseClient});

  Future<List<AppSubscriptionPackage>> getAvailablePackages() async {
    AppLogger.info('Offering fetch started', tag: 'REVENUECAT');
    final offerings = await RevenueCatService.instance.getOfferings();
    if (offerings.error != null) {
      AppLogger.error(
        'Offering fetch failure',
        tag: 'REVENUECAT',
        data: {'message': offerings.error},
      );
      throw ValidationException(offerings.error!);
    }
    AppLogger.info(
      'Offering fetch success',
      tag: 'REVENUECAT',
      data: {'package_count': offerings.packages.length},
    );
    return offerings.packages;
  }

  Future<CustomerPremiumStatus> getCustomerStatus() {
    return RevenueCatService.instance.getCustomerStatus();
  }

  Future<bool> isPremium() {
    return RevenueCatService.instance.isPremium();
  }

  Future<PurchaseResult> purchasePackage(AppSubscriptionPackage package) async {
    AppLogger.payment(
      'Purchase started',
      data: {'plan_code': package.productId},
    );
    await RevenueCatService.instance.getOfferings();
    final result = await RevenueCatService.instance.purchasePackage(package);
    if (result.success) {
      await syncPremiumStatusToSupabase();
      AppLogger.payment(
        'Payment success from backend',
        data: {'status': result.status},
      );
    } else if (result.cancelled) {
      AppLogger.payment('Payment pending', data: {'status': result.status});
    } else {
      AppLogger.warning(
        'Payment failed',
        tag: 'PAYMENT',
        data: {'status': result.status},
      );
    }
    return result;
  }

  Future<PurchaseResult> restorePurchases() async {
    AppLogger.payment('Restore started');
    final result = await RevenueCatService.instance.restorePurchases();
    if (result.success) {
      await syncPremiumStatusToSupabase();
      AppLogger.payment('Restore success');
    } else {
      AppLogger.warning(
        'Restore failure',
        tag: 'PAYMENT',
        data: {'status': result.status},
      );
    }
    return result;
  }

  Future<void> syncPremiumStatusToSupabase() {
    return guard(
      () async {
        AppLogger.supabase(
          'Syncing premium status to Supabase',
          table: 'revenuecat_customers',
        );
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
          AppLogger.supabase(
            'Subscription sync success',
            table: 'revenuecat_customers',
            data: {'user_id': userId, 'is_premium': status.isPremium},
          );
        } catch (_) {
          // Client-side sync is best-effort; authoritative entitlements come from
          // webhook verification on server-side infrastructure.
          AppLogger.warning(
            'Subscription sync failed (best-effort)',
            tag: 'REVENUECAT',
            data: {'user_id': userId},
          );
        }
      },
      source: 'SubscriptionRepository.syncPremiumStatusToSupabase',
      table: 'revenuecat_customers',
    );
  }

  Stream<CustomerPremiumStatus> watchPremiumStatus() {
    return RevenueCatService.instance.premiumStatusStream;
  }
}
