import 'model_helpers.dart';

class ChatMessageReaction {
  const ChatMessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  factory ChatMessageReaction.fromMap(JsonMap map) {
    return ChatMessageReaction(
      id: readString(map, 'id'),
      messageId: readString(map, 'message_id'),
      userId: readString(map, 'user_id'),
      reaction: readString(map, 'reaction'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
    );
  }
}
