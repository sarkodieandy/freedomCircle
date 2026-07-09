import 'package:flutter/material.dart';

import '../../app/constants.dart';

class AppPremiumIcon extends StatelessWidget {
  const AppPremiumIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = AppColors.green,
    this.withContainer = true,
  });

  final IconData icon;
  final double size;
  final Color color;
  final bool withContainer;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: size, color: color);
    if (!withContainer) return iconWidget;

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(child: iconWidget),
    );
  }
}
