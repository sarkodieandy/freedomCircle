import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class BreathingPrayerCircle extends StatefulWidget {
  const BreathingPrayerCircle({
    super.key,
    required this.progress,
    required this.playing,
    this.label = 'Breathe and pray',
    this.size = 220,
  });

  final double progress;
  final bool playing;
  final String label;
  final double size;

  @override
  State<BreathingPrayerCircle> createState() => _BreathingPrayerCircleState();
}

class _BreathingPrayerCircleState extends State<BreathingPrayerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
      lowerBound: .94,
      upperBound: 1.05,
    );
    if (widget.playing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BreathingPrayerCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
    if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _controller.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _BreathingRingPainter(progress: widget.progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.self_improvement_rounded,
                      color: AppColors.green.withValues(alpha: .92),
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.progress * 100).clamp(0, 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BreathingRingPainter extends CustomPainter {
  const _BreathingRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = AppColors.softGreen;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12
      ..color = AppColors.green;

    canvas.drawCircle(center, radius, base);
    final sweep = (progress.clamp(0, 1)) * (2 * math.pi);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
