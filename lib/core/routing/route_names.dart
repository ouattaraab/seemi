/// Constantes de noms de routes PPV.
///
/// Utiliser ces constantes au lieu de strings hardcodées.
abstract final class RouteNames {
  static const String kRouteSplash = '/';
  static const String kRouteOnboarding = '/onboarding';
  static const String kRouteLogin = '/login';
  static const String kRouteRegister = '/register';
  static const String kRouteOtp = '/otp';
  static const String kRouteTos = '/tos';
  static const String kRouteKyc = '/kyc';
  static const String kRoutePayoutMethod = '/payout-method';
  static const String kRouteHome = '/home';
  static const String kRouteUpload = '/upload';
  static const String kRouteDesignShowcase = '/design-showcase';
  static const String kRouteContentViewer = '/c/:slug';
  static const String kRouteForgotPassword = '/forgot-password';
  static const String kRouteResetPassword = '/reset-password';
  static const String kRouteChangePassword = '/change-password';
  static const String kRouteNotificationPreferences = '/notification-preferences';
  static const String kRouteMyContents = '/my-contents';
  static const String kRouteCreatorContentDetail = '/creator/contents/:id';

  /// Helper pour construire l'URL de détail créateur avec un id concret.
  static String creatorContentDetail(int id) => '/creator/contents/$id';

  static const String kRouteReferral = '/referral';
  static const String kRouteMaintenance     = '/maintenance';
  static const String kRouteForceUpdate     = '/update';
  static const String kRouteCreatorConsents = '/creator-consents';

  static const String kRouteCreatorProfile = '/profile/:username';

  /// Helper pour construire l'URL du profil public d'un créateur.
  static String creatorProfile(String username) => '/profile/$username';

  static const String kRouteAnalytics = '/analytics';

  static const String kRouteAutoWithdrawal = '/auto-withdrawal';

  static const String kRouteFanPass = '/fan-pass/:creatorId';

  /// Helper pour construire l'URL Fan Pass d'un créateur avec son id.
  static String fanPass(int creatorId) => '/fan-pass/$creatorId';

  static const String kRouteAffiliate = '/affiliate';

  static const String kRouteCustomRequests = '/custom-requests';

  static const String kRouteMySubscriptions = '/my-subscriptions';

  // ── F14: Direct Messaging ────────────────────────────────────────────────────
  static const String kRouteConversations = '/conversations';
  static const String kRouteConversation  = '/conversations/:id';

  /// Helper pour construire l'URL d'une conversation avec son id concret.
  static String conversation(int id) => '/conversations/$id';

  // ── F12: Content Bundles ─────────────────────────────────────────────────────
  static const String kRouteMyBundles   = '/my-bundles';
  static const String kRouteBundleCreate = '/bundles/create';
  static const String kRouteBundlePublic = '/b/:slug';

  /// Helper pour construire l'URL publique d'un bundle avec son slug.
  static String bundlePublic(String slug) => '/b/$slug';
}
