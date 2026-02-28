import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing - Spacing (8px system)', () {
    test('kSpaceXs is 4', () {
      expect(AppSpacing.kSpaceXs, 4);
    });

    test('kSpaceSm is 8', () {
      expect(AppSpacing.kSpaceSm, 8);
    });

    test('kSpaceMd is 16', () {
      expect(AppSpacing.kSpaceMd, 16);
    });

    test('kSpaceLg is 24', () {
      expect(AppSpacing.kSpaceLg, 24);
    });

    test('kSpaceXl is 32', () {
      expect(AppSpacing.kSpaceXl, 32);
    });

    test('kSpace2xl is 48', () {
      expect(AppSpacing.kSpace2xl, 48);
    });
  });

  group('AppSpacing - Corner Radius', () {
    test('kRadiusSm is 8', () {
      expect(AppSpacing.kRadiusSm, 8);
    });

    test('kRadiusButton is 10', () {
      expect(AppSpacing.kRadiusButton, 10);
    });

    test('kRadiusMd is 12', () {
      expect(AppSpacing.kRadiusMd, 12);
    });

    test('kRadiusCta is 14', () {
      expect(AppSpacing.kRadiusCta, 14);
    });

    test('kRadiusLg is 16', () {
      expect(AppSpacing.kRadiusLg, 16);
    });

    test('kRadiusXl is 24', () {
      expect(AppSpacing.kRadiusXl, 24);
    });
  });

  group('AppSpacing - Screen Margins', () {
    test('kScreenMargin is 16', () {
      expect(AppSpacing.kScreenMargin, 16);
    });
  });
}
