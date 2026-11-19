/// VintageVibe Mobile — Editorial iOS Design System Colors
/// Basado en la guía `vintage-fashion-ios-ui`: papel cálido, negro tinta y bordes sutiles.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ==================== Editorial Core Palette ====================
  /// Ink Black — Primary CTA, active elements, strong editorial contrast
  static const Color primary = Color(0xFF141414);
  static const Color primaryDark = Color(0xFF0B0B0C);
  static const Color primaryLight = Color(0xFFF2F0EB);

  /// Organic Forest Olive — Subtle vintage secondary accent
  static const Color secondary = Color(0xFF3B4D3B);
  static const Color secondaryDark = Color(0xFF2B392B);
  static const Color secondaryLight = Color(0xFFE7ECE7);

  /// Muted Terracotta — Discrete vintage editorial accent
  static const Color accent = Color(0xFF9E5B40);
  static const Color accentDark = Color(0xFF7D4530);
  static const Color accentLight = Color(0xFFF3E7E2);

  // ==================== Editorial Neutrals ====================
  /// Text primary (Ink Black)
  static const Color dark = Color(0xFF141414);
  static const Color darkSecondary = Color(0xFF262629);

  /// Text secondary (iOS Native Secondary Gray)
  static const Color gray = Color(0xFF6E6E73);

  /// Subtle Border (#E5E2DC) & Soft Surface (#F2F0EB)
  static const Color border = Color(0xFFE5E2DC);
  static const Color surfaceSoft = Color(0xFFF2F0EB);
  static const Color grayLight = Color(0xFFE5E2DC);

  /// Warm Paper Background (#FAF9F6)
  static const Color light = Color(0xFFFAF9F6);
  static const Color white = Color(0xFFFFFFFF);

  // ==================== Semantic Colors ====================
  static const Color success = Color(0xFF3B4D3B);
  static const Color error = Color(0xFFB33A3A);
  static const Color warning = Color(0xFF9E5B40);
  static const Color info = Color(0xFF4A6170);

  // ==================== Editorial Flat Shadows (Sutiles, nunca pesados) ====================
  static List<BoxShadow> get shadowSm => const [];
  static List<BoxShadow> get shadowMd => const [];
  static List<BoxShadow> get shadowLg => const [];
  static List<BoxShadow> get shadowXl => const [];
}
