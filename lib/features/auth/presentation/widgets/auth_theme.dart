import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors & typography from stitch `code.html`.
class AuthTheme {
  AuthTheme._();

  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF2D7835);
  static const brand = Color(0xFF3F8F3F);
  static const brandTagline = Color(0xFF3F693F);
  static const ink = Color(0xFF20252B);
  static const muted = Color(0xFF59636F);
  static const mutedLight = Color(0xFF7B837D);
  static const line = Color(0xFFE1E5E2);
  static const lineSoft = Color(0xFFE4E7E4);
  static const inputBg = Color(0xFFF4F6F4);
  static const shieldBg = Color(0xFFEFF9EE);
  static const warningBg = Color(0xFFF8FAF8);
  static const secureBg = Color(0xFFF5FBF4);
  static const secureBorder = Color(0xFFDFEFDD);
  static const featureGreenBg = Color(0xFFEDF8ED);
  static const featureYellowBg = Color(0xFFFFF8DD);
  static const timerGreen = Color(0xFF31823B);
  static const resendGreen = Color(0xFF3D9144);

  static TextStyle title([Color? c]) => GoogleFonts.inter(
    fontSize: 27,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: c ?? ink,
  );

  static TextStyle otpTitle([Color? c]) => GoogleFonts.inter(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: c ?? ink,
  );

  static TextStyle brandName([Color? c]) => GoogleFonts.inter(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: c ?? brand,
  );

  static TextStyle body([Color? c]) =>
      GoogleFonts.inter(fontSize: 15, height: 1.5, color: c ?? muted);

  static TextStyle bodySm([Color? c]) =>
      GoogleFonts.inter(fontSize: 14, color: c ?? mutedLight);

  static TextStyle label([Color? c]) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: c ?? ink,
  );

  static TextStyle caption([Color? c]) =>
      GoogleFonts.inter(fontSize: 12, color: c ?? mutedLight);

  static TextStyle button([Color? c]) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: c ?? Colors.white,
  );
}
