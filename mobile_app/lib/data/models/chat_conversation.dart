import 'model_helpers.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.conversationType,
    required this.status,
    required this.createdAt,
    this.groupId,
    this.supportRequestId,
    this.bookingId,
    this.title,
    this.createdBy,
    this.updatedAt,
  });

  final String id;
  final String conversationType;
  final String status;
  final DateTime createdAt;
  final String? groupId;
  final String? supportRequestId;
  final String? bookingId;
  final String? title;
  final String? createdBy;
  final DateTime? updatedAt;

  bool get isGroup =>
      conversationType == 'group' || conversationType == 'prayer_group';
  bool get isSupport => conversationType == 'support_request';
  bool get isPrivate => conversationType == 'helper_private';

  factory ChatConversation.fromMap(JsonMap map) {
    return ChatConversation(
      id: readString(map, 'id'),
      conversationType: readString(map, 'conversation_type', fallback: 'group'),
      status: readString(map, 'status', fallback: 'active'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      groupId: readNullableString(map, 'group_id'),
      supportRequestId: readNullableString(map, 'support_request_id'),
      bookingId: readNullableString(map, 'booking_id'),
      title: readNullableString(map, 'title'),
      createdBy: readNullableString(map, 'created_by'),
      updatedAt: DateTime.tryParse(readString(map, 'updated_at')),
    );
  }
}
