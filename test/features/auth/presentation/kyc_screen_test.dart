import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/kyc_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/kyc_screen.dart';
import 'package:ppv_app/features/auth/presentation/widgets/kyc_step_indicator.dart';

class _MockAuthRepository implements AuthRepository {
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
  Future<UserModel> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    return const UserModel(
      id: 1,
      phone: '+2250701020304',
      firstName: 'Aminata',
      lastName: 'Koné',
      role: 'creator',
      kycStatus: 'pending',
      isActive: true,
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
      create: (_) => KycProvider(repository: mockRepository),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/kyc',
          routes: [
            GoRoute(
              path: '/kyc',
              builder: (_, _) => const KycScreen(),
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

  Widget createTestWidgetWithProvider(KycProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/kyc',
          routes: [
            GoRoute(
              path: '/kyc',
              builder: (_, _) => const KycScreen(),
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

  group('KycScreen - Step 1', () {
    testWidgets('displays KYC title and step indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Vérification KYC'), findsOneWidget);
      expect(find.byType(KycStepIndicator), findsOneWidget);
    });

    testWidgets('step 1 displays personal info fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Informations personnelles'), findsOneWidget);
      expect(find.text('Prénom'), findsOneWidget);
      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Date de naissance'), findsOneWidget);
      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('step 1 shows error for empty fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Continuer'));
      await tester.pump();

      expect(find.textContaining('prénom'), findsOneWidget);
    });

    testWidgets('displays 3 TextFields in step 1', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Prénom, Nom, Date de naissance (AbsorbPointer)
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('displays Continuer button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Continuer'), findsOneWidget);
    });
  });

  group('KycScreen - Step 2', () {
    testWidgets('step 2 displays document upload UI', (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));

      expect(find.text("Pièce d'identité"), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Galerie'), findsOneWidget);
      expect(find.text('Aucune image sélectionnée'), findsOneWidget);
    });

    testWidgets('step 2 Continuer button disabled without document',
        (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('step 2 shows back button', (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('KycScreen - Step 3', () {
    testWidgets('step 3 displays summary', (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();
      provider.setDocument(File('/fake/path/id.jpg'));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));

      expect(find.text('Récapitulatif'), findsOneWidget);
      expect(find.text('Aminata'), findsOneWidget);
      expect(find.text('Koné'), findsOneWidget);
      expect(find.text('15/03/2000'), findsOneWidget);
      expect(find.text('Soumettre ma vérification'), findsOneWidget);
    });

    testWidgets('step 3 submit button label is correct', (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();
      provider.setDocument(File('/fake/path/id.jpg'));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));

      expect(find.text('Soumettre ma vérification'), findsOneWidget);
    });
  });

  group('KycScreen - Navigation', () {
    testWidgets('step 1 has no back button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('back button on step 2 returns to step 1', (tester) async {
      final provider = KycProvider(repository: mockRepository);
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.nextStep();

      await tester.pumpWidget(createTestWidgetWithProvider(provider));
      expect(find.text("Pièce d'identité"), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(find.text('Informations personnelles'), findsOneWidget);
    });
  });
}
