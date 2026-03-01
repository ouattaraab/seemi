import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  static const String _font = 'Plus Jakarta Sans';

  static const TextStyle kDisplayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.kTextPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle kHeadlineLarge = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.kTextPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle kHeadlineMedium = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kTitleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kLabelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kCaption = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.kTextSecondary,
  );
}
