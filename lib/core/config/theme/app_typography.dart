/// VintageVibe Mobile — Editorial Typography System
/// Combina encabezados editoriales (Playfair Display) con cuerpo limpio estilo iOS (Inter).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ==================== Heading Font (Playfair Display Editorial) ====================
  static TextStyle heading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.dark,
    double height = 1.2,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ==================== Body Font (Inter Clean iOS) ====================
  static TextStyle body({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.gray,
    double height = 1.45,
    double letterSpacing = -0.1,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ==================== Predefined Styles ====================

  // Display
  static TextStyle get displayLarge =>
      heading(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.6);
  static TextStyle get displayMedium =>
      heading(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get displaySmall =>
      heading(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.4);

  // Headlines
  static TextStyle get headlineLarge =>
      heading(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static TextStyle get headlineMedium =>
      heading(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static TextStyle get headlineSmall =>
      heading(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2);

  // Title
  static TextStyle get titleLarge =>
      body(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.dark);
  static TextStyle get titleMedium =>
      body(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.dark);
  static TextStyle get titleSmall =>
      body(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark);

  // Body
  static TextStyle get bodyLarge => body(fontSize: 16, color: AppColors.dark);
  static TextStyle get bodyMedium => body(fontSize: 14, color: AppColors.dark);
  static TextStyle get bodySmall => body(fontSize: 13, color: AppColors.gray);

  // Labels
  static TextStyle get labelLarge => body(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
      );
  static TextStyle get labelMedium => body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.gray,
      );
  static TextStyle get labelSmall => body(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.gray,
        height: 1.3,
        letterSpacing: 0.2,
      );

  // Form labels
  static TextStyle get formLabel => body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
      );

  // Button text
  static TextStyle get button => body(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
        letterSpacing: 0.1,
      );

  // Price (Firm editorial sans-serif)
  static TextStyle get price => body(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
        letterSpacing: -0.3,
      );

  static TextStyle get priceSmall => body(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
        letterSpacing: -0.2,
      );

  // Caption
  static TextStyle get caption => body(
        fontSize: 12,
        color: AppColors.gray,
      );
}
