import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/common_widgets.dart';

class GuidedSessionCard extends StatelessWidget {
  const GuidedSessionCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    required this.isPremium,
    required this.onStart,
    this.locked = false,
  });

  final String title;
  final String description;
  final String duration;
  final String category;
  final bool isPremium;
  final bool locked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconContainer(
                icon: Icons.headphones_rounded,
                size: 50,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text('$duration • $category', style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (isPremium)
                StatusBadge(
                  label: locked ? 'Premium Locked' : 'Premium',
                  color: AppColors.gold,
                  icon: locked
                      ? Icons.lock_rounded
                      : Icons.workspace_premium_rounded,
                )
              else
                const StatusBadge(
                  label: 'Free',
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: AppTextStyles.body),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                locked ? Icons.cloud_off_rounded : Icons.offline_pin_rounded,
                color: AppColors.mutedText,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text('Offline placeholder', style: AppTextStyles.caption),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: locked ? AppColors.gold : AppColors.green,
                ),
                onPressed: onStart,
                icon: Icon(
                  locked ? Icons.lock_open_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(locked ? 'Unlock' : 'Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
