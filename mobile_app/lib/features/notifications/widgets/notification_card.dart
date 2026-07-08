import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/notification_item.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(notification.type);
    return Dismissible(
      key: ValueKey(notification.id),
      background: _SwipeBackground(
        color: AppColors.green,
        icon: Icons.done_all_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: AppColors.support,
        icon: Icons.delete_outline_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMarkRead();
          return false;
        }
        onDelete();
        return true;
      },
      child: AppCard(
        onTap: onTap,
        color: notification.isUnread ? AppColors.softGreen : AppColors.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: notification.isUnread
                  ? accent
                  : accent.withValues(alpha: .12),
              child: Icon(
                _iconFor(notification.type),
                color: notification.isUnread ? Colors.white : accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.support,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (notification.body?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') onMarkRead();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'read', child: Text('Mark read')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String type) {
    if (type.contains('group')) return Icons.groups_rounded;
    if (type.contains('prayer')) return Icons.volunteer_activism_rounded;
    if (type.contains('community')) return Icons.forum_rounded;
    if (type.contains('helper') || type.contains('booking')) {
      return Icons.verified_user_rounded;
    }
    if (type.contains('payment') || type.contains('subscription')) {
      return Icons.receipt_long_rounded;
    }
    if (type.contains('quiet') || type.contains('bible')) {
      return Icons.auto_stories_rounded;
    }
    if (type.contains('fasting')) return Icons.restaurant_rounded;
    if (type.contains('milestone')) return Icons.workspace_premium_rounded;
    if (type.contains('safety')) return Icons.shield_rounded;
    return Icons.notifications_rounded;
  }

  static Color _accentFor(String type) {
    if (type.contains('payment') || type.contains('subscription')) {
      return AppColors.gold;
    }
    if (type.contains('helper') || type.contains('booking')) {
      return AppColors.support;
    }
    if (type.contains('safety')) return AppColors.support;
    return AppColors.green;
  }

  static String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
