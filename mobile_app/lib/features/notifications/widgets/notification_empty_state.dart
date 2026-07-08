import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';

class NotificationEmptyState extends StatelessWidget {
  const NotificationEmptyState({
    super.key,
    this.title = 'No notifications yet',
    this.body = 'Prayer, group, helper, and account updates will appear here.',
    this.onRefresh,
  });

  final String title;
  final String body;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.green,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
