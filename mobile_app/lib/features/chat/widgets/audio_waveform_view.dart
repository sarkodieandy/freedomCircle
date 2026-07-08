import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class AudioWaveformView extends StatelessWidget {
  const AudioWaveformView({
    super.key,
    required this.values,
    this.color = AppColors.green,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bars = values.isEmpty ? const [.2, .5, .35, .7, .4, .6] : values;
    return Row(
      children: [
        for (final value in bars)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 10 + (value.clamp(0, 1) * 28),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
