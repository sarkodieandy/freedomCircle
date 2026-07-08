import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatRepository _repository = const ChatRepository();
  late Future<List<ChatConversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getUserConversations();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repository.getUserConversations());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Chats',
      subtitle: 'Group circles, prayer threads, helper messages, and support.',
      withBack: true,
      trailing: IconButton(
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Refresh chats',
      ),
      children: [
        FutureBuilder<List<ChatConversation>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorRetryCard(
                title: 'Could not load chats',
                body: snapshot.error.toString(),
                onRetry: () => setState(
                  () => _future = _repository.getUserConversations(),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingStateCard();
            }

            final conversations = snapshot.data ?? const <ChatConversation>[];
            if (conversations.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.forum_outlined,
                title: 'No active chats',
                body:
                    'Join a circle, request support, or message a verified helper to start a private conversation.',
                action: 'Find support',
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: conversations.length,
                itemBuilder: (context, index) => _ConversationTile(
                  conversation: conversations[index],
                  onTap: () => pushScreen(
                    context,
                    ChatScreen(
                      conversation: conversations[index],
                      title: _title(conversations[index]),
                      groupId: conversations[index].groupId,
                      allowAnonymous: conversations[index].isGroup,
                      showModeratorActions: conversations[index].isGroup,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _title(ChatConversation conversation) {
    if (conversation.title?.isNotEmpty == true) return conversation.title!;
    return switch (conversation.conversationType) {
      'prayer_group' => 'Prayer group chat',
      'helper_private' => 'Helper chat',
      'support_request' => 'Support chat',
      'admin_support' => 'Admin support',
      _ => 'Group chat',
    };
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (conversation.conversationType) {
      'support_request' || 'helper_private' => AppColors.support,
      'prayer_group' => AppColors.gold,
      _ => AppColors.green,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_icon(conversation.conversationType), color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    return switch (type) {
      'prayer_group' => Icons.volunteer_activism_rounded,
      'helper_private' => Icons.health_and_safety_rounded,
      'support_request' => Icons.support_agent_rounded,
      'admin_support' => Icons.admin_panel_settings_rounded,
      _ => Icons.groups_rounded,
    };
  }

  String get _title {
    if (conversation.title?.isNotEmpty == true) return conversation.title!;
    return switch (conversation.conversationType) {
      'prayer_group' => 'Prayer group chat',
      'helper_private' => 'Helper private chat',
      'support_request' => 'Support request chat',
      'admin_support' => 'Admin support',
      _ => 'Group chat',
    };
  }

  String get _subtitle {
    final updated = conversation.updatedAt ?? conversation.createdAt;
    final hour = updated.hour.toString().padLeft(2, '0');
    final minute = updated.minute.toString().padLeft(2, '0');
    return '${conversation.status} - last active $hour:$minute';
  }
}
