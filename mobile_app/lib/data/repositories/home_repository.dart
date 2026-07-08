import '../models/accountability_group.dart';
import 'supabase_repository.dart';

class HomeRepository extends SupabaseRepository {
  const HomeRepository({super.supabaseClient});

  Future<Map<String, dynamic>> getDashboardSummary(String userId) {
    return guard(() async {
      final row = await client
          .from('home_dashboard_summary')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? <String, dynamic>{} : mapRow(row);
    });
  }

  Future<Map<String, dynamic>?> getTodayFocus(String userId) {
    return guard(() async {
      final row = await client
          .from('user_onboarding_preferences')
          .select('focus_area,reminder_time')
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : mapRow(row);
    });
  }

  Future<Map<String, dynamic>?> getDailyVerse() {
    return guard(() async {
      final row = await client
          .from('app_content')
          .select()
          .eq('content_type', 'daily_verse')
          .eq('is_active', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : mapRow(row);
    });
  }

  Future<List<Map<String, dynamic>>> getUpcomingGroupSessions(String userId) {
    return guard(() async {
      final rows = await client
          .from('group_sessions')
          .select()
          .eq('user_id', userId)
          .gte('scheduled_at', DateTime.now().toIso8601String())
          .order('scheduled_at')
          .limit(5);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }

  Future<List<AccountabilityGroup>> getSuggestedGroups() {
    return guard(() async {
      final rows = await client
          .from('public_group_cards')
          .select()
          .order('created_at', ascending: false)
          .limit(6);
      return mapRows(rows, AccountabilityGroup.fromMap);
    });
  }

  Future<Map<String, dynamic>> getUserStreakSummary(String userId) {
    return guard(() async {
      final row = await client
          .from('user_streak_summary')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? <String, dynamic>{} : mapRow(row);
    });
  }
}
