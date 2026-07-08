import '../models/prayer_request.dart';
import 'supabase_repository.dart';

class PrayerRepository extends SupabaseRepository {
  const PrayerRepository({super.supabaseClient});

  Future<List<PrayerRequest>> getPrayerRequests({String? groupId}) =>
      prayerRequests(groupId: groupId);

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

  Future<PrayerRequest> updatePrayerRequest(
    String prayerRequestId,
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('prayer_requests')
          .update(values)
          .eq('id', prayerRequestId)
          .select()
          .single();
      return PrayerRequest.fromMap(mapRow(row));
    });
  }

  Future<PrayerRequest> markPrayerAnswered(String prayerRequestId) {
    return guard(() async {
      final row = await client
          .from('prayer_requests')
          .update({'status': 'answered'})
          .eq('id', prayerRequestId)
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

  Future<void> prayForRequest({
    required String prayerRequestId,
    required String userId,
  }) => markPrayed(prayerRequestId: prayerRequestId, userId: userId);

  Future<List<PrayerRequest>> getAnsweredPrayers() {
    return guard(() async {
      final rows = await client
          .from('prayer_requests')
          .select()
          .eq('status', 'answered')
          .order('created_at', ascending: false);
      return mapRows(rows, PrayerRequest.fromMap);
    });
  }

  Future<List<PrayerRequest>> getGroupPrayerRequests(String groupId) =>
      prayerRequests(groupId: groupId);
}
