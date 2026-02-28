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
import 'package:ppv_app/features/auth/presentation/screens/register_screen.dart';

class _MockAuthRepository implements AuthRepository {
  bool sendOtpCalled = false;

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
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (_, _) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/otp',
              builder: (_, _) => const Scaffold(body: Text('OTP Screen')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) => const Scaffold(body: Text('Login Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('RegisterScreen', () {
    testWidgets('displays title and phone input', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Créez votre compte'), findsOneWidget);
      expect(find.text('+225'), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });

    testWidgets('displays login link', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(
        find.text('Déjà un compte ? Se connecter'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for empty phone number', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(
        find.text('Veuillez saisir votre numéro de téléphone'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for invalid phone format', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(
        find.text('Numéro invalide. Format : 01/05/07 XX XX XX XX'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid Orange CI number (01)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '0102030405');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(mockRepository.sendOtpCalled, true);
    });

    testWidgets('accepts valid MTN CI number (05)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '0502030405');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(mockRepository.sendOtpCalled, true);
    });

    testWidgets('accepts valid Moov CI number (07)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '0702030405');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pumpAndSettle();

      expect(mockRepository.sendOtpCalled, true);
    });
  });
}
