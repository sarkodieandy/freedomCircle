import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../core/widgets/app_card.dart';

class ReflectionPromptCard extends StatelessWidget {
  const ReflectionPromptCard({
    super.key,
    required this.prompt,
    required this.controller,
    this.hint,
  });

  final String prompt;
  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint ?? 'Write privately...',
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}
