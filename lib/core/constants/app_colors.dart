import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2E8B57);
  static const Color primaryDark = Color(0xFF1B5E3A);
  static const Color primaryMid = Color(0xFF34A05F);
  static const Color primaryBright = Color(0xFF4CAF50);
  static const Color primarySoft = Color(0xFFE8F5EC);
  static const Color primarySoftBorder = Color(0xFFC8E6D2);

  // Surfaces
  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFAFDFB);
  static const Color fieldBg = Color(0xFFF3F6F3);

  // Text
  static const Color textPrimary = Color(0xFF16201A);
  static const Color textSecondary = Color(0xFF64756A);
  static const Color textMuted = Color(0xFF93A199);

  // Lines
  static const Color border = Color(0xFFE6EDE8);
  static const Color borderInput = Color(0xFFDDE7E0);

  // Status
  static const Color inStock = Color(0xFF167F46);
  static const Color outStock = Color(0xFFD64545);
  static const Color warning = Color(0xFFD98324);
  static const Color auditRecentBg = Color(0xFFEDF9F1);
  static const Color auditRecentBorder = Color(0xFF9FD9B4);

  static const Color footerActiveBg = Color(0xFFE8F5EC);
  static const Color errorBg = Color(0xFFFDF0F0);
  static const Color errorBorder = Color(0xFFF6CFCF);
  static const Color errorText = Color(0xFFC33636);
  static const Color successBg = Color(0xFFEFFAF2);
  static const Color successBorder = Color(0xFFBFE6CD);
  static const Color successText = Color(0xFF167F46);
  static const Color btnSecondaryBg = Color(0xFFEDF6F0);
  static const Color btnSecondaryBorder = Color(0xFFCBE4D5);

  // Elevation
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0D101B12), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x1A101B12), blurRadius: 28, offset: Offset(0, 12)),
  ];
}
