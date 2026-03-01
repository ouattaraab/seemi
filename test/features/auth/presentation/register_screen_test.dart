import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/register_screen.dart';

class _MockAuthRepository implements AuthRepository {
  bool registerCalled = false;

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
    registerCalled = true;
    return const RegisterResult(
      user: UserModel(
        id: 1,
        phone: '+2250701020304',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      ),
      accessToken: 'token',
      refreshToken: 'refresh',
    );
  }

  @override
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    throw UnimplementedError();
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
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (_, _) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('Login Screen')),
            ),
            GoRoute(
              path: '/tos',
              builder: (_, _) => const Scaffold(body: Text('TOS Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Rejoignez SeeMi et monétisez vos contenus.'), findsOneWidget);
    });

    testWidgets('displays S\'inscrire button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text("S'inscrire"), findsOneWidget);
    });

    testWidgets('displays login link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Déjà un compte ?'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('navigates to login screen on link tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('shows form fields for email and password', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Multiple TextFormField/TextField inputs expected
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
