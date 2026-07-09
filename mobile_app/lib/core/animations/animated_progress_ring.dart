import 'package:flutter/material.dart';

import '../widgets/progress_ring.dart';

class AnimatedProgressRing extends StatelessWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
    required this.label,
  });

  final double progress;
  final double size;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) =>
          ProgressRing(progress: value, size: size, color: color, label: label),
    );
  }
}
