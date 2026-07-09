import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/supabase/supabase_service.dart';

class ChatRealtimeService {
  ChatRealtimeService(this.conversationId);

  final String conversationId;
  RealtimeChannel? _channel;

  StreamController<Map<String, dynamic>>? _typingController;

  Stream<Map<String, dynamic>> typingEvents() {
    _typingController ??= StreamController<Map<String, dynamic>>.broadcast();
    if (!SupabaseService.isInitialized) return const Stream.empty();

    AppLogger.info(
      'Channel subscribed',
      tag: 'REALTIME',
      data: {'channel': 'chat:$conversationId', 'feature': 'typing indicator'},
    );

    _channel ??= SupabaseService.client.channel('chat:$conversationId')
      ..onBroadcast(
        event: 'typing',
        callback: (payload) {
          AppLogger.info(
            'Realtime event received',
            tag: 'REALTIME',
            data: {
              'channel': 'chat:$conversationId',
              'feature': 'typing indicator',
            },
          );
          _typingController?.add(payload);
        },
      )
      ..subscribe();

    AppLogger.info(
      'Channel subscription success',
      tag: 'REALTIME',
      data: {'channel': 'chat:$conversationId'},
    );
    return _typingController!.stream;
  }

  Future<void> sendTyping({
    required String userId,
    required bool isTyping,
  }) async {
    if (!SupabaseService.isInitialized) return;
    AppLogger.chat(
      'Typing event sent',
      data: {'conversation_id': conversationId, 'is_typing': isTyping},
    );
    _channel ??= SupabaseService.client.channel('chat:$conversationId')
      ..subscribe();
    await _channel!.sendBroadcastMessage(
      event: 'typing',
      payload: {
        'user_id': userId,
        'is_typing': isTyping,
        'sent_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> dispose() async {
    await _typingController?.close();
    if (_channel != null && SupabaseService.isInitialized) {
      await SupabaseService.client.removeChannel(_channel!);
      AppLogger.info(
        'Channel disposed/unsubscribed',
        tag: 'REALTIME',
        data: {'channel': 'chat:$conversationId'},
      );
    }
  }
}
