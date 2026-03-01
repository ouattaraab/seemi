import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

/// ThemeData SeeMi — Dark Blue Theme, Material Design 3.
///
/// Couleur primaire : iOS Blue (#0A84FF).
/// Boutons : hauteur 56px minimum pour les CTA.
abstract final class AppTheme {
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.kPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.kPrimaryDark,
      onPrimaryContainer: AppColors.kPrimaryLight,
      secondary: AppColors.kAccentOrange,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.kAccentOrangeDark,
      onSecondaryContainer: AppColors.kAccentOrangeLight,
      tertiary: AppColors.kAccentViolet,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.kAccentVioletDark,
      onTertiaryContainer: AppColors.kAccentVioletLight,
      error: AppColors.kError,
      onError: Colors.white,
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
    titleTextStyle: TextStyle(
      color: AppColors.kTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
  );

  // ─── Elevated Button (Primary Blue) ───
  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      elevation: 0,
    ),
  );

  // ─── Filled Button (Primary Blue) ───
  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  // ─── Outlined Button ───
  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.kTextPrimary,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      side: const BorderSide(color: AppColors.kOutline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // ─── Text Button (Ghost Blue) ───
  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.kPrimary,
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.kPrimary,
      ),
    ),
  );

  // ─── Card ───
  static final _cardTheme = CardThemeData(
    color: AppColors.kBgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
      side: const BorderSide(color: AppColors.kDivider),
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
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    hintStyle: AppTextStyles.kBodyMedium.copyWith(
      color: AppColors.kTextTertiary,
    ),
    labelStyle: AppTextStyles.kBodyMedium.copyWith(
      color: AppColors.kTextSecondary,
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
    selectedLabelStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    elevation: 12,
  );

  // ─── Floating Action Button ───
  static const _floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.kPrimary,
    foregroundColor: Colors.white,
    elevation: 4,
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
