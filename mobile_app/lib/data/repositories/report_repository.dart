import '../models/report_item.dart';
import 'supabase_repository.dart';

class ReportRepository extends SupabaseRepository {
  const ReportRepository({super.supabaseClient});

  Future<ReportItem> createReportRecord(Map<String, dynamic> values) =>
      createReport(values);

  Future<ReportItem> createReport(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client.from('reports').insert(values).select().single();
      return ReportItem.fromMap(mapRow(row));
    });
  }

  Future<List<ReportItem>> myReports(String reporterId) {
    return guard(() async {
      final rows = await client
          .from('reports')
          .select()
          .eq('reporter_id', reporterId)
          .order('created_at', ascending: false);
      return mapRows(rows, ReportItem.fromMap);
    });
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    String reason = 'safety_report',
  }) {
    return guard(() async {
      await client.from('user_blocks').upsert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
        'reason': reason,
      }, onConflict: 'blocker_id,blocked_id');
    });
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) {
    return guard(() async {
      await client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
    });
  }

  Future<List<Map<String, dynamic>>> blockedUsers(String blockerId) {
    return guard(() async {
      final rows = await client
          .from('user_blocks')
          .select()
          .eq('blocker_id', blockerId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }
}
