/// VintageVibe Mobile — Typography System
/// Mirrors Playfair Display (headings) + Inter (body) from the Angular frontend.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // ==================== Heading Font (Playfair Display) ====================
  static TextStyle heading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.dark,
    double height = 1.2,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // ==================== Body Font (Inter) ====================
  static TextStyle body({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.gray,
    double height = 1.6,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // ==================== Predefined Styles ====================

  // Display
  static TextStyle get displayLarge => heading(fontSize: 48, fontWeight: FontWeight.w900);
  static TextStyle get displayMedium => heading(fontSize: 36, fontWeight: FontWeight.w700);
  static TextStyle get displaySmall => heading(fontSize: 30, fontWeight: FontWeight.w700);

  // Headlines
  static TextStyle get headlineLarge => heading(fontSize: 24, fontWeight: FontWeight.w700);
  static TextStyle get headlineMedium => heading(fontSize: 20, fontWeight: FontWeight.w600);
  static TextStyle get headlineSmall => heading(fontSize: 18, fontWeight: FontWeight.w600);

  // Title
  static TextStyle get titleLarge => body(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.dark);
  static TextStyle get titleMedium => body(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark);
  static TextStyle get titleSmall => body(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark);

  // Body
  static TextStyle get bodyLarge => body(fontSize: 18);
  static TextStyle get bodyMedium => body(fontSize: 16);
  static TextStyle get bodySmall => body(fontSize: 14);

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
        color: AppColors.grayLight,
        height: 1.4,
      );

  // Form labels (uppercase, spaced)
  static TextStyle get formLabel => body(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.dark,
      );

  // Button text
  static TextStyle get button => body(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  // Price
  static TextStyle get price => heading(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get priceSmall => heading(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // Caption
  static TextStyle get caption => body(
        fontSize: 12,
        color: AppColors.grayLight,
      );
}
