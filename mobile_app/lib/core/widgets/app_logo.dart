import 'package:flutter/material.dart';

import '../../app/constants.dart';

class FreedomLogo extends StatelessWidget {
  const FreedomLogo({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: .26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .07
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx, size.height * .24),
      Offset(center.dx, size.height * .56),
      crossPaint,
    );
    canvas.drawLine(
      Offset(size.width * .37, size.height * .38),
      Offset(size.width * .63, size.height * .38),
      crossPaint,
    );

    final path = Path()
      ..moveTo(size.width * .24, size.height * .66)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .8,
        size.width * .76,
        size.height * .62,
      );

    final pathPaint = Paint()
      ..color = AppColors.gold
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .06
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
