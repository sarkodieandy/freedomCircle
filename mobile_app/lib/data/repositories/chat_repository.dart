import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/model_helpers.dart';
import '../../core/utils/app_logger.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class ChatRepository extends SupabaseRepository {
  const ChatRepository({super.supabaseClient});

  String? get _userId => SupabaseService.currentUser?.id;

  Future<List<ChatConversation>> getUserConversations() {
    if (!SupabaseService.isInitialized || _userId == null) {
      AppLogger.chat(
        'Loading conversations skipped',
        data: {'reason': 'not_initialized_or_no_user'},
      );
      return Future.value(const []);
    }

    AppLogger.chat('Loading conversations', data: {'user_id': _userId});
    return guard(
      () async {
        final rows = await client
            .from('chat_conversations')
            .select()
            .order('updated_at', ascending: false);
        return mapRows(rows, ChatConversation.fromMap);
      },
      source: 'ChatRepository.getUserConversations',
      table: 'chat_conversations',
    );
  }

  Future<ChatConversation> getOrCreateGroupConversation(String groupId) async {
    final id = await _rpcString('get_or_create_group_chat', {
      'group_uuid': groupId,
      'conversation_kind': 'group',
    });
    return _conversation(id);
  }

  Future<ChatConversation> getOrCreatePrayerGroupConversation(
    String groupId,
  ) async {
    final id = await _rpcString('get_or_create_group_chat', {
      'group_uuid': groupId,
      'conversation_kind': 'prayer_group',
    });
    return _conversation(id);
  }

  Future<ChatConversation> getOrCreatePrivateConversation(
    String otherUserId,
  ) async {
    final id = await _rpcString('get_or_create_private_chat', {
      'other_user_uuid': otherUserId,
    });
    return _conversation(id);
  }

  Future<ChatConversation> getOrCreateSupportConversation(
    String supportRequestId,
  ) async {
    final id = await _rpcString('get_or_create_support_chat', {
      'support_request_uuid': supportRequestId,
    });
    return _conversation(id);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) {
    if (!SupabaseService.isInitialized) return Future.value(const []);

    AppLogger.chat(
      'Loading messages',
      data: {'conversation_id': conversationId},
    );
    return guard(
      () async {
        final rows = await client
            .from('chat_messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: false)
            .limit(50);
        return mapRows(rows, ChatMessage.fromMap).reversed.toList();
      },
      source: 'ChatRepository.getMessages',
      table: 'chat_messages',
      data: {'conversation_id': conversationId},
    );
  }

  Stream<List<ChatMessage>> listenToMessages(String conversationId) {
    if (!SupabaseService.isInitialized) return Stream.value(const []);

    AppLogger.chat(
      'Message realtime stream subscribed',
      data: {'conversation_id': conversationId},
    );

    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) {
          AppLogger.chat(
            'Message realtime received',
            data: {'conversation_id': conversationId, 'count': rows.length},
          );
          return mapRows(rows, ChatMessage.fromMap);
        });
  }

  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    String? groupId,
    required String body,
    bool isAnonymous = false,
    String? replyToMessageId,
  }) {
    AppLogger.chat(
      'Sending text message',
      data: {
        'conversation_id': conversationId,
        'group_id': groupId,
        'is_anonymous': isAnonymous,
      },
    );
    return guard(
      () async {
        final row = await client
            .from('chat_messages')
            .insert({
              'conversation_id': conversationId,
              'group_id': groupId,
              'sender_id': _userId,
              'message_type': 'text',
              'body': body.trim(),
              'is_anonymous': isAnonymous,
              'reply_to_message_id': replyToMessageId,
            })
            .select()
            .single();
        AppLogger.chat(
          'Message sent success',
          data: {'conversation_id': conversationId, 'type': 'text'},
        );
        return ChatMessage.fromMap(mapRow(row));
      },
      source: 'ChatRepository.sendTextMessage',
      table: 'chat_messages',
      data: {'conversation_id': conversationId},
    );
  }

  Future<ChatMessage> sendVoiceMessage({
    required String conversationId,
    String? groupId,
    required String filePath,
    required String fileUrl,
    required int durationSeconds,
    List<double>? waveform,
    bool isAnonymous = false,
  }) {
    AppLogger.chat(
      'Sending voice message',
      data: {
        'conversation_id': conversationId,
        'duration_seconds': durationSeconds,
      },
    );
    return guard(
      () async {
        final row = await client
            .from('chat_messages')
            .insert({
              'conversation_id': conversationId,
              'group_id': groupId,
              'sender_id': _userId,
              'message_type': 'voice',
              'attachment_url': fileUrl,
              'attachment_path': filePath,
              'attachment_mime_type': 'audio/mp4',
              'audio_duration_seconds': durationSeconds,
              'waveform': waveform ?? _fallbackWaveform,
              'is_anonymous': isAnonymous,
              'metadata': {'sensitive': true},
            })
            .select()
            .single();
        AppLogger.chat(
          'Message sent success',
          data: {'conversation_id': conversationId, 'type': 'voice'},
        );
        return ChatMessage.fromMap(mapRow(row));
      },
      source: 'ChatRepository.sendVoiceMessage',
      table: 'chat_messages',
      data: {'conversation_id': conversationId},
    );
  }

  Future<void> editMessage(String messageId, String newBody) {
    return guard(() async {
      await client
          .from('chat_messages')
          .update({'body': newBody.trim(), 'status': 'edited'})
          .eq('id', messageId);
    });
  }

  Future<void> softDeleteMessage(String messageId) {
    return guard(() async {
      await client
          .from('chat_messages')
          .update({'body': null, 'status': 'deleted'})
          .eq('id', messageId);
    });
  }

  Future<void> hideMessageAsModerator(String messageId) {
    return guard(() async {
      await client
          .from('chat_messages')
          .update({'status': 'hidden'})
          .eq('id', messageId);
    });
  }

  Future<void> markMessageRead(String messageId, String conversationId) {
    final userId = _userId;
    if (userId == null) return Future.value();

    AppLogger.chat(
      'Message read receipt sent',
      data: {'conversation_id': conversationId, 'message_id': messageId},
    );
    return guard(
      () async {
        await client.from('chat_message_reads').upsert({
          'message_id': messageId,
          'conversation_id': conversationId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        }, onConflict: 'message_id,user_id');
      },
      source: 'ChatRepository.markMessageRead',
      table: 'chat_message_reads',
    );
  }

  Future<void> markConversationRead(String conversationId) {
    AppLogger.chat(
      'Conversation read receipt sent',
      data: {'conversation_id': conversationId},
    );
    return guard(
      () async {
        await client.rpc(
          'mark_chat_conversation_read',
          params: {'conversation_uuid': conversationId},
        );
      },
      source: 'ChatRepository.markConversationRead',
      table: 'chat_message_reads',
    );
  }

  Future<void> reactToMessage(String messageId, String reaction) {
    final userId = _userId;
    if (userId == null) return Future.value();

    AppLogger.chat(
      'Message reaction added',
      data: {'message_id': messageId, 'reaction': reaction},
    );
    return guard(
      () async {
        await client.from('chat_message_reactions').upsert({
          'message_id': messageId,
          'user_id': userId,
          'reaction': reaction,
        }, onConflict: 'message_id,user_id,reaction');
      },
      source: 'ChatRepository.reactToMessage',
      table: 'chat_message_reactions',
    );
  }

  Future<void> removeReaction(String messageId, String reaction) {
    final userId = _userId;
    if (userId == null) return Future.value();

    AppLogger.chat(
      'Message reaction removed',
      data: {'message_id': messageId, 'reaction': reaction},
    );
    return guard(
      () async {
        await client
            .from('chat_message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId)
            .eq('reaction', reaction);
      },
      source: 'ChatRepository.removeReaction',
      table: 'chat_message_reactions',
    );
  }

  Future<void> reportMessage(String messageId, String reason) {
    final userId = _userId;
    if (userId == null) return Future.value();

    AppLogger.chat(
      'Message report submitted',
      data: {'message_id': messageId, 'reason': reason},
    );
    return guard(
      () async {
        await client.from('reports').insert({
          'reporter_id': userId,
          'target_type': 'chat_message',
          'target_id': messageId,
          'reason': reason,
        });
      },
      source: 'ChatRepository.reportMessage',
      table: 'reports',
    );
  }

  Future<void> blockUser(String userId) {
    final currentUserId = _userId;
    if (currentUserId == null || userId == currentUserId) {
      return Future.value();
    }

    return guard(() async {
      await client.from('user_blocks').upsert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      }, onConflict: 'blocker_id,blocked_id');
    });
  }

  Future<void> muteConversation(String conversationId) {
    return _updateParticipantStatus(conversationId, 'muted');
  }

  Future<void> leaveConversation(String conversationId) {
    return _updateParticipantStatus(conversationId, 'left');
  }

  Future<void> sendTypingBroadcast(String conversationId, bool isTyping) async {
    if (!SupabaseService.isInitialized || _userId == null) return;
    AppLogger.chat(
      'Typing event sent',
      data: {'conversation_id': conversationId, 'is_typing': isTyping},
    );
    await client
        .channel('chat:$conversationId')
        .sendBroadcastMessage(
          event: 'typing',
          payload: {
            'user_id': _userId,
            'is_typing': isTyping,
            'sent_at': DateTime.now().toIso8601String(),
          },
        );
  }

  Future<ChatConversation> _conversation(String conversationId) {
    return guard(
      () async {
        final row = await client
            .from('chat_conversations')
            .select()
            .eq('id', conversationId)
            .single();
        return ChatConversation.fromMap(mapRow(row));
      },
      source: 'ChatRepository._conversation',
      table: 'chat_conversations',
    );
  }

  Future<String> _rpcString(String function, JsonMap params) {
    return guard(
      () async {
        final value = await client.rpc(function, params: params);
        return value.toString();
      },
      source: 'ChatRepository._rpcString',
      table: function,
      data: params,
    );
  }

  Future<void> _updateParticipantStatus(String conversationId, String status) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(
      () async {
        await client
            .from('chat_participants')
            .update({'status': status})
            .eq('conversation_id', conversationId)
            .eq('user_id', userId);
      },
      source: 'ChatRepository._updateParticipantStatus',
      table: 'chat_participants',
      data: {'conversation_id': conversationId, 'status': status},
    );
  }

  static const _fallbackWaveform = [
    .22,
    .48,
    .35,
    .76,
    .42,
    .62,
    .31,
    .55,
    .28,
    .7,
    .36,
    .5,
  ];
}
