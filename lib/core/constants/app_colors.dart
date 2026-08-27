import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — Gramik Darkstore theme
  static const Color primary = Color(0xFFEC5800);
  static const Color primaryDark = Color(0xFFD04E00);
  static const Color primaryMid = Color(0xFFEC5800);
  static const Color primaryBright = Color(0xFFF06A1A);
  static const Color primarySoft = Color(0xFFFFE4D2);
  static const Color primarySoftBorder = Color(0xFFF5C4A8);

  // Surfaces
  static const Color background = Color(0xFFF0F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color fieldBg = Color(0xFFF5F6F8);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF999999);

  // Lines
  static const Color border = Color(0xFFEAEAEA);
  static const Color borderInput = Color(0xFFECECEC);

  // Status
  static const Color inStock = Color(0xFF167F46);
  static const Color outStock = Color(0xFFD64545);
  static const Color warning = Color(0xFFD98324);
  static const Color auditRecentBg = Color(0xFFFFF4ED);
  static const Color auditRecentBorder = Color(0xFFF5C4A8);

  static const Color footerActiveBg = Color(0xFFFFE4D2);
  static const Color errorBg = Color(0xFFFDF0F0);
  static const Color errorBorder = Color(0xFFF6CFCF);
  static const Color errorText = Color(0xFFC33636);
  static const Color successBg = Color(0xFFEFFAF2);
  static const Color successBorder = Color(0xFFBFE6CD);
  static const Color successText = Color(0xFF167F46);
  static const Color btnSecondaryBg = Color(0xFFFFF4ED);
  static const Color btnSecondaryBorder = Color(0xFFF5C4A8);

  // Elevation
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
