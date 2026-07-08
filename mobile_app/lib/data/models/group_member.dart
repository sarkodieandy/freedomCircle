import 'model_helpers.dart';

class GroupMember {
  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
  });

  final String groupId;
  final String userId;
  final String role;
  final String status;

  factory GroupMember.fromMap(JsonMap map) {
    return GroupMember(
      groupId: readString(map, 'group_id'),
      userId: readString(map, 'user_id'),
      role: readString(map, 'role', fallback: 'member'),
      status: readString(map, 'status', fallback: 'pending'),
    );
  }
}
