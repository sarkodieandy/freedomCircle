import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
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
      throw const AuthException('Sign in before uploading audio.');
    }

    AppLogger.chat(
      'Recording upload started',
      data: {'conversation_id': conversationId, 'mime_type': mimeType},
    );
    return guard(
      () async {
        final extension = _extensionFor(mimeType);
        final path =
            '$conversationId/$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File(localFilePath);

        AppLogger.info(
          'File upload started',
          tag: 'STORAGE',
          data: {
            'bucket': 'chat-voice-notes',
            'file_path': path,
            'file_size_bytes': await file.length(),
          },
        );

        await client.storage
            .from('chat-voice-notes')
            .upload(
              path,
              file,
              fileOptions: FileOptions(contentType: mimeType, upsert: false),
            );

        AppLogger.info(
          'Upload success',
          tag: 'STORAGE',
          data: {'bucket': 'chat-voice-notes', 'file_path': path},
        );
        return path;
      },
      source: 'RecordingRepository.uploadVoiceNote',
      table: 'storage.chat-voice-notes',
      data: {'conversation_id': conversationId},
    );
  }

  Future<String> signedVoiceUrl(String filePath) {
    AppLogger.info(
      'Signed URL generation started',
      tag: 'STORAGE',
      data: {'bucket': 'chat-voice-notes', 'file_path': filePath},
    );
    return guard(
      () async {
        final url = client.storage
            .from('chat-voice-notes')
            .createSignedUrl(filePath, 60 * 15);
        AppLogger.info(
          'Signed URL generation success',
          tag: 'STORAGE',
          data: {'bucket': 'chat-voice-notes', 'file_path': filePath},
        );
        return url;
      },
      source: 'RecordingRepository.signedVoiceUrl',
      table: 'storage.chat-voice-notes',
    );
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
      throw const AuthException('Sign in before saving audio.');
    }

    return guard(
      () async {
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
        AppLogger.chat(
          'Recording upload success',
          data: {
            'conversation_id': conversationId,
            'duration_seconds': durationSeconds,
          },
        );
        return ChatRecording.fromMap(mapRow(row));
      },
      source: 'RecordingRepository.createRecordingMetadata',
      table: 'chat_recordings',
      data: {'conversation_id': conversationId},
    );
  }

  Future<void> deleteRecording(String recordingId) {
    return guard(
      () async {
        await client
            .from('chat_recordings')
            .update({'status': 'deleted'})
            .eq('id', recordingId);
        AppLogger.info(
          'File delete success',
          tag: 'STORAGE',
          data: {'recording_id': recordingId},
        );
      },
      source: 'RecordingRepository.deleteRecording',
      table: 'chat_recordings',
    );
  }

  Future<List<ChatRecording>> getConversationRecordings(String conversationId) {
    return guard(
      () async {
        final rows = await client
            .from('chat_recordings')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false);
        return mapRows(rows, ChatRecording.fromMap);
      },
      source: 'RecordingRepository.getConversationRecordings',
      table: 'chat_recordings',
      data: {'conversation_id': conversationId},
    );
  }

  String _extensionFor(String mimeType) {
    if (mimeType.contains('mpeg')) return 'mp3';
    if (mimeType.contains('wav')) return 'wav';
    if (mimeType.contains('webm')) return 'webm';
    return 'm4a';
  }
}
