import 'supabase_repository.dart';

class SafetyRepository extends SupabaseRepository {
  const SafetyRepository({super.supabaseClient});

  Future<void> createReport(Map<String, dynamic> values) {
    return guard(() async {
      await client.from('reports').insert(values);
    });
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
    String reason = 'safety_action',
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

  Future<List<Map<String, dynamic>>> getBlockedUsers(String blockerId) {
    return guard(() async {
      final rows = await client
          .from('user_blocks')
          .select()
          .eq('blocker_id', blockerId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }

  Future<void> contactSupportPlaceholder() async {
    // TODO(server): route support contact to Laravel support workflow.
  }
}
