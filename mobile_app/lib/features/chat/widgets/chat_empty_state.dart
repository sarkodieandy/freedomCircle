import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    this.title = 'No messages yet',
    this.body = 'Start with a short, honest message. This space is built for privacy and grace.',
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: AppColors.green,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
