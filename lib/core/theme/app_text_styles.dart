import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

/// Hiérarchie typographique SeeMi — tailles augmentées pour mobile.
///
/// Optimisé pour la lisibilité sur grand écran et les doigts épais.
abstract final class AppTextStyles {
  static const TextStyle kDisplayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.kTextPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle kHeadlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.kTextPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle kHeadlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kTitleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kBodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kLabelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.kTextPrimary,
  );

  static const TextStyle kCaption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.kTextSecondary,
  );
}
