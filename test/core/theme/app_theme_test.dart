import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_theme.dart';

void main() {
  late ThemeData theme;

  setUp(() {
    theme = AppTheme.darkTheme;
  });

  group('AppTheme - ColorScheme', () {
    test('brightness is dark', () {
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('primary is kPrimary teal', () {
      expect(theme.colorScheme.primary, AppColors.kPrimary);
    });

    test('secondary is kAccentOrange', () {
      expect(theme.colorScheme.secondary, AppColors.kAccentOrange);
    });

    test('tertiary is kAccentViolet', () {
      expect(theme.colorScheme.tertiary, AppColors.kAccentViolet);
    });

    test('error is kError', () {
      expect(theme.colorScheme.error, AppColors.kError);
    });

    test('surface is kBgSurface', () {
      expect(theme.colorScheme.surface, AppColors.kBgSurface);
    });
  });

  group('AppTheme - Scaffold', () {
    test('scaffoldBackgroundColor is kBgBase #0D0D0D', () {
      expect(theme.scaffoldBackgroundColor, AppColors.kBgBase);
    });
  });

  group('AppTheme - TextTheme', () {
    test('displayLarge is 32px ExtraBold', () {
      expect(theme.textTheme.displayLarge!.fontSize, 32);
      expect(theme.textTheme.displayLarge!.fontWeight, FontWeight.w800);
    });

    test('headlineLarge is 24px Bold', () {
      expect(theme.textTheme.headlineLarge!.fontSize, 24);
      expect(theme.textTheme.headlineLarge!.fontWeight, FontWeight.w700);
    });

    test('headlineMedium is 20px SemiBold', () {
      expect(theme.textTheme.headlineMedium!.fontSize, 20);
      expect(theme.textTheme.headlineMedium!.fontWeight, FontWeight.w600);
    });

    test('titleLarge is 17px SemiBold', () {
      expect(theme.textTheme.titleLarge!.fontSize, 17);
      expect(theme.textTheme.titleLarge!.fontWeight, FontWeight.w600);
    });

    test('bodyLarge is 15px Regular with height 1.5', () {
      expect(theme.textTheme.bodyLarge!.fontSize, 15);
      expect(theme.textTheme.bodyLarge!.fontWeight, FontWeight.w400);
      expect(theme.textTheme.bodyLarge!.height, 1.5);
    });

    test('bodyMedium is 14px Regular with height 1.5', () {
      expect(theme.textTheme.bodyMedium!.fontSize, 14);
      expect(theme.textTheme.bodyMedium!.fontWeight, FontWeight.w400);
      expect(theme.textTheme.bodyMedium!.height, 1.5);
    });

    test('labelLarge is 13px SemiBold', () {
      expect(theme.textTheme.labelLarge!.fontSize, 13);
      expect(theme.textTheme.labelLarge!.fontWeight, FontWeight.w600);
    });

    test('bodySmall (caption) is 12px Regular', () {
      expect(theme.textTheme.bodySmall!.fontSize, 12);
      expect(theme.textTheme.bodySmall!.fontWeight, FontWeight.w400);
    });
  });

  group('AppTheme - Button Heights', () {
    test('elevated button has min height 48dp', () {
      final style = theme.elevatedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 48);
    });

    test('filled button has min height 48dp', () {
      final style = theme.filledButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 48);
    });

    test('outlined button has min height 48dp', () {
      final style = theme.outlinedButtonTheme.style!;
      final minSize = style.minimumSize!.resolve({})!;
      expect(minSize.height, 48);
    });
  });

  group('AppTheme - Card', () {
    test('card color is kBgSurface', () {
      expect(theme.cardTheme.color, AppColors.kBgSurface);
    });

    test('card has rounded corners 16dp', () {
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      final radius = (shape.borderRadius as BorderRadius).topLeft;
      expect(radius.x, 16);
    });
  });

  group('AppTheme - Input Decoration', () {
    test('input is filled with kBgElevated', () {
      expect(theme.inputDecorationTheme.filled, true);
      expect(theme.inputDecorationTheme.fillColor, AppColors.kBgElevated);
    });

    test('focused border is teal', () {
      final focusedBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, AppColors.kPrimary);
    });
  });

  group('AppTheme - AppBar', () {
    test('appbar is transparent', () {
      expect(theme.appBarTheme.backgroundColor, Colors.transparent);
    });

    test('appbar title is centered', () {
      expect(theme.appBarTheme.centerTitle, true);
    });
  });

  group('AppTheme - Bottom Navigation', () {
    test('selected item color is teal', () {
      expect(theme.bottomNavigationBarTheme.selectedItemColor,
          AppColors.kPrimary);
    });
  });

  group('AppTheme - Dialog', () {
    test('dialog background is kBgSurface', () {
      expect(theme.dialogTheme.backgroundColor, AppColors.kBgSurface);
    });

    test('dialog has radius 24dp', () {
      final shape = theme.dialogTheme.shape as RoundedRectangleBorder;
      final radius = (shape.borderRadius as BorderRadius).topLeft;
      expect(radius.x, 24);
    });
  });

  group('AppTheme - SnackBar', () {
    test('snackbar background is kBgOverlay', () {
      expect(theme.snackBarTheme.backgroundColor, AppColors.kBgOverlay);
    });
  });

  group('AppTheme - Divider', () {
    test('divider color is kDivider', () {
      expect(theme.dividerTheme.color, AppColors.kDivider);
    });
  });
}
