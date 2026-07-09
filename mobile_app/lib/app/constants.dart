import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const green = Color(0xFF1F5B3A);
  static const deepGreen = Color(0xFF123524);
  static const softGreen = Color(0xFFE8F3EC);
  static const mintGreen = Color(0xFFDDEFE5);

  static const background = Color(0xFFFAF8F2);
  static const card = Color(0xFFFFFFFF);
  static const softCream = Color(0xFFF4EFE6);
  static const line = Color(0xFFE7E0D5);

  static const navy = Color(0xFF172033);
  static const secondaryText = Color(0xFF667085);
  static const mutedText = Color(0xFF8A948C);

  static const gold = Color(0xFFC89B3C);
  static const paleGold = Color(0xFFF3E8C8);

  static const support = Color(0xFFB86B4B);
  static const supportBg = Color(0xFFF6E8E1);
  static const success = Color(0xFF2E7D4F);

  static const inkSoft = Color(0xFFEEF0F3);
  static const darkSurface = Color(0xFF102419);
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 22.0;
}

class AppBorders {
  const AppBorders._();

  static BorderSide get subtle => const BorderSide(color: AppColors.line);
  static BorderSide get green => const BorderSide(color: AppColors.green);
  static BorderSide get premium => const BorderSide(color: AppColors.gold);
}

class AppTextStyles {
  const AppTextStyles._();

  static const screenTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.12,
  );

  static const sectionTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const cardTitle = TextStyle(
    color: AppColors.navy,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    color: AppColors.secondaryText,
    fontSize: 14,
    height: 1.45,
  );

  static const caption = TextStyle(
    color: AppColors.mutedText,
    fontSize: 12,
    height: 1.35,
  );
}
