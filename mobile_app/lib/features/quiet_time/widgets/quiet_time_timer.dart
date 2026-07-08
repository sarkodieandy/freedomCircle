import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class QuietTimeTimer extends StatelessWidget {
  const QuietTimeTimer({
    super.key,
    required this.durations,
    required this.selected,
    required this.onSelected,
    this.onCustom,
  });

  final List<int> durations;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback? onCustom;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final minutes in durations)
          ChoiceChip(
            label: Text('$minutes min'),
            selected: selected == minutes,
            onSelected: (_) => onSelected(minutes),
          ),
        ActionChip(
          avatar: const Icon(
            Icons.tune_rounded,
            size: 18,
            color: AppColors.green,
          ),
          label: const Text('Custom'),
          onPressed: onCustom,
        ),
      ],
    );
  }
}
