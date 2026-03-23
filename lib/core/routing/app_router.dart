import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/kyc_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/tos_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/login_screen.dart';
import 'package:ppv_app/features/auth/presentation/screens/register_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_preferences_screen.dart';
import 'package:ppv_app/features/design_showcase/presentation/screens/design_showcase_screen.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/content_detail_screen.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/screens/creator_content_detail_screen.dart';
import 'package:ppv_app/features/content/presentation/screens/my_contents_screen.dart';
import 'package:ppv_app/features/content/presentation/screens/upload_screen.dart';
import 'package:ppv_app/features/home/presentation/screens/home_screen.dart';
import 'package:ppv_app/features/payment/data/payment_repository.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';
import 'package:ppv_app/features/payout/presentation/screens/payout_method_screen.dart';
import 'package:ppv_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:ppv_app/features/app_update/presentation/screens/force_update_screen.dart';
import 'package:ppv_app/features/maintenance/presentation/screens/maintenance_screen.dart';
import 'package:ppv_app/features/creator_consents/presentation/screens/creator_consents_screen.dart';
import 'package:ppv_app/features/referral/presentation/screens/referral_screen.dart';
import 'package:ppv_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:ppv_app/features/creator_profile/presentation/creator_profile_provider.dart';
import 'package:ppv_app/features/creator_profile/presentation/screens/creator_profile_screen.dart';
import 'package:ppv_app/features/analytics/presentation/analytics_provider.dart';
import 'package:ppv_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:ppv_app/features/auto_withdrawal/presentation/auto_withdrawal_provider.dart';
import 'package:ppv_app/features/auto_withdrawal/presentation/screens/auto_withdrawal_screen.dart';
import 'package:ppv_app/features/subscription/presentation/screens/fan_pass_screen.dart';
import 'package:ppv_app/features/subscription/presentation/screens/my_subscriptions_screen.dart';
import 'package:ppv_app/features/subscription/presentation/screens/creator_fan_pass_screen.dart';
import 'package:ppv_app/features/affiliate/presentation/screens/affiliate_dashboard_screen.dart';
import 'package:ppv_app/features/custom_requests/presentation/screens/custom_requests_screen.dart';
import 'package:ppv_app/features/messaging/data/messaging_repository.dart';
import 'package:ppv_app/features/messaging/presentation/conversations_provider.dart';
import 'package:ppv_app/features/messaging/presentation/conversation_provider.dart';
import 'package:ppv_app/features/messaging/presentation/screens/conversations_screen.dart';
import 'package:ppv_app/features/messaging/presentation/screens/conversation_screen.dart';
import 'package:ppv_app/features/bundle/data/bundle_repository.dart';
import 'package:ppv_app/features/bundle/presentation/my_bundles_provider.dart';
import 'package:ppv_app/features/bundle/presentation/create_bundle_provider.dart';
import 'package:ppv_app/features/bundle/presentation/screens/my_bundles_screen.dart';
import 'package:ppv_app/features/bundle/presentation/screens/create_bundle_screen.dart';
import 'package:ppv_app/features/bundle/presentation/screens/public_bundle_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_list_screen.dart';
import 'package:ppv_app/features/notifications/presentation/screens/notification_detail_screen.dart';

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
  // MED-07 — La route design-showcase n'est publique qu'en debug pour éviter
  // d'exposer des détails d'UI interne en production.
  static final _publicRoutes = [
    RouteNames.kRouteSplash,
    RouteNames.kRouteOnboarding,
    RouteNames.kRouteLogin,
    RouteNames.kRouteRegister,
    if (kDebugMode) RouteNames.kRouteDesignShowcase,
    RouteNames.kRouteForgotPassword,
    RouteNames.kRouteResetPassword,
    RouteNames.kRouteMaintenance,
    RouteNames.kRouteForceUpdate,
    RouteNames.kRouteCreatorProfile,
    RouteNames.kRouteBundlePublic,
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
        path: RouteNames.kRouteResetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          // MED-06 — Validation stricte du format token (alphanumérique ≥ 32 chars)
          // et email (doit contenir @ avec un domaine non vide).
          final tokenValid = RegExp(r'^[A-Za-z0-9]{32,}$').hasMatch(token);
          final emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
          if (!tokenValid || !emailValid) {
            return const ForgotPasswordScreen();
          }
          return ResetPasswordScreen(token: token, email: email);
        },
      ),
      GoRoute(
        path: RouteNames.kRouteChangePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteNotificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteMyContents,
        builder: (context, state) => const MyContentsScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteCreatorContentDetail,
        builder: (context, state) {
          final content = state.extra as Content;
          return CreatorContentDetailScreen(content: content);
        },
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
      GoRoute(
        path: RouteNames.kRouteReferral,
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteMaintenance,
        builder: (context, state) =>
            MaintenanceScreen(data: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: RouteNames.kRouteForceUpdate,
        builder: (context, state) =>
            ForceUpdateScreen(data: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: RouteNames.kRouteCreatorConsents,
        builder: (context, state) => const CreatorConsentsScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteCreatorProfile,
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ChangeNotifierProvider(
            create: (_) => CreatorProfileProvider(username: username),
            child: CreatorProfileScreen(username: username),
          );
        },
      ),
      GoRoute(
        path: RouteNames.kRouteAnalytics,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(),
          child: const AnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteAutoWithdrawal,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AutoWithdrawalProvider(),
          child: const AutoWithdrawalScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteFanPass,
        builder: (context, state) => FanPassScreen(
          // LOW-01 — tryParse to avoid crash on invalid path param
          creatorId: int.tryParse(state.pathParameters['creatorId'] ?? '') ?? 0,
          creatorName: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteAffiliate,
        builder: (context, state) => const AffiliateDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteCustomRequests,
        builder: (context, state) => const CustomRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteCreatorFanPass,
        builder: (context, state) => const CreatorFanPassScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteMySubscriptions,
        builder: (context, state) => const MySubscriptionsScreen(),
      ),
      // ── F14: Direct Messaging ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.kRouteConversations,
        builder: (context, state) => ChangeNotifierProvider(
          // MED-05 — Use shared MessagingRepository (with session/maintenance callbacks)
          create: (_) => ConversationsProvider(
            repo: context.read<MessagingRepository>(),
          ),
          child: const ConversationsScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteConversation,
        builder: (context, state) {
          // LOW-01 — Use tryParse to avoid crash on invalid path param
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChangeNotifierProvider(
            create: (_) => ConversationProvider(
              conversationId: id,
              repo: context.read<MessagingRepository>(),
            ),
            child: ConversationScreen(conversationId: id),
          );
        },
      ),
      // ── F12: Content Bundles ───────────────────────────────────────────────
      GoRoute(
        path: RouteNames.kRouteMyBundles,
        builder: (context, state) => ChangeNotifierProvider(
          create: (ctx) => MyBundlesProvider(
            repository: ctx.read<BundleRepository>(),
          ),
          child: const MyBundlesScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteBundleCreate,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CreateBundleProvider(),
          child: const CreateBundleScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.kRouteBundlePublic,
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          final paymentRef = state.uri.queryParameters['reference'] ??
              state.uri.queryParameters['trxref'];
          return PublicBundleScreen(slug: slug, paymentReference: paymentRef);
        },
      ),
      // ── Notifications / Messages ───────────────────────────────────────────
      GoRoute(
        path: RouteNames.kRouteMessages,
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: RouteNames.kRouteNotificationDetail,
        builder: (context, state) {
          // LOW-01 — Use tryParse to avoid crash on invalid path param
          final id =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return NotificationDetailScreen(notificationId: id);
        },
      ),
    ],
  );

  Future<String?> _globalRedirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    // Les routes /c/*, /profile/* et /b/* sont publiques (deep linking)
    final isPublicRoute = _publicRoutes.contains(state.matchedLocation) ||
        state.uri.path.startsWith('/c/') ||
        state.uri.path.startsWith('/profile/') ||
        state.uri.path.startsWith('/b/');
    if (isPublicRoute) return null;

    final hasToken = await _storageService.hasTokens();
    if (!hasToken) return RouteNames.kRouteLogin;

    return null;
  }
}
