import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_recording.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class RecordingRepository extends SupabaseRepository {
  const RecordingRepository({super.supabaseClient});

  String? get _userId => SupabaseService.currentUser?.id;

  Future<String> uploadVoiceNote({
    required String conversationId,
    required String localFilePath,
    required String mimeType,
  }) {
    final userId = _userId;
    if (userId == null) {
      throw const SupabaseRepositoryException(
        'Sign in before uploading audio.',
      );
    }

    return guard(() async {
      final extension = _extensionFor(mimeType);
      final path =
          '$conversationId/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      await client.storage
          .from('chat-voice-notes')
          .upload(
            path,
            File(localFilePath),
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );
      return path;
    });
  }

  Future<String> signedVoiceUrl(String filePath) {
    return guard(() async {
      return client.storage
          .from('chat-voice-notes')
          .createSignedUrl(filePath, 60 * 15);
    });
  }

  Future<ChatRecording> createRecordingMetadata({
    required String conversationId,
    required String filePath,
    required String fileUrl,
    required int durationSeconds,
    required String mimeType,
    String? messageId,
    int? sizeBytes,
    bool consentConfirmed = false,
  }) {
    final userId = _userId;
    if (userId == null) {
      throw const SupabaseRepositoryException('Sign in before saving audio.');
    }

    return guard(() async {
      final row = await client
          .from('chat_recordings')
          .insert({
            'conversation_id': conversationId,
            'message_id': messageId,
            'user_id': userId,
            'recording_type': 'voice_note',
            'file_url': fileUrl,
            'file_path': filePath,
            'duration_seconds': durationSeconds,
            'mime_type': mimeType,
            'size_bytes': sizeBytes,
            'consent_confirmed': consentConfirmed,
          })
          .select()
          .single();
      return ChatRecording.fromMap(mapRow(row));
    });
  }

  Future<void> deleteRecording(String recordingId) {
    return guard(() async {
      await client
          .from('chat_recordings')
          .update({'status': 'deleted'})
          .eq('id', recordingId);
    });
  }

  Future<List<ChatRecording>> getConversationRecordings(String conversationId) {
    return guard(() async {
      final rows = await client
          .from('chat_recordings')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);
      return mapRows(rows, ChatRecording.fromMap);
    });
  }

  String _extensionFor(String mimeType) {
    if (mimeType.contains('mpeg')) return 'mp3';
    if (mimeType.contains('wav')) return 'wav';
    if (mimeType.contains('webm')) return 'webm';
    return 'm4a';
  }
}
