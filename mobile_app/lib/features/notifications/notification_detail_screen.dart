import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_shell.dart';
import '../../data/models/notification_item.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Notification',
      subtitle: notification.title,
      withBack: true,
      children: [
        AppCard(
          color: notification.isUnread ? AppColors.softGreen : AppColors.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.green,
                child: Icon(_iconFor(notification.type), color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (notification.body?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(
                  notification.body!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 18),
              Text(
                notification.createdAt.toLocal().toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
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
    if (type.contains('safety')) return Icons.shield_rounded;
    return Icons.notifications_rounded;
  }
}
