import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFF9FE1CB);
  static const primaryDark = Color(0xFF0F6E56);
  static const primarySurface = Color(0xFFE1F5EE);

  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFF9F8F4);
  static const backgroundTertiary = Color(0xFFF1EFE8);

  static const textPrimary = Color(0xFF111110);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textTertiary = Color(0xFF888780);
  static const textHint = Color(0xFFB4B2A9);

  static const border = Color(0xFFD3D1C7);
  static const borderLight = Color(0xFFE8E6DF);

  static const success = Color(0xFF1D9E75);
  static const successSurface = Color(0xFFEAF3DE);
  static const successText = Color(0xFF27500A);

  static const error = Color(0xFFE24B4A);
  static const errorSurface = Color(0xFFFCEBEB);
  static const errorBorder = Color(0xFFF09595);
  static const errorText = Color(0xFF791F1F);

  static const warning = Color(0xFFEF9F27);
  static const warningSurface = Color(0xFFFAEEDA);
  static const warningText = Color(0xFF633806);

  static const info = Color(0xFF378ADD);
  static const infoSurface = Color(0xFFE6F1FB);
  static const infoText = Color(0xFF0C447C);

  static const pending = Color(0xFFEF9F27);
  static const pendingSurface = Color(0xFFFAEEDA);
  static const pendingText = Color(0xFF633806);

  static const avatarColors = [
    Color(0xFFE6F1FB),
    Color(0xFFEEEDFE),
    Color(0xFFEAF3DE),
    Color(0xFFFAEEDA),
    Color(0xFFFAECE7),
    Color(0xFFFBEAF0),
  ];

  static const avatarTextColors = [
    Color(0xFF0C447C),
    Color(0xFF3C3489),
    Color(0xFF27500A),
    Color(0xFF633806),
    Color(0xFF712B13),
    Color(0xFF72243E),
  ];

  static Color avatarBg(String name) {
    final index = name.hashCode.abs() % avatarColors.length;
    return avatarColors[index];
  }

  static Color avatarText(String name) {
    final index = name.hashCode.abs() % avatarTextColors.length;
    return avatarTextColors[index];
  }
}
