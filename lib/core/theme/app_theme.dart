import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final dmSans = GoogleFonts.dmSansTextTheme();
    final sora = GoogleFonts.sora();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: Colors.white,
      ),
      textTheme: dmSans.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderInput, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderInput, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      extensions: [AppTextStyles(sora: sora)],
    );
  }
}

class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({required this.sora});

  final TextStyle sora;

  @override
  AppTextStyles copyWith({TextStyle? sora}) => AppTextStyles(sora: sora ?? this.sora);

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) => this;
}

extension AppThemeX on BuildContext {
  TextStyle get sora => Theme.of(this).extension<AppTextStyles>()!.sora;
}
