import '../models/recovery_category.dart';
import '../models/recovery_goal.dart';
import '../models/recovery_log.dart';
import 'supabase_repository.dart';

class RecoveryRepository extends SupabaseRepository {
  const RecoveryRepository({super.supabaseClient});

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
}
