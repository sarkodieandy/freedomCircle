import 'model_helpers.dart';

class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.role = 'member',
    this.status = 'active',
    this.lastReadAt,
    this.joinedAt,
  });

  final String id;
  final String conversationId;
  final String userId;
  final String role;
  final String status;
  final DateTime? lastReadAt;
  final DateTime? joinedAt;

  factory ChatParticipant.fromMap(JsonMap map) {
    return ChatParticipant(
      id: readString(map, 'id'),
      conversationId: readString(map, 'conversation_id'),
      userId: readString(map, 'user_id'),
      role: readString(map, 'role', fallback: 'member'),
      status: readString(map, 'status', fallback: 'active'),
      lastReadAt: DateTime.tryParse(readString(map, 'last_read_at')),
      joinedAt: DateTime.tryParse(readString(map, 'joined_at')),
    );
  }
}
