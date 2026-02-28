import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/profile_screen.dart';

class _MockAuthRepository implements AuthRepository {
  UserModel? profileToReturn;
  UserModel? updatedProfileToReturn;
  Exception? getProfileError;
  Exception? updateProfileError;
  bool updateProfileCalled = false;
  bool logoutCalled = false;
  Completer<UserModel>? getProfileCompleter;

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
  Future<RegisterResult> register({String? firstName, String? lastName}) async {
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
    logoutCalled = true;
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
    if (getProfileCompleter != null) return getProfileCompleter!.future;
    if (getProfileError != null) throw getProfileError!;
    return profileToReturn ??
        const UserModel(
          id: 1,
          phone: '+2250701020304',
          firstName: 'Aminata',
          lastName: 'Koné',
          role: 'creator',
          kycStatus: 'approved',
          isActive: true,
        );
  }

  @override
  Future<TosAcceptanceModel> acceptTos({required String type}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    updateProfileCalled = true;
    if (updateProfileError != null) throw updateProfileError!;
    return updatedProfileToReturn ??
        UserModel(
          id: 1,
          phone: '+2250701020304',
          firstName: firstName ?? 'Aminata',
          lastName: lastName ?? 'Koné',
          role: 'creator',
          kycStatus: 'approved',
          isActive: true,
        );
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
      create: (_) => ProfileProvider(repository: mockRepository),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Scaffold(body: ProfileScreen()),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('displays user name, phone, and avatar placeholder',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aminata Koné'), findsOneWidget);
      expect(find.text('+2250701020304'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays KYC approved badge', (tester) async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'approved',
        isActive: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('KYC vérifié'), findsOneWidget);
    });

    testWidgets('displays KYC pending badge', (tester) async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'pending',
        isActive: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('KYC en attente'), findsOneWidget);
    });

    testWidgets('displays Modifier le profil button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Modifier le profil'), findsOneWidget);
    });

    testWidgets('tapping Modifier opens edit form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();

      // Form fields should appear
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
    });

    testWidgets('phone field is disabled in edit mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();

      // Find phone TextFormField — it should be disabled
      final phoneFinder = find.widgetWithText(TextFormField, '+2250701020304');
      expect(phoneFinder, findsOneWidget);

      final phoneField = tester.widget<TextFormField>(phoneFinder);
      expect(phoneField.enabled, false);
    });

    testWidgets('submitting form calls updateProfile', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();

      // Tap Enregistrer
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(mockRepository.updateProfileCalled, true);
    });

    testWidgets('shows success SnackBar after update', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Profil mis à jour avec succès'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on update failure', (tester) async {
      mockRepository.updateProfileError = Exception('Server error');

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur lors de la mise à jour du profil.'),
          findsOneWidget);
    });

    testWidgets('shows loading indicator when profile is loading',
        (tester) async {
      // Hold the future open so loading state is observable
      mockRepository.getProfileCompleter = Completer<UserModel>();

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // triggers addPostFrameCallback → loadProfile()
      await tester.pump(); // rebuild with isLoading=true

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid dangling future
      mockRepository.getProfileCompleter!.complete(const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'approved',
        isActive: true,
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('Annuler button exits edit mode', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.text('Modifier le profil'));
      await tester.pump();
      expect(find.text('Enregistrer'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Annuler'));
      await tester.pump();

      // Back to view mode
      expect(find.text('Modifier le profil'), findsOneWidget);
      expect(find.text('Enregistrer'), findsNothing);
    });

    testWidgets('Déconnexion button is present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Déconnexion'), findsOneWidget);
    });

    testWidgets('tapping Déconnexion calls logout and navigates to login',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Déconnexion'));
      await tester.pumpAndSettle();

      expect(mockRepository.logoutCalled, true);
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('displays fallback name when names are null', (tester) async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: null,
        lastName: null,
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Utilisateur'), findsOneWidget);
    });
  });
}
