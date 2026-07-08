import 'package:flutter/foundation.dart';

import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    required this.conversationId,
    this.groupId,
    this.repository = const ChatRepository(),
  });

  final String conversationId;
  final String? groupId;
  final ChatRepository repository;

  ChatMessage? replyingTo;
  bool isAnonymous = false;
  bool isSending = false;
  String? error;

  void setReply(ChatMessage? message) {
    replyingTo = message;
    notifyListeners();
  }

  void setAnonymous(bool value) {
    isAnonymous = value;
    notifyListeners();
  }

  Future<void> sendText(String body) async {
    if (body.trim().isEmpty) return;
    isSending = true;
    error = null;
    notifyListeners();
    try {
      await repository.sendTextMessage(
        conversationId: conversationId,
        groupId: groupId,
        body: body,
        isAnonymous: isAnonymous,
        replyToMessageId: replyingTo?.id,
      );
      replyingTo = null;
    } catch (exception) {
      error = exception.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
