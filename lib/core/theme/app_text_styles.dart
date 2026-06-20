import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: -0.3);
  static const h3 = TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const h4 = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static const bodySmall = TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.3);

  static const buttonPrimary = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white);
  static const buttonSecondary = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const link = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary);
}
