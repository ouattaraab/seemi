/// Système de spacing SeeMi — base 8px, optimisé mobile.
///
/// Touch targets minimum 56px pour les CTA principaux.
abstract final class AppSpacing {
  // ─── Spacing (système 8px) ───
  static const double kSpaceXs = 4;
  static const double kSpaceSm = 8;
  static const double kSpaceMd = 16;
  static const double kSpaceLg = 24;
  static const double kSpaceXl = 32;
  static const double kSpace2xl = 48;

  // ─── Corner Radius ───
  static const double kRadiusSm = 8;
  static const double kRadiusButton = 14;
  static const double kRadiusMd = 14;
  static const double kRadiusCta = 16;
  static const double kRadiusLg = 20;
  static const double kRadiusXl = 28;

  // ─── Touch Targets ───
  /// Hauteur minimum des boutons CTA principaux (grands doigts).
  static const double kButtonHeight = 56;

  /// Hauteur des boutons secondaires.
  static const double kButtonHeightSm = 48;

  // ─── Icon Sizes ───
  static const double kIconSizeHero = 80;
  static const double kIconSizeLg = 32;
  static const double kIconSizeMd = 24;

  // ─── Screen Margins ───
  static const double kScreenMargin = 20;
}
