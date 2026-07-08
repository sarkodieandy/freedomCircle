import '../models/report_item.dart';
import 'supabase_repository.dart';

class ReportRepository extends SupabaseRepository {
  const ReportRepository({super.supabaseClient});

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
}
