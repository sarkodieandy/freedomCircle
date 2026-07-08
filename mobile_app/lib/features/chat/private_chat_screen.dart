import 'package:flutter/material.dart';

import '../../data/models/chat_conversation.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_screen.dart';
import 'widgets/chat_error_state.dart';
import 'widgets/chat_loading_state.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({
    super.key,
    required this.otherUserId,
    this.title = 'Helper chat',
  });

  final String otherUserId;
  final String title;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final ChatRepository _repository = const ChatRepository();
  Future<ChatConversation>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.otherUserId.isNotEmpty) {
      _future = _repository.getOrCreatePrivateConversation(widget.otherUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.otherUserId.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ChatErrorState(
              message:
                  'This helper needs a linked user ID before chat can open.',
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
                    _future = _repository.getOrCreatePrivateConversation(
                      widget.otherUserId,
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
