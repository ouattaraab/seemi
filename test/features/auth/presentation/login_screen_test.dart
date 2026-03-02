import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/login_screen.dart';

class _MockAuthRepository implements AuthRepository {
  bool loginCalled = false;
  String? capturedEmailOrPhone;
  String? capturedPassword;
  Exception? loginError;
  bool accountNotFoundError = false;

  @override
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    loginCalled = true;
    capturedEmailOrPhone = emailOrPhone;
    capturedPassword = password;
    if (loginError != null) throw loginError!;
    return const LoginResult(
      user: UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      ),
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
    );
  }

  @override
  Future<void> refreshToken() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> getProfile() async {
    throw UnimplementedError();
  }

  @override
  Future<TosAcceptanceModel> acceptTos({
    required String type,
  }) async {
    throw UnimplementedError();
  }

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
  late _MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = _MockAuthRepository();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(repository: mockRepository),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, _) => const LoginScreen(),
            ),
            GoRoute(
              path: '/register',
              builder: (_, _) =>
                  const Scaffold(body: Text('Register Screen')),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('displays subtitle and Se connecter button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Connectez-vous à votre compte.'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('displays identifier and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('displays register link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Pas encore de compte ?'), findsOneWidget);
      expect(find.text("S'inscrire"), findsOneWidget);
    });

    testWidgets('shows validation error for empty identifier', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Veuillez entrer votre email ou téléphone'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error for empty password', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Fill identifier but not password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'aminata@example.com');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Veuillez entrer votre mot de passe'),
        findsOneWidget,
      );
    });

    testWidgets('navigates to register screen on link tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text("S'inscrire"));
      await tester.tap(find.text("S'inscrire"));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('displays lock icon', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Lock icon is on the password field
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('displays forgot password link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    });
  });
}
