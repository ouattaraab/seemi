import 'dart:io';

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
  bool logoutCalled = false;

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
    testWidgets('displays user name and phone', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aminata Koné'), findsOneWidget);
      expect(find.text('+2250701020304'), findsOneWidget);
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

      // label.toUpperCase() renders 'Pro Créateur' as 'PRO CRÉATEUR'
      expect(find.text('PRO CRÉATEUR'), findsOneWidget);
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

      // label.toUpperCase() renders 'KYC en attente' as 'KYC EN ATTENTE'
      expect(find.text('KYC EN ATTENTE'), findsOneWidget);
    });

    testWidgets('displays Se déconnecter button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Se déconnecter'), findsOneWidget);
    });

    testWidgets('tapping Se déconnecter calls logout and navigates to login',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Se déconnecter'));
      await tester.tap(find.text('Se déconnecter'));
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

    testWidgets('displays menu items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe & Sécurité'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });
}
