import 'model_helpers.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.messageType,
    required this.status,
    required this.createdAt,
    this.groupId,
    this.senderId,
    this.body,
    this.attachmentUrl,
    this.attachmentPath,
    this.attachmentMimeType,
    this.attachmentSizeBytes,
    this.audioDurationSeconds,
    this.waveform = const [],
    this.isAnonymous = false,
    this.replyToMessageId,
    this.metadata = const {},
    this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String messageType;
  final String status;
  final DateTime createdAt;
  final String? groupId;
  final String? senderId;
  final String? body;
  final String? attachmentUrl;
  final String? attachmentPath;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;
  final int? audioDurationSeconds;
  final List<double> waveform;
  final bool isAnonymous;
  final String? replyToMessageId;
  final JsonMap metadata;
  final DateTime? updatedAt;

  bool get isVoice => messageType == 'voice';
  bool get isDeleted => status == 'deleted' || status == 'hidden';

  factory ChatMessage.fromMap(JsonMap map) {
    final waveformValue = map['waveform'];
    final metadataValue = map['metadata'];
    return ChatMessage(
      id: readString(map, 'id'),
      conversationId: readString(map, 'conversation_id'),
      messageType: readString(map, 'message_type', fallback: 'text'),
      status: readString(map, 'status', fallback: 'active'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      groupId: readNullableString(map, 'group_id'),
      senderId: readNullableString(map, 'sender_id'),
      body: readNullableString(map, 'body'),
      attachmentUrl: readNullableString(map, 'attachment_url'),
      attachmentPath: readNullableString(map, 'attachment_path'),
      attachmentMimeType: readNullableString(map, 'attachment_mime_type'),
      attachmentSizeBytes: readInt(map, 'attachment_size_bytes'),
      audioDurationSeconds: readInt(map, 'audio_duration_seconds'),
      waveform: waveformValue is List
          ? waveformValue.map((value) => (value as num).toDouble()).toList()
          : const [],
      isAnonymous: readBool(map, 'is_anonymous'),
      replyToMessageId: readNullableString(map, 'reply_to_message_id'),
      metadata: metadataValue is Map ? JsonMap.from(metadataValue) : const {},
      updatedAt: DateTime.tryParse(readString(map, 'updated_at')),
    );
  }
}
