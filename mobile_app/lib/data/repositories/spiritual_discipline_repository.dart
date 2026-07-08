import '../models/spiritual_logs.dart';
import 'supabase_repository.dart';

class SpiritualDisciplineRepository extends SupabaseRepository {
  const SpiritualDisciplineRepository({super.supabaseClient});

  Future<List<PrayerLog>> getPrayerLogs(String userId) => prayerLogs(userId);

  Future<List<FastingLog>> getFastingLogs(String userId) => fastingLogs(userId);

  Future<List<BibleStudyLog>> getBibleStudyLogs(String userId) =>
      bibleStudyLogs(userId);

  Future<List<DailyCheckin>> getCheckinHistory(String userId) =>
      dailyCheckins(userId);

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

  Future<PrayerLog> createPrayerLog(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('prayer_logs')
          .insert(values)
          .select()
          .single();
      return PrayerLog.fromMap(mapRow(row));
    });
  }

  Future<FastingLog> createFastingLog(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('fasting_logs')
          .insert(values)
          .select()
          .single();
      return FastingLog.fromMap(mapRow(row));
    });
  }

  Future<FastingLog> updateFastingLog(
    String fastingLogId,
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('fasting_logs')
          .update(values)
          .eq('id', fastingLogId)
          .select()
          .single();
      return FastingLog.fromMap(mapRow(row));
    });
  }

  Future<BibleStudyLog> createBibleStudyLog(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('bible_study_logs')
          .insert(values)
          .select()
          .single();
      return BibleStudyLog.fromMap(mapRow(row));
    });
  }

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

  Future<DailyCheckin> submitDailyCheckin(Map<String, dynamic> values) =>
      upsertDailyCheckin(values);

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
}
