import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';

class PrayerRequestCard extends StatelessWidget {
  const PrayerRequestCard({
    super.key,
    required this.title,
    required this.body,
    required this.prayed,
    required this.isAnonymous,
    this.answered = false,
  });

  final String title;
  final String body;
  final int prayed;
  final bool isAnonymous;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  answered
                      ? Icons.check_circle_rounded
                      : Icons.volunteer_activism_rounded,
                  color: answered ? AppColors.success : AppColors.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isAnonymous)
                  const StatusBadge(
                    label: 'Anonymous',
                    color: AppColors.navy,
                    icon: Icons.visibility_off_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionPill(
                  icon: Icons.favorite_rounded,
                  label: 'I prayed $prayed',
                ),
                if (!answered)
                  const ActionPill(
                    icon: Icons.task_alt_rounded,
                    label: 'Mark answered',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
