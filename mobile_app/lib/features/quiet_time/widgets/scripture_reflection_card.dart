import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';

class ScriptureReflectionCard extends StatelessWidget {
  const ScriptureReflectionCard({
    super.key,
    required this.verse,
    required this.reference,
  });

  final String verse;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.softGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.green),
          const SizedBox(height: 10),
          Text(
            '"$verse"',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Text(
            reference,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.green),
          ),
        ],
      ),
    );
  }
}
