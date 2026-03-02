import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/kyc_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/tos_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_preferences_screen.dart';
import 'package:ppv_app/features/design_showcase/presentation/screens/design_showcase_screen.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/content_detail_screen.dart';
import 'package:ppv_app/features/content/presentation/screens/upload_screen.dart';
import 'package:ppv_app/features/home/presentation/screens/home_screen.dart';
import 'package:ppv_app/features/payment/data/payment_repository.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';
import 'package:ppv_app/features/payout/presentation/screens/payout_method_screen.dart';
import 'package:ppv_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ppv_app/features/splash/presentation/screens/splash_screen.dart';

/// Configuration GoRouter PPV — routes déclaratives + guard d'auth.
///
/// Le redirect global vérifie l'authentification via SecureStorageService.
/// Les routes publiques (splash, onboarding, login, register, otp, design-showcase)
/// sont accessibles sans token.
class AppRouter {
  final SecureStorageService _storageService;

  AppRouter({SecureStorageService? storageService})
      : _storageService = storageService ?? const SecureStorageService();

  /// Routes qui ne nécessitent pas d'authentification.
  static const _publicRoutes = [
    RouteNames.kRouteSplash,
    RouteNames.kRouteOnboarding,
    RouteNames.kRouteLogin,
    RouteNames.kRouteRegister,
    RouteNames.kRouteDesignShowcase,
    RouteNames.kRouteForgotPassword,
    RouteNames.kRouteResetPassword,
  ];

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.kRouteSplash,
    redirect: _globalRedirect,
    routes: [
      GoRoute(
        path: RouteNames.kRouteSplash,
        builder: (context, state) =>
            SplashScreen(storageService: _storageService),
      ),
      GoRoute(
        path: RouteNames.kRouteOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteRegister,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteTos,
        builder: (context, state) => const TosScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteKyc,
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        path: RouteNames.kRoutePayoutMethod,
        builder: (context, state) => const PayoutMethodScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteUpload,
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteDesignShowcase,
        builder: (context, state) => const DesignShowcaseScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteForgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteChangePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteNotificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      // Deep linking — route publique (acheteurs sans compte)
      // ?reference= et ?trxref= sont les params Paystack de callback
      GoRoute(
        path: RouteNames.kRouteContentViewer,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          // Paystack ajoute ?reference= et/ou ?trxref= lors du redirect après paiement
          final paymentRef = state.uri.queryParameters['reference'] ??
              state.uri.queryParameters['trxref'];
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ContentDetailProvider(
                  slug: slug,
                  repository: PublicContentRepository(),
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => PaymentProvider(
                  repository: PaymentRepository(),
                ),
              ),
            ],
            child: ContentDetailScreen(paymentReference: paymentRef),
          );
        },
      ),
    ],
  );

  Future<String?> _globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Les routes /c/* sont publiques (deep linking acheteurs sans compte)
    final isPublicRoute = _publicRoutes.contains(state.matchedLocation) ||
        state.uri.path.startsWith('/c/');
    if (isPublicRoute) return null;

    final hasToken = await _storageService.hasTokens();
    if (!hasToken) return RouteNames.kRouteLogin;

    return null;
  }
}
