import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppThemeBorders {
  const AppThemeBorders._();

  static const subtle = BorderSide(color: AppThemeColors.divider);
  static const focused = BorderSide(color: AppThemeColors.primary, width: 1.4);
  static const premium = BorderSide(color: AppThemeColors.premium, width: 1.2);
}
