import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/supabase_service.dart';

class ChatRealtimeService {
  ChatRealtimeService(this.conversationId);

  final String conversationId;
  RealtimeChannel? _channel;

  StreamController<Map<String, dynamic>>? _typingController;

  Stream<Map<String, dynamic>> typingEvents() {
    _typingController ??= StreamController<Map<String, dynamic>>.broadcast();
    if (!SupabaseService.isInitialized) return const Stream.empty();
    _channel ??= SupabaseService.client.channel('chat:$conversationId')
      ..onBroadcast(
        event: 'typing',
        callback: (payload) => _typingController?.add(payload),
      )
      ..subscribe();
    return _typingController!.stream;
  }

  Future<void> sendTyping({
    required String userId,
    required bool isTyping,
  }) async {
    if (!SupabaseService.isInitialized) return;
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
    }
  }
}
