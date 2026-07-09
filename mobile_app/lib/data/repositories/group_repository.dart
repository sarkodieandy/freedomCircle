import '../models/accountability_group.dart';
import '../models/group_member.dart';
import '../../core/services/monetization_service.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class GroupRepository extends SupabaseRepository {
  const GroupRepository({super.supabaseClient});

  String? get _currentUserId => SupabaseService.currentUserId;

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

  Future<GroupMember?> getMembership(String groupId, String userId) {
    return guard(() async {
      final row = await client
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : GroupMember.fromMap(mapRow(row));
    });
  }

  Future<GroupMember> joinGroup({
    required String groupId,
    required String userId,
    bool autoApprove = false,
  }) {
    return guard(() async {
      final row = await client
          .from('group_members')
          .upsert({
            'group_id': groupId,
            'user_id': userId,
            'role': 'member',
            'status': autoApprove ? 'approved' : 'pending',
          }, onConflict: 'group_id,user_id')
          .select()
          .single();
      return GroupMember.fromMap(mapRow(row));
    });
  }

  Future<bool> canCurrentUserCreatePremiumGroup() {
    return MonetizationService.instance.hasFeature('premium_groups');
  }

  Future<AccountabilityGroup> createGroupAndJoinAsOwner({
    required String name,
    required String description,
    required String visibility,
    required String groupType,
    required bool isPremium,
    String? coverImageUrl,
  }) {
    return guard(() async {
      final userId = _currentUserId;
      if (userId == null) {
        throw StateError('You must be logged in to create a group.');
      }

      final insertRow = await client
          .from('groups')
          .insert({
            'owner_id': userId,
            'name': name,
            'description': description,
            'visibility': visibility,
            'group_type': groupType,
            'is_premium': isPremium,
            if (coverImageUrl != null && coverImageUrl.isNotEmpty)
              'cover_image_url': coverImageUrl,
          })
          .select()
          .single();

      final groupId = mapRow(insertRow)['id']?.toString() ?? '';
      if (groupId.isEmpty) {
        throw StateError('Group creation did not return a valid id.');
      }

      await client.from('group_members').upsert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'owner',
        'status': 'approved',
      }, onConflict: 'group_id,user_id');

      await getOrCreateGroupConversationId(groupId);

      final card = await getGroupById(groupId);
      if (card != null) return card;
      return AccountabilityGroup.fromMap(mapRow(insertRow));
    });
  }

  Future<String> getOrCreateGroupConversationId(
    String groupId, {
    bool prayerGroup = false,
  }) {
    return guard(() async {
      final result = await client.rpc(
        'get_or_create_group_chat',
        params: {
          'group_uuid': groupId,
          'conversation_kind': prayerGroup ? 'prayer_group' : 'group',
        },
      );
      return result?.toString() ?? '';
    });
  }

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
