import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppThemeTextStyles {
  const AppThemeTextStyles._();

  static TextStyle get largeTitle => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.12,
  );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textPrimary,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    color: AppThemeColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
}
