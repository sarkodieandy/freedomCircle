import 'model_helpers.dart';

class ChatRecording {
  const ChatRecording({
    required this.id,
    required this.conversationId,
    required this.fileUrl,
    required this.filePath,
    required this.createdAt,
    this.messageId,
    this.userId,
    this.recordingType = 'voice_note',
    this.durationSeconds = 0,
    this.mimeType,
    this.sizeBytes,
    this.transcript,
    this.status = 'active',
    this.consentConfirmed = false,
    this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String? messageId;
  final String? userId;
  final String recordingType;
  final String fileUrl;
  final String filePath;
  final int durationSeconds;
  final String? mimeType;
  final int? sizeBytes;
  final String? transcript;
  final String status;
  final bool consentConfirmed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ChatRecording.fromMap(JsonMap map) {
    return ChatRecording(
      id: readString(map, 'id'),
      conversationId: readString(map, 'conversation_id'),
      messageId: readNullableString(map, 'message_id'),
      userId: readNullableString(map, 'user_id'),
      recordingType: readString(map, 'recording_type', fallback: 'voice_note'),
      fileUrl: readString(map, 'file_url'),
      filePath: readString(map, 'file_path'),
      durationSeconds: readInt(map, 'duration_seconds'),
      mimeType: readNullableString(map, 'mime_type'),
      sizeBytes: readInt(map, 'size_bytes'),
      transcript: readNullableString(map, 'transcript'),
      status: readString(map, 'status', fallback: 'active'),
      consentConfirmed: readBool(map, 'consent_confirmed'),
      createdAt: readDateTime(map, 'created_at', fallback: DateTime.now()),
      updatedAt: DateTime.tryParse(readString(map, 'updated_at')),
    );
  }
}
