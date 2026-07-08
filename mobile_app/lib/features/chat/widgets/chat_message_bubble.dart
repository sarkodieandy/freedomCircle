import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../data/models/chat_message.dart';
import 'message_reaction_bar.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onLongPress,
    this.onReply,
    this.onReaction,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback onLongPress;
  final VoidCallback? onReply;
  final ValueChanged<String>? onReaction;

  @override
  Widget build(BuildContext context) {
    final hidden = message.isDeleted;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isMine ? AppColors.green : AppColors.card,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: Radius.circular(isMine ? 4 : 20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
              ),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    message.isAnonymous ? 'Anonymous member' : 'Member',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isMine ? Colors.white : AppColors.green,
                    ),
                  ),
                Text(
                  hidden ? 'Message removed' : (message.body ?? ''),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isMine ? Colors.white : AppColors.navy,
                    fontStyle: hidden ? FontStyle.italic : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _time(message.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isMine
                            ? Colors.white.withValues(alpha: .72)
                            : AppColors.mutedText,
                      ),
                    ),
                    if (message.status == 'edited') ...[
                      const SizedBox(width: 6),
                      Text(
                        'edited',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isMine
                              ? Colors.white.withValues(alpha: .72)
                              : AppColors.mutedText,
                        ),
                      ),
                    ],
                    if (onReply != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onReply,
                        icon: Icon(
                          Icons.reply_rounded,
                          color: isMine ? Colors.white : AppColors.green,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                if (!hidden)
                  MessageReactionBar(
                    messageId: message.id,
                    onReaction: onReaction,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
