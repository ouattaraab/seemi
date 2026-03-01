import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme => _lightTheme; // alias for compat

  static ThemeData get _lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.kPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.kPrimarySurface,
      onPrimaryContainer: AppColors.kPrimary,
      secondary: AppColors.kAccent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFEF3C7),
      onSecondaryContainer: AppColors.kAccentDark,
      tertiary: AppColors.kSuccess,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD1FAE5),
      onTertiaryContainer: Color(0xFF065F46),
      error: AppColors.kError,
      onError: Colors.white,
      surface: AppColors.kBgBase,
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
      bottomNavigationBarTheme: _bottomNavTheme,
      floatingActionButtonTheme: _fabTheme,
      chipTheme: _chipTheme,
      snackBarTheme: _snackBarTheme,
      dialogTheme: _dialogTheme,
      bottomSheetTheme: _bottomSheetTheme,
      dividerTheme: _dividerTheme,
    );
  }

  static const _textTheme = TextTheme(
    displayLarge:  AppTextStyles.kDisplayLarge,
    headlineLarge: AppTextStyles.kHeadlineLarge,
    headlineMedium:AppTextStyles.kHeadlineMedium,
    titleLarge:    AppTextStyles.kTitleLarge,
    bodyLarge:     AppTextStyles.kBodyLarge,
    bodyMedium:    AppTextStyles.kBodyMedium,
    labelLarge:    AppTextStyles.kLabelLarge,
    bodySmall:     AppTextStyles.kCaption,
  );

  static const _appBarTheme = AppBarTheme(
    backgroundColor: AppColors.kBgBase,
    elevation: 0,
    centerTitle: false,
    foregroundColor: AppColors.kTextPrimary,
    titleTextStyle: TextStyle(
      fontFamily: 'Plus Jakarta Sans',
      color: AppColors.kTextPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );

  static final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
    ),
  );

  static final _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static final _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.kTextPrimary,
      minimumSize: const Size.fromHeight(AppSpacing.kButtonHeight),
      side: const BorderSide(color: AppColors.kOutline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.kPrimary,
      textStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static final _cardTheme = CardThemeData(
    color: AppColors.kBgSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
      side: const BorderSide(color: AppColors.kDivider),
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.kBgSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      borderSide: const BorderSide(color: AppColors.kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      borderSide: const BorderSide(color: AppColors.kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      borderSide: const BorderSide(color: AppColors.kAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    hintStyle: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextTertiary),
    labelStyle: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
  );

  static const _bottomNavTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.kBgBase,
    selectedItemColor: AppColors.kPrimary,
    unselectedItemColor: AppColors.kTextTertiary,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 10, fontWeight: FontWeight.w700),
    elevation: 0,
  );

  static const _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.kPrimary,
    foregroundColor: Colors.white,
    elevation: 4,
  );

  static final _chipTheme = ChipThemeData(
    backgroundColor: AppColors.kBgElevated,
    selectedColor: AppColors.kPrimarySurface,
    labelStyle: AppTextStyles.kLabelLarge,
    side: const BorderSide(color: AppColors.kDivider),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  static final _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.kTextPrimary,
    contentTextStyle: AppTextStyles.kBodyMedium.copyWith(color: Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusSm),
    ),
    behavior: SnackBarBehavior.floating,
  );

  static final _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.kBgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
    ),
  );

  static const _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.kBgSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.kRadiusXl)),
    ),
  );

  static const _dividerTheme = DividerThemeData(
    color: AppColors.kDivider,
    thickness: 1,
  );
}
