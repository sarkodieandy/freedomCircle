import '../models/spiritual_logs.dart';
import 'supabase_repository.dart';

class CheckinRepository extends SupabaseRepository {
  const CheckinRepository({super.supabaseClient});

  Future<DailyCheckin?> getTodayCheckin(String userId) {
    return guard(() async {
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final row = await client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .eq('checkin_date', today)
          .maybeSingle();
      return row == null ? null : DailyCheckin.fromMap(mapRow(row));
    });
  }

  Future<DailyCheckin> submitDailyCheckin(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('daily_checkins')
          .upsert(values)
          .select()
          .single();
      return DailyCheckin.fromMap(mapRow(row));
    });
  }

  Future<DailyCheckin> updateDailyCheckin(
    String checkinId,
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('daily_checkins')
          .update(values)
          .eq('id', checkinId)
          .select()
          .single();
      return DailyCheckin.fromMap(mapRow(row));
    });
  }

  Future<List<DailyCheckin>> getCheckinHistory(String userId) {
    return guard(() async {
      final rows = await client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .order('checkin_date', ascending: false)
          .limit(60);
      return mapRows(rows, DailyCheckin.fromMap);
    });
  }
}
