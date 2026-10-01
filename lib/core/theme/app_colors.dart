import 'package:flutter/material.dart';

/// Warm, calm, trustworthy palette. Deliberately NOT a dating-app palette
/// (no hot pinks / reds). High contrast for a 60+ audience.
class AppColors {
  AppColors._();

  // Primary: a warm, grounded teal-green — calm and optimistic.
  static const Color primary = Color(0xFF1E7D74);
  static const Color primaryDark = Color(0xFF14615A);
  static const Color primaryLight = Color(0xFFE3F2F0);

  // Secondary: warm amber — friendly, human, welcoming.
  static const Color accent = Color(0xFFE08A2B);
  static const Color accentLight = Color(0xFFFBEBD8);

  // Neutrals
  static const Color ink = Color(0xFF1C2422); // near-black text, softened
  static const Color inkSoft = Color(0xFF4A5551);
  static const Color inkFaint = Color(0xFF7A8580);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F7F5);
  static const Color border = Color(0xFFE1E5E2);

  // Semantic
  static const Color success = Color(0xFF2E7D46);
  static const Color danger = Color(0xFFC0392B);
  static const Color dangerLight = Color(0xFFFBE7E4);
  static const Color warning = Color(0xFFB8860B);

  static const Color online = Color(0xFF2E7D46);

  // Per-category accent colors for interest chips (soft bg + strong fg).
  static const Color outdoorsBg = Color(0xFFE3F2EC);
  static const Color outdoorsFg = Color(0xFF1E7D5A);
  static const Color socialBg = Color(0xFFE6EEFB);
  static const Color socialFg = Color(0xFF2F5FC7);
  static const Color creativeBg = Color(0xFFF0E9FB);
  static const Color creativeFg = Color(0xFF7A4FC0);
  static const Color learningBg = Color(0xFFFBEBD8);
  static const Color learningFg = Color(0xFFC0771E);
  static const Color fitnessBg = Color(0xFFFCE7EE);
  static const Color fitnessFg = Color(0xFFC0417A);
}
