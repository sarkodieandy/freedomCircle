import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/screen_shell.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      (
        'Prayer',
        'Ama prayed for your request',
        '2 min ago',
        true,
        Icons.volunteer_activism_rounded,
      ),
      (
        'Group',
        'Men of Discipline has a new weekly prompt',
        '18 min ago',
        true,
        Icons.groups_rounded,
      ),
      (
        'Milestone',
        'You are one day away from a 14-day badge',
        'Today',
        false,
        Icons.workspace_premium_rounded,
      ),
      (
        'Helper',
        'Pastor Ama confirmed tomorrow at 6:30 PM',
        'Yesterday',
        false,
        Icons.verified_user_rounded,
      ),
      (
        'Payment',
        'Premium renewal reminder for next week',
        'Yesterday',
        false,
        Icons.receipt_long_rounded,
      ),
    ];

    return ScreenShell(
      title: 'Notifications',
      subtitle:
          'Prayer, group activity, helper messages, and milestone alerts.',
      withBack: true,
      children: [
        for (final item in notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              color: item.$4 ? AppColors.softGreen : AppColors.card,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: item.$4
                        ? AppColors.green
                        : AppColors.green.withValues(alpha: .12),
                    child: Icon(
                      item.$5,
                      color: item.$4 ? Colors.white : AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(item.$3, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        const EmptyStateCard(
          icon: Icons.notifications_none_rounded,
          title: 'No older notifications',
          body: 'You are caught up. Important updates will appear here.',
          action: 'Refresh',
        ),
      ],
    );
  }
}
