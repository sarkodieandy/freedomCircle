import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeShadows {
  const AppThemeShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppThemeColors.textPrimary.withValues(alpha: .04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppThemeColors.textPrimary.withValues(alpha: .02),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
