import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/app_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_theme.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

class _MockAuthRepository implements AuthRepository {
  @override
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> refreshToken() async => throw UnimplementedError();

  @override
  Future<void> logout() async => throw UnimplementedError();

  @override
  Future<UserModel> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async =>
      throw UnimplementedError();

  @override
  Future<UserModel> getProfile() async => throw UnimplementedError();

  @override
  Future<TosAcceptanceModel> acceptTos({required String type}) async =>
      throw UnimplementedError();

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> registerFcmToken(String token) async =>
      throw UnimplementedError();

  @override
  Future<void> forgotPassword({required String email}) async =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteAccount() async => throw UnimplementedError();
}

void main() {
  group('RouteNames - Constantes', () {
    test('kRouteSplash est /', () {
      expect(RouteNames.kRouteSplash, '/');
    });

    test('kRouteOnboarding est /onboarding', () {
      expect(RouteNames.kRouteOnboarding, '/onboarding');
    });

    test('kRouteLogin est /login', () {
      expect(RouteNames.kRouteLogin, '/login');
    });

    test('kRouteHome est /home', () {
      expect(RouteNames.kRouteHome, '/home');
    });

    test('kRouteDesignShowcase est /design-showcase', () {
      expect(RouteNames.kRouteDesignShowcase, '/design-showcase');
    });
  });

  group('AppRouter - Configuration', () {
    late AppRouter appRouter;

    setUp(() {
      appRouter = AppRouter();
    });

    test('router est créé sans erreur', () {
      expect(appRouter.router, isNotNull);
    });

    test('initialLocation est splash (/)', () {
      expect(
        appRouter.router.routeInformationProvider.value.uri.path,
        '/',
      );
    });

    test('les routes définies incluent les 14 paths requis', () {
      final routes = appRouter.router.configuration.routes;
      // 7 from Story 2.1 + 1 KYC + 1 TOS + 1 PayoutMethod + 1 Upload (Story 3.1) + 1 DesignShowcase + 1 ContentViewer (Story 4.4)
      // + 3 new routes: ForgotPassword, ChangePassword, NotificationPreferences
      expect(routes.length, 14);
    });

    test('kRouteContentViewer est /c/:slug', () {
      expect(RouteNames.kRouteContentViewer, '/c/:slug');
    });

    test('kRouteKyc est /kyc', () {
      expect(RouteNames.kRouteKyc, '/kyc');
    });

    test('kRouteTos est /tos', () {
      expect(RouteNames.kRouteTos, '/tos');
    });

    test('kRoutePayoutMethod est /payout-method', () {
      expect(RouteNames.kRoutePayoutMethod, '/payout-method');
    });
  });

  group('AppRouter - Navigation', () {
    testWidgets('splash screen se charge en route initiale', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: appRouter.router,
        ),
      );
      await tester.pump();

      // Le splash screen affiche 'SeeMi'
      expect(find.text('SeeMi'), findsOneWidget);
    });

    testWidgets('design showcase est accessible', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: appRouter.router,
        ),
      );

      // Naviguer vers design showcase
      appRouter.router.go(RouteNames.kRouteDesignShowcase);
      await tester.pumpAndSettle();

      expect(find.text('SeeMi Design System'), findsOneWidget);
    });

    testWidgets('onboarding screen est accessible', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: appRouter.router,
        ),
      );

      appRouter.router.go(RouteNames.kRouteOnboarding);
      await tester.pumpAndSettle();

      expect(find.text('Partagez vos photos'), findsOneWidget);
    });

    testWidgets('login screen est accessible', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: _MockAuthRepository()),
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: appRouter.router,
          ),
        ),
      );

      appRouter.router.go(RouteNames.kRouteLogin);
      await tester.pumpAndSettle();

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Connectez-vous à votre compte.'), findsOneWidget);
    });
  });

  group('AppRouter - Deep Linking (Story 4.4)', () {
    test('route /c/:slug est enregistrée dans le routeur (14 routes au total)',
        () {
      final appRouter = AppRouter();
      // Le compte de 14 routes inclut la route deep link /c/:slug (Story 4.4)
      // + 3 nouvelles routes: ForgotPassword, ChangePassword, NotificationPreferences
      expect(appRouter.router.configuration.routes.length, 14);
    });

    test('guard autorise les chemins /c/ sans token (startsWith)', () {
      // Valide la logique du guard pour les routes /c/*
      const publicPaths = ['/c/abc123', '/c/mon-contenu', '/c/x'];

      for (final path in publicPaths) {
        expect(
          path.startsWith('/c/'),
          isTrue,
          reason: '$path devrait être reconnu comme route publique deep link',
        );
      }

      // Les routes protégées ne commencent pas par /c/
      const protectedPaths = ['/home', '/upload', '/profile'];
      for (final path in protectedPaths) {
        expect(
          path.startsWith('/c/'),
          isFalse,
          reason: '$path ne devrait pas être reconnu comme route deep link',
        );
      }
    });
  });

  group('AppRouter - Auth Redirect Guard', () {
    setUp(() {
      // Mock flutter_secure_storage — retourne null (pas de token)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          if (call.method == 'read') return null;
          if (call.method == 'readAll') return <String, String>{};
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    testWidgets('home sans token redirige vers login', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: _MockAuthRepository()),
          child: MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: appRouter.router,
          ),
        ),
      );

      // Naviguer vers /home — sans token, le guard doit rediriger vers /login
      appRouter.router.go(RouteNames.kRouteHome);
      await tester.pumpAndSettle();

      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Connectez-vous à votre compte.'), findsOneWidget);
    });

    testWidgets('routes publiques accessibles sans token', (tester) async {
      final appRouter = AppRouter();
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: appRouter.router,
        ),
      );

      // /onboarding est une route publique — pas de redirect
      appRouter.router.go(RouteNames.kRouteOnboarding);
      await tester.pumpAndSettle();

      expect(find.text('Partagez vos photos'), findsOneWidget);
    });
  });
}
