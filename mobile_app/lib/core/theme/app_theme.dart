import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_borders.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class PremiumAppTheme {
  const PremiumAppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppThemeColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppThemeColors.primary,
        onPrimary: Colors.white,
        secondary: AppThemeColors.premium,
        onSecondary: AppThemeColors.textPrimary,
        error: AppThemeColors.support,
        onError: Colors.white,
        surface: AppThemeColors.card,
        onSurface: AppThemeColors.textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        displaySmall: AppThemeTextStyles.largeTitle,
        headlineMedium: AppThemeTextStyles.screenTitle,
        titleLarge: AppThemeTextStyles.sectionTitle,
        titleMedium: AppThemeTextStyles.cardTitle,
        bodyLarge: AppThemeTextStyles.body,
        bodyMedium: AppThemeTextStyles.body,
        bodySmall: AppThemeTextStyles.caption,
        labelLarge: AppThemeTextStyles.button.copyWith(
          color: AppThemeColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppThemeColors.background,
        foregroundColor: AppThemeColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppThemeTextStyles.body.copyWith(
          color: AppThemeColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.md),
          borderSide: AppThemeBorders.subtle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.md),
          borderSide: AppThemeBorders.subtle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeRadius.md),
          borderSide: AppThemeBorders.focused,
        ),
      ),
      dividerColor: AppThemeColors.divider,
    );
  }
}
