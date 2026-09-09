import 'package:flutter/material.dart';

/// App appearance: Dark (current) or Default (previous light).
enum AppThemeMode {
  dark,
  light;

  bool get isDark => this == AppThemeMode.dark;

  String get storageValue => name;

  static AppThemeMode fromStorage(String? raw) {
    if (raw == 'light') return AppThemeMode.light;
    return AppThemeMode.dark; // default
  }
}

class AppPalette {
  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primaryMid,
    required this.primaryBright,
    required this.primarySoft,
    required this.primarySoftBorder,
    required this.background,
    required this.surface,
    required this.cardBg,
    required this.fieldBg,
    required this.headerBg,
    required this.headerActionBg,
    required this.headerActionIcon,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderInput,
    required this.inStock,
    required this.outStock,
    required this.warning,
    required this.auditRecentBg,
    required this.auditRecentBorder,
    required this.footerActiveBg,
    required this.errorBg,
    required this.errorBorder,
    required this.errorText,
    required this.successBg,
    required this.successBorder,
    required this.successText,
    required this.btnSecondaryBg,
    required this.btnSecondaryBorder,
    required this.statCardBg,
    required this.statCardBorder,
    required this.statValueColor,
    required this.cardShadow,
    required this.floatShadow,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryMid;
  final Color primaryBright;
  final Color primarySoft;
  final Color primarySoftBorder;
  final Color background;
  final Color surface;
  final Color cardBg;
  final Color fieldBg;
  final Color headerBg;
  final Color headerActionBg;
  final Color headerActionIcon;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderInput;
  final Color inStock;
  final Color outStock;
  final Color warning;
  final Color auditRecentBg;
  final Color auditRecentBorder;
  final Color footerActiveBg;
  final Color errorBg;
  final Color errorBorder;
  final Color errorText;
  final Color successBg;
  final Color successBorder;
  final Color successText;
  final Color btnSecondaryBg;
  final Color btnSecondaryBorder;
  final Color statCardBg;
  final Color statCardBorder;
  final Color statValueColor;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> floatShadow;

  /// Current dark mock theme.
  static const dark = AppPalette(
    primary: Color(0xFFEC5800),
    primaryDark: Color(0xFFD04E00),
    primaryMid: Color(0xFFEC5800),
    primaryBright: Color(0xFFF06A1A),
    primarySoft: Color(0xFF3D2418),
    primarySoftBorder: Color(0xFF5C3A28),
    background: Color(0xFF0B0B0F),
    surface: Color(0xFF16161C),
    cardBg: Color(0xFF1C1C24),
    fieldBg: Color(0xFF24242E),
    headerBg: Color(0xFF0B0B0F),
    headerActionBg: Color(0xFF24242E),
    headerActionIcon: Color(0xFFF4F4F5),
    textPrimary: Color(0xFFF4F4F5),
    textSecondary: Color(0xFFA1A1AA),
    textMuted: Color(0xFF71717A),
    border: Color(0xFF2A2A35),
    borderInput: Color(0xFF3A3A48),
    inStock: Color(0xFF22C55E),
    outStock: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    auditRecentBg: Color(0xFF3D2418),
    auditRecentBorder: Color(0xFF5C3A28),
    footerActiveBg: Color(0xFF3D2418),
    errorBg: Color(0xFF2A1515),
    errorBorder: Color(0xFF5C2A2A),
    errorText: Color(0xFFF87171),
    successBg: Color(0xFF12261A),
    successBorder: Color(0xFF1F4D32),
    successText: Color(0xFF4ADE80),
    btnSecondaryBg: Color(0xFF3D2418),
    btnSecondaryBorder: Color(0xFF5C3A28),
    statCardBg: Color(0xFF14141C),
    statCardBorder: Color(0xFF2A2A36),
    statValueColor: Color(0xFFFFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
    floatShadow: [
      BoxShadow(color: Color(0x88000000), blurRadius: 28, offset: Offset(0, 12)),
    ],
  );

  /// Previous light theme (“Default”).
  static const light = AppPalette(
    primary: Color(0xFFEC5800),
    primaryDark: Color(0xFFD04E00),
    primaryMid: Color(0xFFEC5800),
    primaryBright: Color(0xFFF06A1A),
    primarySoft: Color(0xFFFFE4D2),
    primarySoftBorder: Color(0xFFF5C4A8),
    background: Color(0xFFF0F5FA),
    surface: Color(0xFFFFFFFF),
    cardBg: Color(0xFFFFFFFF),
    fieldBg: Color(0xFFF5F6F8),
    headerBg: Color(0xFFEC5800),
    headerActionBg: Color(0x33FFFFFF),
    headerActionIcon: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF999999),
    border: Color(0xFFEAEAEA),
    borderInput: Color(0xFFECECEC),
    inStock: Color(0xFF167F46),
    outStock: Color(0xFFD64545),
    warning: Color(0xFFD98324),
    auditRecentBg: Color(0xFFFFF4ED),
    auditRecentBorder: Color(0xFFF5C4A8),
    footerActiveBg: Color(0xFFFFE4D2),
    errorBg: Color(0xFFFDF0F0),
    errorBorder: Color(0xFFF6CFCF),
    errorText: Color(0xFFC33636),
    successBg: Color(0xFFEFFAF2),
    successBorder: Color(0xFFBFE6CD),
    successText: Color(0xFF167F46),
    btnSecondaryBg: Color(0xFFFFF4ED),
    btnSecondaryBorder: Color(0xFFF5C4A8),
    statCardBg: Color(0xFFFFFFFF),
    statCardBorder: Color(0xFFEAEAEA),
    statValueColor: Color(0xFF1A1A1A),
    cardShadow: [
      BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 3)),
    ],
    floatShadow: [
      BoxShadow(color: Color(0x1A0F172A), blurRadius: 28, offset: Offset(0, 12)),
    ],
  );
}

