import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/tos_screen.dart';

class _MockAuthRepository implements AuthRepository {
  bool shouldFail = false;

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
    throw UnimplementedError();
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
    if (shouldFail) {
      throw Exception('Erreur serveur');
    }
    return TosAcceptanceModel(
      id: 1,
      acceptanceType: type,
      tosVersion: '1.0',
      acceptedAt: DateTime.now(),
    );
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

  Widget createTestWidget({TosProvider? provider}) {
    return ChangeNotifierProvider(
      create: (_) => provider ?? TosProvider(repository: mockRepository),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/tos',
          routes: [
            GoRoute(
              path: '/tos',
              builder: (_, _) => const TosScreen(),
            ),
            GoRoute(
              path: '/kyc',
              builder: (_, _) =>
                  const Scaffold(body: Text('KYC Screen')),
            ),
            GoRoute(
              path: '/register',
              builder: (_, _) =>
                  const Scaffold(body: Text('Register Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('TosScreen', () {
    testWidgets('displays title and CGU content', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text("Conditions Générales d'Utilisation"), findsOneWidget);
      expect(find.textContaining('Article 1'), findsOneWidget);
    });

    testWidgets('displays accept and decline buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text("J'accepte les conditions"), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
    });

    testWidgets('tap accept navigates to KYC', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text("J'accepte les conditions"));
      await tester.pumpAndSettle();

      expect(find.text('KYC Screen'), findsOneWidget);
    });

    testWidgets('tap decline shows blocked view', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Refuser'));
      await tester.pump();

      expect(find.text('Acceptation requise'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('declined view has return to register button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Refuser'));
      await tester.pump();

      expect(find.text("Retour à l'inscription"), findsOneWidget);
    });

    testWidgets('declined view has review conditions button',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Refuser'));
      await tester.pump();

      expect(find.text('Revoir les conditions'), findsOneWidget);
    });

    testWidgets('review conditions returns to normal view', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Refuser'));
      await tester.pump();

      await tester.tap(find.text('Revoir les conditions'));
      await tester.pump();

      expect(find.text("J'accepte les conditions"), findsOneWidget);
    });
  });
}
