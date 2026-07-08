import '../models/payment.dart';
import '../models/subscription.dart';
import 'supabase_repository.dart';

class SubscriptionRepository extends SupabaseRepository {
  const SubscriptionRepository({super.supabaseClient});

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
}
