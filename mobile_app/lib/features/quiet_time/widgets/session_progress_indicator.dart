import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class SessionProgressIndicator extends StatelessWidget {
  const SessionProgressIndicator({
    super.key,
    required this.steps,
    required this.current,
  });

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: steps.isEmpty ? 0 : ((current + 1) / steps.length).clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.green,
          backgroundColor: AppColors.softGreen,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < steps.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.softGreen : AppColors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: i == current ? AppColors.green : AppColors.line,
                  ),
                ),
                child: Text(
                  steps[i],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: i == current ? AppColors.green : AppColors.mutedText,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
