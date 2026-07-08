import 'model_helpers.dart';

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.isAnonymous = false,
    this.isModerator = false,
  });

  final String id;
  final String groupId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool isAnonymous;
  final bool isModerator;

  factory GroupMessage.fromMap(JsonMap map) {
    return GroupMessage(
      id: readString(map, 'id'),
      groupId: readString(map, 'group_id'),
      senderName: readString(map, 'sender_name', fallback: 'Member'),
      message: readString(map, 'message'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      isAnonymous: readBool(map, 'is_anonymous'),
      isModerator: readBool(map, 'is_moderator'),
    );
  }
}
