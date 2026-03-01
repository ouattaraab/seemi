import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color kBgBase     = Color(0xFFFDFBF7); // crème chaud
  static const Color kBgSurface  = Color(0xFFFFFFFF); // card
  static const Color kBgElevated = Color(0xFFF3F4F6); // secondary
  static const Color kBgOverlay  = Color(0xFFF1F5F9); // muted

  // Primary (indigo)
  static const Color kPrimary      = Color(0xFF4338CA);
  static const Color kPrimaryDark  = Color(0xFF3730A3);
  static const Color kPrimaryLight = Color(0xFF6366F1);
  static const Color kPrimarySurface = Color(0x1A4338CA); // 10% opacity

  // Accent (ambre)
  static const Color kAccent     = Color(0xFFF59E0B);
  static const Color kAccentDark = Color(0xFFD97706);
  static const Color kAccentLight= Color(0xFFFBBF24);

  // Semantic
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kError   = Color(0xFFEF4444);
  static const Color kWarning = Color(0xFFF59E0B);

  // Text
  static const Color kTextPrimary   = Color(0xFF0B1120);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kTextTertiary  = Color(0xFF94A3B8);

  // UI
  static const Color kDivider  = Color(0xFFE2E8F0);
  static const Color kOutline  = Color(0xFFE2E8F0);
  static const Color kBorder   = Color(0xFFE2E8F0); // alias for convenience

  // Glass (kept for compat)
  static const Color kGlassBg        = Color(0x0AFFFFFF);
  static const Color kGlassBorder    = Color(0x1AFFFFFF);
  static const Color kGlassHighlight = Color(0x14FFFFFF);

  // ── Compat aliases (ancienne palette) ────────────────────────────────────
  // Maintenu pour ne pas casser les écrans existants.

  /// Texte désactivé / placeholder
  static const Color kTextDisabled = Color(0xFF94A3B8); // = kTextTertiary

  /// Info (bleu lien)
  static const Color kInfo = Color(0xFF3B82F6);

  /// Orange accent (ex. prix, tags)
  static const Color kAccentOrange      = Color(0xFFF59E0B); // = kAccent
  static const Color kAccentOrangeLight = Color(0xFFFBBF24);
  static const Color kAccentOrangeDark  = Color(0xFFD97706);

  /// Violet accent (ex. stories, catégories)
  static const Color kAccentViolet        = Color(0xFF8B5CF6);
  static const Color kAccentVioletLight   = Color(0xFFA78BFA);
  static const Color kAccentVioletDark    = Color(0xFF7C3AED);
  static const Color kAccentVioletSurface = Color(0x1A8B5CF6);
}
