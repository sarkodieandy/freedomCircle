import '../models/accountability_group.dart';
import '../models/group_member.dart';
import 'supabase_repository.dart';

class GroupRepository extends SupabaseRepository {
  const GroupRepository({super.supabaseClient});

  Future<List<AccountabilityGroup>> getPublicGroups() => groups();

  Future<List<AccountabilityGroup>> getSuggestedGroups() => groups();

  Future<List<AccountabilityGroup>> getJoinedGroups(String userId) {
    return guard(() async {
      final rows = await client
          .from('public_group_cards')
          .select()
          .eq('membership_status', 'approved')
          .eq('member_user_id', userId)
          .order('created_at', ascending: false);
      return mapRows(rows, AccountabilityGroup.fromMap);
    });
  }

  Future<AccountabilityGroup?> getGroupById(String groupId) {
    return guard(() async {
      final row = await client
          .from('public_group_cards')
          .select()
          .eq('id', groupId)
          .maybeSingle();
      return row == null ? null : AccountabilityGroup.fromMap(mapRow(row));
    });
  }

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

  Future<GroupMember> requestJoinGroup(String groupId, String userId) =>
      requestToJoin(groupId, userId);

  Future<void> leaveGroup(String groupId, String userId) {
    return guard(() async {
      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);
    });
  }

  Future<GroupMember> approveMember(String groupMemberId) {
    return guard(() async {
      final row = await client
          .from('group_members')
          .update({'status': 'approved'})
          .eq('id', groupMemberId)
          .select()
          .single();
      return GroupMember.fromMap(mapRow(row));
    });
  }

  Future<GroupMember> blockMember(String groupMemberId) {
    return guard(() async {
      final row = await client
          .from('group_members')
          .update({'status': 'blocked'})
          .eq('id', groupMemberId)
          .select()
          .single();
      return GroupMember.fromMap(mapRow(row));
    });
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) {
    return guard(() async {
      final rows = await client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .order('joined_at', ascending: false);
      return mapRows(rows, GroupMember.fromMap);
    });
  }

  Future<List<Map<String, dynamic>>> getGroupResources(String groupId) {
    return guard(() async {
      final rows = await client
          .from('group_resources')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }

  Future<Map<String, dynamic>> createGroupResource(
    Map<String, dynamic> values,
  ) {
    return guard(() async {
      final row = await client
          .from('group_resources')
          .insert(values)
          .select()
          .single();
      return mapRow(row);
    });
  }

  Future<List<Map<String, dynamic>>> getGroupCheckins(String groupId) {
    return guard(() async {
      final rows = await client
          .from('group_checkins')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }

  Future<Map<String, dynamic>> submitGroupCheckin(Map<String, dynamic> values) {
    return guard(() async {
      final row = await client
          .from('group_checkins')
          .insert(values)
          .select()
          .single();
      return mapRow(row);
    });
  }

  Future<List<Map<String, dynamic>>> getGroupLeaderboard(String groupId) {
    return guard(() async {
      final rows = await client
          .from('group_members')
          .select('user_id, accountability_score, streak_days')
          .eq('group_id', groupId)
          .eq('status', 'approved')
          .order('accountability_score', ascending: false)
          .limit(20);
      return (rows as List).map((item) => mapRow(item)).toList();
    });
  }
}
