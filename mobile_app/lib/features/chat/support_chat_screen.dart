import 'package:flutter/material.dart';

import '../../data/models/chat_conversation.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_screen.dart';
import 'widgets/chat_error_state.dart';
import 'widgets/chat_loading_state.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({
    super.key,
    required this.supportRequestId,
    this.title = 'Support chat',
  });

  final String supportRequestId;
  final String title;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final ChatRepository _repository = const ChatRepository();
  Future<ChatConversation>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.supportRequestId.isNotEmpty) {
      _future = _repository.getOrCreateSupportConversation(widget.supportRequestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.supportRequestId.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ChatErrorState(
              message: 'This support request needs a backend ID before chat can open.',
            ),
          ),
        ),
      );
    }

    return FutureBuilder<ChatConversation>(
      future: _future!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: SafeArea(child: ChatLoadingState()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ChatErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {
                    _future = _repository.getOrCreateSupportConversation(
                      widget.supportRequestId,
                    );
                  }),
                ),
              ),
            ),
          );
        }
        return ChatScreen(
          conversation: snapshot.data!,
          title: widget.title,
          allowAnonymous: false,
        );
      },
    );
  }
}