/// Runtime color tokens — switch via [AppColors.apply].
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.dark;
  static AppThemeMode _mode = AppThemeMode.dark;

  static AppThemeMode get mode => _mode;
  static bool get isDark => _mode.isDark;
  static AppPalette get palette => _p;

  static void apply(AppThemeMode mode) {
    _mode = mode;
    _p = mode.isDark ? AppPalette.dark : AppPalette.light;
  }

  static Color get primary => _p.primary;
  static Color get primaryDark => _p.primaryDark;
  static Color get primaryMid => _p.primaryMid;
  static Color get primaryBright => _p.primaryBright;
  static Color get primarySoft => _p.primarySoft;
  static Color get primarySoftBorder => _p.primarySoftBorder;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get cardBg => _p.cardBg;
  static Color get fieldBg => _p.fieldBg;
  static Color get headerBg => _p.headerBg;
  static Color get headerActionBg => _p.headerActionBg;
  static Color get headerActionIcon => _p.headerActionIcon;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  static Color get border => _p.border;
  static Color get borderInput => _p.borderInput;

  static Color get inStock => _p.inStock;
  static Color get outStock => _p.outStock;
  static Color get warning => _p.warning;
  static Color get auditRecentBg => _p.auditRecentBg;
  static Color get auditRecentBorder => _p.auditRecentBorder;

  static Color get footerActiveBg => _p.footerActiveBg;
  static Color get errorBg => _p.errorBg;
  static Color get errorBorder => _p.errorBorder;
  static Color get errorText => _p.errorText;
  static Color get successBg => _p.successBg;
  static Color get successBorder => _p.successBorder;
  static Color get successText => _p.successText;
  static Color get btnSecondaryBg => _p.btnSecondaryBg;
  static Color get btnSecondaryBorder => _p.btnSecondaryBorder;

  static Color get statCardBg => _p.statCardBg;
  static Color get statCardBorder => _p.statCardBorder;
  static Color get statValueColor => _p.statValueColor;

  static List<BoxShadow> get cardShadow => _p.cardShadow;
  static List<BoxShadow> get floatShadow => _p.floatShadow;

  /// Soft icon wells — light soft pastels in Default (last commit), dark wells in Dark.
  static Color get softOrange =>
      isDark ? const Color(0xFF3D2418) : const Color(0xFFFFF5F0);
  static Color get softBlue =>
      isDark ? const Color(0xFF1A2740) : const Color(0xFFEFF6FF);
  static Color get softGreen =>
      isDark ? const Color(0xFF12261A) : const Color(0xFFECFDF5);
  static Color get softPurple =>
      isDark ? const Color(0xFF2A1F40) : const Color(0xFFF5F3FF);
  static Color get softTeal =>
      isDark ? const Color(0xFF0F2A2A) : const Color(0xFFF0FDFA);
}
