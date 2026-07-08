import '../models/payment.dart';
import '../models/subscription.dart';
import '../models/monetization_models.dart';
import 'supabase_repository.dart';

class SubscriptionRepository extends SupabaseRepository {
  const SubscriptionRepository({super.supabaseClient});

  Future<UserSubscription?> getCurrentSubscription(String userId) =>
      currentStatus(userId);

  Future<UserSubscription?> currentStatus(String userId) {
    return guard(() async {
      final row = await client
          .from('user_subscription_status')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : UserSubscription.fromMap(mapRow(row));
    });
  }

  Future<List<Payment>> payments(String userId) {
    return guard(() async {
      final rows = await client
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, Payment.fromMap);
    });
  }

  Future<List<Payment>> getPaymentHistory(String userId) => payments(userId);

  Future<Payment> createPendingPayment(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('payments')
          .insert(values)
          .select()
          .single();
      return Payment.fromMap(mapRow(row));
    });
  }

  Future<List<MonetizationPlan>> getAvailablePlans({String? planType}) {
    return guard(() async {
      var query = client
          .from('plans')
          .select('*, plan_features(*)')
          .eq('is_active', true);
      if (planType != null) {
        query = query.eq('plan_type', planType);
      }
      final rows = await query.order('sort_order');
      return mapRows(rows, MonetizationPlan.fromMap);
    });
  }

  Future<List<PlanFeature>> getPlanFeatures(String planId) {
    return guard(() async {
      final rows = await client
          .from('plan_features')
          .select()
          .eq('plan_id', planId)
          .order('feature_key');
      return mapRows(rows, PlanFeature.fromMap);
    });
  }

  Future<List<Map<String, dynamic>>> getUserEntitlements(String userId) {
    return guard(() async {
      final rows = await client
          .from('entitlements')
          .select()
          .eq('subject_user_id', userId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }

  Future<void> restorePurchasesPlaceholder() async {
    // TODO(mobile-iap): integrate with App Store / Google Play restore flows.
  }

  Future<void> startUpgradeFlowPlaceholder({String? planCode}) async {
    // TODO(server): call Laravel/Paystack or native IAP flow and verify server-side.
  }
}
