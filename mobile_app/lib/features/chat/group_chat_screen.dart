import 'package:flutter/material.dart';

import '../../data/models/chat_conversation.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_screen.dart';
import 'widgets/chat_error_state.dart';
import 'widgets/chat_loading_state.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
    this.title = 'Group chat',
    this.prayerGroup = false,
  });

  final String groupId;
  final String title;
  final bool prayerGroup;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ChatRepository _repository = const ChatRepository();
  Future<ChatConversation>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.groupId.isNotEmpty) {
      _future = widget.prayerGroup
          ? _repository.getOrCreatePrayerGroupConversation(widget.groupId)
          : _repository.getOrCreateGroupConversation(widget.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupId.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ChatErrorState(
              message: 'This group needs a backend ID before chat can open.',
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
                    _future = widget.prayerGroup
                        ? _repository.getOrCreatePrayerGroupConversation(
                            widget.groupId,
                          )
                        : _repository.getOrCreateGroupConversation(
                            widget.groupId,
                          );
                  }),
                ),
              ),
            ),
          );
        }
        return ChatScreen(
          conversation: snapshot.data!,
          groupId: widget.groupId,
          title: widget.title,
          allowAnonymous: true,
          showModeratorActions: true,
        );
      },
    );
  }
}
