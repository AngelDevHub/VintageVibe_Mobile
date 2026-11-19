/// VintageVibe Mobile — Design System Colors
/// Mirrors the CSS variables from the Angular frontend.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==================== Primary Palette ====================
  /// Warm Gold — Primary CTA, buttons, highlights
  static const Color primary = Color(0xFFD4A574);
  static const Color primaryDark = Color(0xFFB8935E);
  static const Color primaryLight = Color(0xFFE8C9A0);

  // ==================== Secondary Palette ====================
  /// Rich Brown — Secondary buttons, accents
  static const Color secondary = Color(0xFF8B7355);
  static const Color secondaryDark = Color(0xFF6B5742);
  static const Color secondaryLight = Color(0xFFA68968);

  // ==================== Accent ====================
  /// Terracotta — Accent elements
  static const Color accent = Color(0xFFC7956D);
  static const Color accentDark = Color(0xFFA67C5A);
  static const Color accentLight = Color(0xFFDDB89A);

  // ==================== Neutral Colors ====================
  static const Color dark = Color(0xFF2C2416);
  static const Color darkSecondary = Color(0xFF3D3426);
  static const Color gray = Color(0xFF6B6458);
  static const Color grayLight = Color(0xFFB8AFA3);
  static const Color light = Color(0xFFF5F1ED);
  static const Color white = Color(0xFFFFFFFF);

  // ==================== Semantic Colors ====================
  static const Color success = Color(0xFF7A9B76);
  static const Color error = Color(0xFFC85A54);
  static const Color warning = Color(0xFFE3A857);
  static const Color info = Color(0xFF6B8E9F);

  // ==================== Gradients ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, accent],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [dark, darkSecondary],
  );

  // ==================== Shadows ====================
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.12),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.1),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.1),
          blurRadius: 15,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.15),
          blurRadius: 25,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: const Color(0xFF2C2416).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 10),
        ),
      ];
}
