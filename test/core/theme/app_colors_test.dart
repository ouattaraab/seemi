import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

void main() {
  group('AppColors - Backgrounds', () {
    test('kBgBase is cream #FDFBF7', () {
      expect(AppColors.kBgBase, const Color(0xFFFDFBF7));
    });

    test('kBgSurface is white #FFFFFF', () {
      expect(AppColors.kBgSurface, const Color(0xFFFFFFFF));
    });

    test('kBgElevated is #F3F4F6', () {
      expect(AppColors.kBgElevated, const Color(0xFFF3F4F6));
    });

    test('kBgOverlay is #F1F5F9', () {
      expect(AppColors.kBgOverlay, const Color(0xFFF1F5F9));
    });
  });

  group('AppColors - Primary Indigo', () {
    test('kPrimary is #4338CA', () {
      expect(AppColors.kPrimary, const Color(0xFF4338CA));
    });

    test('kPrimaryLight is #6366F1', () {
      expect(AppColors.kPrimaryLight, const Color(0xFF6366F1));
    });

    test('kPrimaryDark is #3730A3', () {
      expect(AppColors.kPrimaryDark, const Color(0xFF3730A3));
    });

    test('kPrimarySurface has alpha ~0.10', () {
      expect(AppColors.kPrimarySurface.a, closeTo(0.10, 0.02));
    });
  });

  group('AppColors - Accent Amber', () {
    test('kAccent is #F59E0B', () {
      expect(AppColors.kAccent, const Color(0xFFF59E0B));
    });

    test('kAccentLight is #FBBF24', () {
      expect(AppColors.kAccentLight, const Color(0xFFFBBF24));
    });

    test('kAccentDark is #D97706', () {
      expect(AppColors.kAccentDark, const Color(0xFFD97706));
    });
  });

  group('AppColors - Accent Violet', () {
    test('kAccentViolet is #8B5CF6', () {
      expect(AppColors.kAccentViolet, const Color(0xFF8B5CF6));
    });

    test('kAccentVioletLight is #A78BFA', () {
      expect(AppColors.kAccentVioletLight, const Color(0xFFA78BFA));
    });

    test('kAccentVioletDark is #7C3AED', () {
      expect(AppColors.kAccentVioletDark, const Color(0xFF7C3AED));
    });

    test('kAccentVioletSurface has alpha ~0.10', () {
      expect(AppColors.kAccentVioletSurface.a, closeTo(0.10, 0.02));
    });
  });

  group('AppColors - Semantic', () {
    test('kSuccess is #10B981', () {
      expect(AppColors.kSuccess, const Color(0xFF10B981));
    });

    test('kWarning is #F59E0B', () {
      expect(AppColors.kWarning, const Color(0xFFF59E0B));
    });

    test('kError is #EF4444', () {
      expect(AppColors.kError, const Color(0xFFEF4444));
    });

    test('kInfo is #3B82F6', () {
      expect(AppColors.kInfo, const Color(0xFF3B82F6));
    });
  });

  group('AppColors - Text', () {
    test('kTextPrimary is near-black #0B1120', () {
      expect(AppColors.kTextPrimary, const Color(0xFF0B1120));
    });

    test('kTextSecondary is #64748B', () {
      expect(AppColors.kTextSecondary, const Color(0xFF64748B));
    });

    test('kTextTertiary is #94A3B8', () {
      expect(AppColors.kTextTertiary, const Color(0xFF94A3B8));
    });

    test('kTextDisabled is #94A3B8', () {
      expect(AppColors.kTextDisabled, const Color(0xFF94A3B8));
    });
  });

  group('AppColors - Borders & Dividers', () {
    test('kOutline is #E2E8F0', () {
      expect(AppColors.kOutline, const Color(0xFFE2E8F0));
    });

    test('kBorder is #E2E8F0', () {
      expect(AppColors.kBorder, const Color(0xFFE2E8F0));
    });

    test('kDivider is #E2E8F0', () {
      expect(AppColors.kDivider, const Color(0xFFE2E8F0));
    });
  });

  group('AppColors - Compat aliases', () {
    test('kAccentOrange equals kAccent', () {
      expect(AppColors.kAccentOrange, AppColors.kAccent);
    });

    test('kAccentOrangeLight equals kAccentLight', () {
      expect(AppColors.kAccentOrangeLight, AppColors.kAccentLight);
    });

    test('kAccentOrangeDark equals kAccentDark', () {
      expect(AppColors.kAccentOrangeDark, AppColors.kAccentDark);
    });
  });
}
