import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

/// Hiérarchie typographique PPV — Roboto (natif Material).
///
/// Line-height 1.5 pour body text, 1.2 pour display/headlines.
abstract final class AppTextStyles {
  static const TextStyle kDisplayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kHeadlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kHeadlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kTitleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kLabelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextSecondary,
  );
}
