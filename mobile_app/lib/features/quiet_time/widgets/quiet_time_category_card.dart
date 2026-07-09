import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/common_widgets.dart';

class QuietTimeCategoryCard extends StatelessWidget {
  const QuietTimeCategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconContainer(icon: icon),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
