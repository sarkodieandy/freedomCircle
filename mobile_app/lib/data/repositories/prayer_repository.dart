import '../models/prayer_request.dart';
import 'supabase_repository.dart';

class PrayerRepository extends SupabaseRepository {
  const PrayerRepository({super.supabaseClient});

  Future<List<PrayerRequest>> prayerRequests({String? groupId}) {
    return guard(() async {
      final query = client.from('prayer_requests').select();
      final rows = groupId == null
          ? await query.order('created_at', ascending: false)
          : await query
                .eq('group_id', groupId)
                .order('created_at', ascending: false);
      return mapRows(rows, PrayerRequest.fromMap);
    });
  }

  Future<PrayerRequest> createPrayerRequest(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('prayer_requests')
          .insert(values)
          .select()
          .single();
      return PrayerRequest.fromMap(mapRow(row));
    });
  }

  Future<void> markPrayed({
    required String prayerRequestId,
    required String userId,
  }) {
    return guard(() async {
      await client.from('prayer_interactions').upsert({
        'prayer_request_id': prayerRequestId,
        'user_id': userId,
      });
    });
  }
}
