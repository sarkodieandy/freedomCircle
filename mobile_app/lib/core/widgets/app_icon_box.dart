import 'package:flutter/material.dart';

import '../../app/constants.dart';

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,
    required this.icon,
    this.size = 42,
    this.iconSize = 22,
    this.color = AppColors.green,
    this.background,
    this.withBorder = true,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final Color? background;
  final bool withBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: withBorder ? Border.all(color: AppColors.line) : null,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
