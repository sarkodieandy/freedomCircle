import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Padding(
        key: ValueKey(label),
        padding: const EdgeInsets.only(left: 6, bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            const _Dot(delay: 0),
            const _Dot(delay: 110),
            const _Dot(delay: 220),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .35, end: 1),
      duration: Duration(milliseconds: 520 + delay),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, -2 * value), child: child),
      ),
      child: Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.only(right: 3),
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
