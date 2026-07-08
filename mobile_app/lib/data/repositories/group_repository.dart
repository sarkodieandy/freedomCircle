import '../models/accountability_group.dart';
import '../models/group_member.dart';
import 'supabase_repository.dart';

class GroupRepository extends SupabaseRepository {
  const GroupRepository({super.supabaseClient});

  Future<List<AccountabilityGroup>> groups() {
    return guard(() async {
      final rows = await client
          .from('public_group_cards')
          .select()
          .order('created_at', ascending: false);
      return mapRows(rows, AccountabilityGroup.fromMap);
    });
  }

  Future<List<GroupMember>> memberships(String userId) {
    return guard(() async {
      final rows = await client
          .from('group_members')
          .select()
          .eq('user_id', userId)
          .order('joined_at', ascending: false);
      return mapRows(rows, GroupMember.fromMap);
    });
  }

  Future<GroupMember> requestToJoin(String groupId, String userId) {
    return guard(() async {
      final row = await client
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': userId,
            'role': 'member',
            'status': 'pending',
          })
          .select()
          .single();
      return GroupMember.fromMap(mapRow(row));
    });
  }
}
