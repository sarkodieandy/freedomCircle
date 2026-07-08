import '../models/recovery_category.dart';
import '../models/recovery_goal.dart';
import '../models/recovery_log.dart';
import 'supabase_repository.dart';

class RecoveryRepository extends SupabaseRepository {
  const RecoveryRepository({super.supabaseClient});

  Future<List<RecoveryCategory>> getRecoveryCategories() => categories();

  Future<List<RecoveryGoal>> getUserRecoveryGoals(String userId) =>
      goals(userId);

  Future<List<RecoveryLog>> getRecoveryLogs(String goalId) =>
      logsForGoal(goalId);

  Future<RecoveryGoal> createRecoveryGoal(Map<String, dynamic> values) =>
      createGoal(values);

  Future<RecoveryLog> createRecoveryLog(Map<String, dynamic> values) =>
      createLog(values);

  Future<List<RecoveryCategory>> categories() {
    return guard(() async {
      final rows = await client
          .from('recovery_categories')
          .select()
          .order('sort_order');
      return mapRows(rows, RecoveryCategory.fromMap);
    });
  }

  Future<List<RecoveryGoal>> goals(String userId) {
    return guard(() async {
      final rows = await client
          .from('user_recovery_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, RecoveryGoal.fromMap);
    });
  }

  Future<List<RecoveryLog>> logsForGoal(String goalId) {
    return guard(() async {
      final rows = await client
          .from('recovery_logs')
          .select()
          .eq('goal_id', goalId)
          .order('log_date', ascending: false);
      return mapRows(rows, RecoveryLog.fromMap);
    });
  }

  Future<RecoveryGoal> createGoal(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('user_recovery_goals')
          .insert(values)
          .select()
          .single();
      return RecoveryGoal.fromMap(mapRow(row));
    });
  }

  Future<RecoveryLog> createLog(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('recovery_logs')
          .insert(values)
          .select()
          .single();
      return RecoveryLog.fromMap(mapRow(row));
    });
  }

  Future<RecoveryGoal> updateRecoveryGoal(
    String goalId,
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('user_recovery_goals')
          .update(values)
          .eq('id', goalId)
          .select()
          .single();
      return RecoveryGoal.fromMap(mapRow(row));
    });
  }

  Future<void> archiveRecoveryGoal(String goalId) {
    return guard(() async {
      await client
          .from('user_recovery_goals')
          .update({'is_archived': true})
          .eq('id', goalId);
    });
  }

  Future<List<RecoveryLog>> getRecoveryCalendar(String userId) {
    return guard(() async {
      final rows = await client
          .from('recovery_logs')
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false)
          .limit(90);
      return mapRows(rows, RecoveryLog.fromMap);
    });
  }

  Future<Map<String, dynamic>> getRecoveryInsights(String userId) {
    return guard(() async {
      final row = await client
          .from('recovery_insights')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? <String, dynamic>{} : mapRow(row);
    });
  }

  Future<List<Map<String, dynamic>>> getMilestones(String userId) {
    return guard(() async {
      final rows = await client
          .from('recovery_milestones')
          .select()
          .eq('user_id', userId)
          .order('milestone_date', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }
}
