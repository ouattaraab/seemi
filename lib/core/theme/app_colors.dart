import 'package:flutter/material.dart';

/// Palette de couleurs SeeMi — Dark Blue Theme.
///
/// Couleur primaire : iOS Blue (#0A84FF).
/// Fond : bleu marine profond (#050D1F → #080F1E).
/// Effet glass : panneaux translucides avec backdrop blur.
abstract final class AppColors {
  // ─── Backgrounds (bleu marine profond) ───
  static const Color kBgBase = Color(0xFF070E1D);
  static const Color kBgSurface = Color(0xFF0D1B35);
  static const Color kBgElevated = Color(0xFF152848);
  static const Color kBgOverlay = Color(0xFF1C3458);

  // ─── Primary Blue (iOS 16 blue) ───
  static const Color kPrimary = Color(0xFF0A84FF);
  static const Color kPrimaryLight = Color(0xFF4DA6FF);
  static const Color kPrimaryDark = Color(0xFF005EC4);
  static const Color kPrimarySurface = Color(0x200A84FF); // 12.5%

  // ─── Accent Orange (CTA secondaire, urgence) ───
  static const Color kAccentOrange = Color(0xFFFF9F0A);
  static const Color kAccentOrangeLight = Color(0xFFFFBF4D);
  static const Color kAccentOrangeDark = Color(0xFFBF7000);
  static const Color kAccentOrangeSurface = Color(0x1FFF9F0A);

  // ─── Accent Violet (premium) ───
  static const Color kAccentViolet = Color(0xFFBF5AF2);
  static const Color kAccentVioletLight = Color(0xFFD88BFF);
  static const Color kAccentVioletDark = Color(0xFF8A2BE2);
  static const Color kAccentVioletSurface = Color(0x1ABF5AF2);

  // ─── Sémantiques (palette iOS 16) ───
  static const Color kSuccess = Color(0xFF30D158);
  static const Color kWarning = Color(0xFFFFD60A);
  static const Color kError = Color(0xFFFF453A);
  static const Color kInfo = Color(0xFF64D2FF);

  // ─── Glass effect ───
  static const Color kGlassBg = Color(0x14FFFFFF);       // blanc 8%
  static const Color kGlassBorder = Color(0x1AFFFFFF);  // blanc 10%
  static const Color kGlassHighlight = Color(0x0DFFFFFF); // blanc 5%

  // ─── Textes ───
  static const Color kTextPrimary = Color(0xFFFFFFFF);
  static const Color kTextSecondary = Color(0xB3FFFFFF); // 70%
  static const Color kTextTertiary = Color(0x80FFFFFF);  // 50%
  static const Color kTextDisabled = Color(0x4DFFFFFF);  // 30%

  // ─── Borders & Dividers ───
  static const Color kOutline = Color(0x1FFFFFFF);  // 12%
  static const Color kDivider = Color(0x14FFFFFF);  // 8%
}
