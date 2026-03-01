import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_theme.dart';

void main() {
  late ThemeData theme;

  setUp(() {
    theme = AppTheme.darkTheme; // alias for the cream light theme
  });

  group('AppTheme - ColorScheme', () {
    test('brightness is light', () {
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('primary is kPrimary indigo', () {
      expect(theme.colorScheme.primary, AppColors.kPrimary);
    });

    test('secondary is kAccent amber', () {
      expect(theme.colorScheme.secondary, AppColors.kAccent);
    });

    test('tertiary is kSuccess', () {
      expect(theme.colorScheme.tertiary, AppColors.kSuccess);
    });

    test('error is kError', () {
      expect(theme.colorScheme.error, AppColors.kError);
    });

    test('surface is kBgBase', () {
      expect(theme.colorScheme.surface, AppColors.kBgBase);
    });
  });

  group('AppTheme - Scaffold', () {
    test('scaffoldBackgroundColor is kBgBase', () {
      expect(theme.scaffoldBackgroundColor, AppColors.kBgBase);
    });
  });

  group('AppTheme - TextTheme', () {
    test('displayLarge is 36px ExtraBold', () {
      expect(theme.textTheme.displayLarge!.fontSize, 36);
      expect(theme.textTheme.displayLarge!.fontWeight, FontWeight.w800);
    });

    test('headlineLarge is 28px ExtraBold', () {
      expect(theme.textTheme.headlineLarge!.fontSize, 28);
      expect(theme.textTheme.headlineLarge!.fontWeight, FontWeight.w800);
    });

    test('headlineMedium is 22px Bold', () {
      expect(theme.textTheme.headlineMedium!.fontSize, 22);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w700);
    });

    test('titleLarge is 18px Bold', () {
      expect(theme.textTheme.titleLarge!.fontSize, 18);
      expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w700);
    });

    test('bodyLarge is 16px Medium', () {
      expect(theme.textTheme.bodyLarge!.fontSize, 16);
      expect(theme.textTheme.bodyLarge!.fontWeight, FontWeight.w500);
    });

    test('bodyMedium is 15px Regular', () {
      expect(theme.textTheme.bodyMedium!.fontSize, 15);
      expect(theme.textTheme.bodyMedium!.fontWeight, FontWeight.w400);
    });

    test('labelLarge is 15px Bold', () {
      expect(theme.textTheme.labelLarge!.fontSize, 15);
      expect(theme.textTheme.labelLarge!.fontWeight, FontWeight.w700);
    });

    test('bodySmall (caption) is 13px Regular', () {
      expect(theme.textTheme.bodySmall!.fontSize, 13);
      expect(theme.textTheme.bodySmall!.fontWeight, FontWeight.w400);
    });
  });

  group('AppTheme - Button Heights', () {
    test('elevated button has min height 56dp', () {
      final style = theme.elevatedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 56);
    });

    test('filled button has min height 56dp', () {
      final style = theme.filledButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 56);
    });

    test('outlined button has min height 56dp', () {
      final style = theme.outlinedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 56);
    });
  });

  group('AppTheme - Card', () {
    test('card color is kBgSurface', () {
      expect(theme.cardTheme.color, AppColors.kBgSurface);
    });

    test('card has rounded corners 32dp', () {
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      final radius = (shape.borderRadius as BorderRadius).topLeft;
      expect(radius.x, 32);
    });
  });

  group('AppTheme - Input Decoration', () {
    test('input is filled with kBgSurface', () {
      expect(theme.inputDecorationTheme.filled, true);
      expect(theme.inputDecorationTheme.fillColor, AppColors.kBgSurface);
    });

    test('focused border is kAccent amber', () {
      final focusedBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, AppColors.kAccent);
    });
  });

  group('AppTheme - AppBar', () {
    test('appbar background is kBgBase', () {
      expect(theme.appBarTheme.backgroundColor, AppColors.kBgBase);
    });

    test('appbar title is not centered', () {
      expect(theme.appBarTheme.centerTitle, false);
    });
  });

  group('AppTheme - Bottom Navigation', () {
    test('selected item color is kPrimary indigo', () {
      expect(
          theme.bottomNavigationBarTheme.selectedItemColor, AppColors.kPrimary);
    });
  });

  group('AppTheme - Dialog', () {
    test('dialog background is kBgSurface', () {
      expect(theme.dialogTheme.backgroundColor, AppColors.kBgSurface);
    });

    test('dialog has radius 32dp', () {
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      final radius = (shape.borderRadius as BorderRadius).topLeft;
      expect(radius.x, 32);
    });
  });

  group('AppTheme - SnackBar', () {
    test('snackbar background is kTextPrimary', () {
      expect(theme.snackBarTheme.backgroundColor, AppColors.kTextPrimary);
    });
  });

  group('AppTheme - Divider', () {
    test('divider color is kDivider', () {
      expect(theme.dividerTheme.color, AppColors.kDivider);
    });
  });
}
