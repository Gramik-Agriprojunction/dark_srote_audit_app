import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gramik Darkstore theme — aligned with RN `theme.js` + `Login.js`.
class AuthTheme {
  AuthTheme._();

  static const primary = Color(0xFFEC5800);
  static const primaryDark = Color(0xFFD04E00);
  static const screenBg = Color(0xFFF0F5FA);
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF999999);
  static const mutedLight = Color(0xFF888888);
  static const line = Color(0xFFECECEC);
  static const lineSoft = Color(0xFFD7DEE7);
  static const inputBg = Color(0xFFF7F7F8);
  static const cardBorder = Color(0xFFD7DEE7);

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
        color: c ?? Colors.white,
      );

  static TextStyle brandName([Color? c]) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: c ?? Colors.white.withValues(alpha: 0.8),
      );

  static TextStyle brandNameBold([Color? c]) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: c ?? Colors.white,
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
