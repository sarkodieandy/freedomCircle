import '../models/spiritual_logs.dart';
import 'supabase_repository.dart';

class SpiritualDisciplineRepository extends SupabaseRepository {
  const SpiritualDisciplineRepository({super.supabaseClient});

  Future<List<PrayerLog>> prayerLogs(String userId) {
    return guard(() async {
      final rows = await client
          .from('prayer_logs')
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false);
      return mapRows(rows, PrayerLog.fromMap);
    });
  }

  Future<List<FastingLog>> fastingLogs(String userId) {
    return guard(() async {
      final rows = await client
          .from('fasting_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, FastingLog.fromMap);
    });
  }

  Future<List<BibleStudyLog>> bibleStudyLogs(String userId) {
    return guard(() async {
      final rows = await client
          .from('bible_study_logs')
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false);
      return mapRows(rows, BibleStudyLog.fromMap);
    });
  }

  Future<List<DailyCheckin>> dailyCheckins(String userId) {
    return guard(() async {
      final rows = await client
          .from('daily_checkins')
          .select()
          .eq('user_id', userId)
          .order('checkin_date', ascending: false);
      return mapRows(rows, DailyCheckin.fromMap);
    });
  }

  Future<DailyCheckin> upsertDailyCheckin(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('daily_checkins')
          .upsert(values)
          .select()
          .single();
      return DailyCheckin.fromMap(mapRow(row));
    });
  }
}
