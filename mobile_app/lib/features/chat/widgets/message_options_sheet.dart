import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../data/models/chat_message.dart';
import 'message_reaction_bar.dart';

Future<void> showMessageOptionsSheet({
  required BuildContext context,
  required ChatMessage message,
  required bool isMine,
  required bool canModerate,
  required VoidCallback onReply,
  required VoidCallback onReport,
  required ValueChanged<String> onReaction,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
  VoidCallback? onHide,
  VoidCallback? onBlockUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            MessageReactionBar(
              messageId: message.id,
              compact: false,
              onReaction: (reaction) {
                Navigator.pop(context);
                onReaction(reaction);
              },
            ),
            const Divider(height: 22),
            _ActionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (isMine && onEdit != null)
              _ActionTile(
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
            if (isMine && onDelete != null)
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                destructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            if (canModerate && onHide != null)
              _ActionTile(
                icon: Icons.visibility_off_rounded,
                label: 'Hide as moderator',
                destructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onHide();
                },
              ),
            _ActionTile(
              icon: Icons.flag_outlined,
              label: 'Report',
              destructive: true,
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
            if (!isMine && onBlockUser != null)
              _ActionTile(
                icon: Icons.block_rounded,
                label: 'Block sender',
                destructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onBlockUser();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.support : AppColors.green;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: onTap,
    );
  }
}
