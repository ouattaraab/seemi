import 'package:flutter/material.dart';

/// Palette de couleurs PPV — Dark Theme exclusif.
///
/// Conventions : préfixe `k` pour toutes les constantes.
/// Référence : UX Design Specification PPV.
abstract final class AppColors {
  // ─── Backgrounds (dark → lighter) ───
  static const Color kBgBase = Color(0xFF0D0D0D);
  static const Color kBgSurface = Color(0xFF1A1A1A);
  static const Color kBgElevated = Color(0xFF242424);
  static const Color kBgOverlay = Color(0xFF2E2E2E);

  // ─── Primary Teal (confiance, navigation, actions créateur) ───
  static const Color kPrimary = Color(0xFF00BFA5);
  static const Color kPrimaryLight = Color(0xFF5DF2D6);
  static const Color kPrimaryDark = Color(0xFF008C7A);
  static const Color kPrimarySurface = Color(0x1F00BFA5); // rgba 0.12

  // ─── Accent Orange (CTA, achat, urgence) ───
  static const Color kAccentOrange = Color(0xFFFF8F00);
  static const Color kAccentOrangeLight = Color(0xFFFFC046);
  static const Color kAccentOrangeDark = Color(0xFFC56200);
  static const Color kAccentOrangeSurface = Color(0x1FFF8F00); // rgba 0.12

  // ─── Accent Violet (premium, innovation) ───
  static const Color kAccentViolet = Color(0xFFB388FF);
  static const Color kAccentVioletLight = Color(0xFFE7B9FF);
  static const Color kAccentVioletDark = Color(0xFF7C4DFF);
  static const Color kAccentVioletSurface = Color(0x1AB388FF); // rgba 0.10

  // ─── Sémantiques ───
  static const Color kSuccess = Color(0xFF4CAF50);
  static const Color kWarning = Color(0xFFFFC107);
  static const Color kError = Color(0xFFEF5350);
  static const Color kInfo = Color(0xFF29B6F6);

  // ─── Textes ───
  static const Color kTextPrimary = Color(0xFFFFFFFF);
  static const Color kTextSecondary = Color(0xB3FFFFFF); // rgba 0.70
  static const Color kTextTertiary = Color(0x80FFFFFF); // rgba 0.50
  static const Color kTextDisabled = Color(0x4DFFFFFF); // rgba 0.30

  // ─── Borders & Dividers ───
  static const Color kOutline = Color(0x1FFFFFFF); // rgba 0.12
  static const Color kDivider = Color(0x14FFFFFF); // rgba 0.08
}
