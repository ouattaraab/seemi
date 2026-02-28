import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

/// ThemeData PPV — Dark Theme exclusif, Material Design 3.
///
/// Utiliser `AppTheme.darkTheme` dans MaterialApp.
/// NE PAS utiliser `ColorScheme.fromSeed()` — contrôle exact des hex.
/// NE PAS utiliser `ColorScheme.dark()` — legacy Material 2.
abstract final class AppTheme {
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.kPrimary,
      onPrimary: AppColors.kBgBase,
      primaryContainer: AppColors.kPrimaryDark,
      onPrimaryContainer: AppColors.kPrimaryLight,
      secondary: AppColors.kAccentOrange,
      onSecondary: AppColors.kBgBase,
      secondaryContainer: AppColors.kAccentOrangeDark,
      onSecondaryContainer: AppColors.kAccentOrangeLight,
      tertiary: AppColors.kAccentViolet,
      onTertiary: AppColors.kBgBase,
      tertiaryContainer: AppColors.kAccentVioletDark,
      onTertiaryContainer: AppColors.kAccentVioletLight,
      error: AppColors.kError,
      onError: AppColors.kTextPrimary,
      surface: AppColors.kBgSurface,
      onSurface: AppColors.kTextPrimary,
      onSurfaceVariant: AppColors.kTextSecondary,
      outline: AppColors.kOutline,
      outlineVariant: AppColors.kDivider,
      inverseSurface: AppColors.kTextPrimary,
      onInverseSurface: AppColors.kBgBase,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.kBgBase,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      chipTheme: _chipTheme,
      snackBarTheme: _snackBarTheme,
      dialogTheme: _dialogTheme,
      bottomSheetTheme: _bottomSheetTheme,
      dividerTheme: _dividerTheme,
    );
  }

  // ─── Text Theme ───
  static const _textTheme = TextTheme(
    displayLarge: AppTextStyles.kDisplayLarge,
    headlineLarge: AppTextStyles.kHeadlineLarge,
    headlineMedium: AppTextStyles.kHeadlineMedium,
    titleLarge: AppTextStyles.kTitleLarge,
    bodyLarge: AppTextStyles.kBodyLarge,
    bodyMedium: AppTextStyles.kBodyMedium,
    labelLarge: AppTextStyles.kLabelLarge,
    bodySmall: AppTextStyles.kCaption,
  );

  // ─── AppBar ───
  static const _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: AppColors.kTextPrimary,
  );

  // ─── Elevated Button (Primary Teal) ───
  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: AppColors.kBgBase,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      textStyle: AppTextStyles.kTitleLarge.copyWith(color: AppColors.kBgBase),
    ),
  );

  // ─── Filled Button (Primary Teal) ───
  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: AppColors.kBgBase,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      textStyle: AppTextStyles.kTitleLarge.copyWith(color: AppColors.kBgBase),
    ),
  );

  // ─── Outlined Button ───
  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.kTextPrimary,
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: AppColors.kOutline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusButton),
      ),
      textStyle: AppTextStyles.kTitleLarge,
    ),
  );

  // ─── Text Button (Ghost Teal) ───
  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.kPrimary,
      textStyle: AppTextStyles.kTitleLarge.copyWith(color: AppColors.kPrimary),
    ),
  );

  // ─── Card ───
  static final _cardTheme = CardThemeData(
    color: AppColors.kBgSurface,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
    ),
  );

  // ─── Input Decoration ───
  static final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.kBgElevated,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: AppTextStyles.kBodyMedium.copyWith(
      color: AppColors.kTextTertiary,
    ),
  );

  // ─── Bottom Navigation Bar ───
  static const _bottomNavigationBarTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.kBgBase,
    selectedItemColor: AppColors.kPrimary,
    unselectedItemColor: AppColors.kTextTertiary,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
  );

  // ─── Floating Action Button ───
  static const _floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.kPrimary,
    foregroundColor: AppColors.kBgBase,
  );

  // ─── Chip ───
  static final _chipTheme = ChipThemeData(
    backgroundColor: AppColors.kBgSurface,
    selectedColor: AppColors.kPrimarySurface,
    labelStyle: AppTextStyles.kLabelLarge,
    side: const BorderSide(color: AppColors.kDivider),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
    ),
  );

  // ─── SnackBar ───
  static final _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.kBgOverlay,
    contentTextStyle: AppTextStyles.kBodyMedium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
    ),
    behavior: SnackBarBehavior.floating,
  );

  // ─── Dialog ───
  static final _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.kBgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
    ),
  );

  // ─── Bottom Sheet ───
  static const _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.kBgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.kRadiusXl),
      ),
    ),
  );

  // ─── Divider ───
  static const _dividerTheme = DividerThemeData(
    color: AppColors.kDivider,
    thickness: 1,
  );
}
