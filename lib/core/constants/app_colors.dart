import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF355872);
  static const Color primaryMid = Color(0xFF7AAACE);
  static const Color primaryLight = Color(0xFF9CD5FF);
  static const Color background = Color(0xFFF7F8F0);

  // Surface & text
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A2530);
  static const Color textSecondary = Color(0xFF5A7A91);
  static const Color divider = Color(0xFFE0E8EE);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57F17);
  static const Color info = Color(0xFF0277BD);

  // Call direction
  static const Color inbound = Color(0xFF2E7D32);
  static const Color outbound = Color(0xFF355872);
  static const Color missed = Color(0xFFD32F2F);
  static const Color rejected = Color(0xFFF57F17);

  // Card shadow color (primary at 6% opacity)
  static const Color cardShadow = Color(0x0F355872);
}
