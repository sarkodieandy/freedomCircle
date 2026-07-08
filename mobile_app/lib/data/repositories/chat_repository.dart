import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/model_helpers.dart';
import '../supabase/supabase_service.dart';
import 'supabase_repository.dart';

class ChatRepository extends SupabaseRepository {
  const ChatRepository({super.supabaseClient});

  String? get _userId => SupabaseService.currentUser?.id;

  Future<List<ChatConversation>> getUserConversations() {
    if (!SupabaseService.isInitialized || _userId == null) {
      return Future.value(const []);
    }

    return guard(() async {
      final rows = await client
          .from('chat_conversations')
          .select()
          .order('updated_at', ascending: false);
      return mapRows(rows, ChatConversation.fromMap);
    });
  }

  Future<ChatConversation> getOrCreateGroupConversation(String groupId) async {
    final id = await _rpcString('get_or_create_group_chat', {
      'group_uuid': groupId,
      'conversation_kind': 'group',
    });
    return _conversation(id);
  }

  Future<ChatConversation> getOrCreatePrayerGroupConversation(String groupId) async {
    final id = await _rpcString('get_or_create_group_chat', {
      'group_uuid': groupId,
      'conversation_kind': 'prayer_group',
    });
    return _conversation(id);
  }

  Future<ChatConversation> getOrCreatePrivateConversation(String otherUserId) async {
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

    return guard(() async {
      final rows = await client
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(50);
      return mapRows(rows, ChatMessage.fromMap).reversed.toList();
    });
  }

  Stream<List<ChatMessage>> listenToMessages(String conversationId) {
    if (!SupabaseService.isInitialized) return Stream.value(const []);

    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => mapRows(rows, ChatMessage.fromMap));
  }

  Future<ChatMessage> sendTextMessage({
    required String conversationId,
    String? groupId,
    required String body,
    bool isAnonymous = false,
    String? replyToMessageId,
  }) {
    return guard(() async {
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
      return ChatMessage.fromMap(mapRow(row));
    });
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
    return guard(() async {
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
      return ChatMessage.fromMap(mapRow(row));
    });
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
      await client.from('chat_messages').update({'status': 'hidden'}).eq(
            'id',
            messageId,
          );
    });
  }

  Future<void> markMessageRead(String messageId, String conversationId) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(() async {
      await client.from('chat_message_reads').upsert({
        'message_id': messageId,
        'conversation_id': conversationId,
        'user_id': userId,
        'read_at': DateTime.now().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    });
  }

  Future<void> markConversationRead(String conversationId) {
    return guard(() async {
      await client.rpc(
        'mark_chat_conversation_read',
        params: {'conversation_uuid': conversationId},
      );
    });
  }

  Future<void> reactToMessage(String messageId, String reaction) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(() async {
      await client.from('chat_message_reactions').upsert({
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
      }, onConflict: 'message_id,user_id,reaction');
    });
  }

  Future<void> removeReaction(String messageId, String reaction) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(() async {
      await client
          .from('chat_message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('reaction', reaction);
    });
  }

  Future<void> reportMessage(String messageId, String reason) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(() async {
      await client.from('reports').insert({
        'reporter_id': userId,
        'target_type': 'chat_message',
        'target_id': messageId,
        'reason': reason,
      });
    });
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
    await client.channel('chat:$conversationId').sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': _userId,
        'is_typing': isTyping,
        'sent_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<ChatConversation> _conversation(String conversationId) {
    return guard(() async {
      final row = await client
          .from('chat_conversations')
          .select()
          .eq('id', conversationId)
          .single();
      return ChatConversation.fromMap(mapRow(row));
    });
  }

  Future<String> _rpcString(String function, JsonMap params) {
    return guard(() async {
      final value = await client.rpc(function, params: params);
      return value.toString();
    });
  }

  Future<void> _updateParticipantStatus(String conversationId, String status) {
    final userId = _userId;
    if (userId == null) return Future.value();

    return guard(() async {
      await client
          .from('chat_participants')
          .update({'status': status})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    });
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
