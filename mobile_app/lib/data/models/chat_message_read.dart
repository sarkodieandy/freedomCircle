import 'model_helpers.dart';

class ChatMessageRead {
  const ChatMessageRead({
    required this.id,
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.readAt,
  });

  final String id;
  final String messageId;
  final String conversationId;
  final String userId;
  final DateTime readAt;

  factory ChatMessageRead.fromMap(JsonMap map) {
    return ChatMessageRead(
      id: readString(map, 'id'),
      messageId: readString(map, 'message_id'),
      conversationId: readString(map, 'conversation_id'),
      userId: readString(map, 'user_id'),
      readAt: readDateTime(map, 'read_at', fallback: DateTime.now()),
    );
  }
}
