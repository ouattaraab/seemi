import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

void main() {
  group('AppColors - Backgrounds', () {
    test('kBgBase is #0D0D0D', () {
      expect(AppColors.kBgBase, const Color(0xFF0D0D0D));
    });

    test('kBgSurface is #1A1A1A', () {
      expect(AppColors.kBgSurface, const Color(0xFF1A1A1A));
    });

    test('kBgElevated is #242424', () {
      expect(AppColors.kBgElevated, const Color(0xFF242424));
    });

    test('kBgOverlay is #2E2E2E', () {
      expect(AppColors.kBgOverlay, const Color(0xFF2E2E2E));
    });
  });

  group('AppColors - Primary Teal', () {
    test('kPrimary is #00BFA5', () {
      expect(AppColors.kPrimary, const Color(0xFF00BFA5));
    });

    test('kPrimaryLight is #5DF2D6', () {
      expect(AppColors.kPrimaryLight, const Color(0xFF5DF2D6));
    });

    test('kPrimaryDark is #008C7A', () {
      expect(AppColors.kPrimaryDark, const Color(0xFF008C7A));
    });

    test('kPrimarySurface has alpha ~0.12', () {
      expect(AppColors.kPrimarySurface.a, closeTo(0.12, 0.02));
    });
  });

  group('AppColors - Accent Orange', () {
    test('kAccentOrange is #FF8F00', () {
      expect(AppColors.kAccentOrange, const Color(0xFFFF8F00));
    });

    test('kAccentOrangeLight is #FFC046', () {
      expect(AppColors.kAccentOrangeLight, const Color(0xFFFFC046));
    });

    test('kAccentOrangeDark is #C56200', () {
      expect(AppColors.kAccentOrangeDark, const Color(0xFFC56200));
    });

    test('kAccentOrangeSurface has alpha ~0.12', () {
      expect(AppColors.kAccentOrangeSurface.a, closeTo(0.12, 0.02));
    });
  });

  group('AppColors - Accent Violet', () {
    test('kAccentViolet is #B388FF', () {
      expect(AppColors.kAccentViolet, const Color(0xFFB388FF));
    });

    test('kAccentVioletLight is #E7B9FF', () {
      expect(AppColors.kAccentVioletLight, const Color(0xFFE7B9FF));
    });

    test('kAccentVioletDark is #7C4DFF', () {
      expect(AppColors.kAccentVioletDark, const Color(0xFF7C4DFF));
    });

    test('kAccentVioletSurface has alpha ~0.10', () {
      expect(AppColors.kAccentVioletSurface.a, closeTo(0.10, 0.02));
    });
  });

  group('AppColors - Semantic', () {
    test('kSuccess is #4CAF50', () {
      expect(AppColors.kSuccess, const Color(0xFF4CAF50));
    });

    test('kWarning is #FFC107', () {
      expect(AppColors.kWarning, const Color(0xFFFFC107));
    });

    test('kError is #EF5350', () {
      expect(AppColors.kError, const Color(0xFFEF5350));
    });

    test('kInfo is #29B6F6', () {
      expect(AppColors.kInfo, const Color(0xFF29B6F6));
    });
  });

  group('AppColors - Text', () {
    test('kTextPrimary is white', () {
      expect(AppColors.kTextPrimary, const Color(0xFFFFFFFF));
    });

    test('kTextSecondary has alpha ~0.70', () {
      expect(AppColors.kTextSecondary.a, closeTo(0.70, 0.02));
    });

    test('kTextTertiary has alpha ~0.50', () {
      expect(AppColors.kTextTertiary.a, closeTo(0.50, 0.02));
    });

    test('kTextDisabled has alpha ~0.30', () {
      expect(AppColors.kTextDisabled.a, closeTo(0.30, 0.02));
    });
  });

  group('AppColors - Borders & Dividers', () {
    test('kOutline has alpha ~0.12', () {
      expect(AppColors.kOutline.a, closeTo(0.12, 0.02));
    });

    test('kDivider has alpha ~0.08', () {
      expect(AppColors.kDivider.a, closeTo(0.08, 0.02));
    });
  });
}
