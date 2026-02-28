import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
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
  bool sendOtpCalled = false;
  String? capturedPhoneNumber;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase.FirebaseAuthException error)
        onVerificationFailed,
    required void Function(firebase.PhoneAuthCredential credential)
        onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    sendOtpCalled = true;
    capturedPhoneNumber = phoneNumber;
    onCodeSent('test_verification_id', null);
  }

  @override
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<RegisterResult> register({
    String? firstName,
    String? lastName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LoginResult> login() async {
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
              path: '/otp',
              builder: (_, _) =>
                  const Scaffold(body: Text('OTP Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('LoginScreen', () {
    testWidgets('displays title and phone input', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('+225'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('displays subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.text('Entrez votre numéro pour vous connecter.'),
        findsOneWidget,
      );
    });

    testWidgets('displays register link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.text('Pas encore de compte ? S\'inscrire'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for empty phone number', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Veuillez saisir votre numéro de téléphone'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for invalid phone format', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(
        find.text('Numéro invalide. Format : 01/05/07 XX XX XX XX'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid phone and sends OTP', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '0701020304');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(mockRepository.sendOtpCalled, true);
      expect(mockRepository.capturedPhoneNumber, '+2250701020304');
    });

    testWidgets('navigates to OTP screen after successful send',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '0701020304');
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('OTP Screen'), findsOneWidget);
    });

    testWidgets('navigates to register screen on link tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Pas encore de compte ? S\'inscrire'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });

    testWidgets('displays lock icon', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });
}
