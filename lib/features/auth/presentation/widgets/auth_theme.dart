import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// Gramik Darkstore auth + brand typography.
class AuthTheme {
  AuthTheme._();

  static Color get primary => AppColors.primary;
  static Color get primaryDark => AppColors.primaryDark;
  static Color get screenBg => AppColors.background;
  static Color get ink => AppColors.textPrimary;
  static Color get muted => AppColors.textMuted;
  static Color get mutedLight => AppColors.textSecondary;
  static Color get line => AppColors.border;
  static Color get lineSoft => AppColors.borderInput;
  static Color get inputBg => AppColors.fieldBg;
  static Color get cardBorder => AppColors.border;

  static TextStyle title([Color? c]) => GoogleFonts.inter(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: c ?? ink,
      );

  static TextStyle otpTitle([Color? c]) => GoogleFonts.inter(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: c ?? (AppColors.isDark ? Colors.white : AppColors.textPrimary),
      );

  static TextStyle brandName([Color? c]) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: c ?? Colors.white.withValues(alpha: 0.9),
      );

  static TextStyle brandNameBold([Color? c]) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: c ??
            (AppColors.isDark
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.95)),
      );

  static TextStyle body([Color? c]) =>
      GoogleFonts.inter(fontSize: 15, height: 1.5, color: c ?? muted);

  static TextStyle bodySm([Color? c]) =>
      GoogleFonts.inter(fontSize: 13, color: c ?? mutedLight);

  static TextStyle label([Color? c]) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: c ?? ink,
      );

  static TextStyle caption([Color? c]) =>
      GoogleFonts.inter(fontSize: 12, color: c ?? mutedLight);

  static TextStyle button([Color? c]) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: c ?? Colors.white,
      );
}
