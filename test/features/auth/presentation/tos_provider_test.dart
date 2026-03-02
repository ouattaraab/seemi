import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';

class _MockAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String failMessage = 'Erreur serveur';
  int acceptTosCallCount = 0;

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
    acceptTosCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
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
  late TosProvider provider;

  setUp(() {
    mockRepository = _MockAuthRepository();
    provider = TosProvider(repository: mockRepository);
  });

  // Provider is auto-disposed by tests that dispose it; no global tearDown needed.

  group('TosProvider', () {
    test('initial state is correct', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.tosAccepted, false);
      expect(provider.tosDeclined, false);
      expect(provider.lastAcceptance, isNull);
    });

    test('acceptTos success sets tosAccepted to true', () async {
      final result = await provider.acceptTos('registration');

      expect(result, true);
      expect(provider.tosAccepted, true);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.lastAcceptance, isNotNull);
      expect(provider.lastAcceptance!.acceptanceType, 'registration');
    });

    test('acceptTos failure sets error', () async {
      mockRepository.shouldFail = true;
      mockRepository.failMessage = 'Connexion impossible';

      final result = await provider.acceptTos('registration');

      expect(result, false);
      expect(provider.tosAccepted, false);
      expect(provider.isLoading, false);
      expect(provider.error, contains('Connexion impossible'));
    });

    test('declineTos sets tosDeclined and blocks access', () {
      provider.declineTos();

      expect(provider.tosDeclined, true);
      expect(provider.tosAccepted, false);
    });

    test('clearError resets error state', () async {
      mockRepository.shouldFail = true;
      await provider.acceptTos('registration');

      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });

    test('reset clears all state', () async {
      await provider.acceptTos('registration');
      expect(provider.tosAccepted, true);

      provider.reset();

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.tosAccepted, false);
      expect(provider.tosDeclined, false);
      expect(provider.lastAcceptance, isNull);
    });

    test('acceptTos calls repository with correct type', () async {
      await provider.acceptTos('login');

      expect(mockRepository.acceptTosCallCount, 1);
      expect(provider.lastAcceptance!.acceptanceType, 'login');
    });

    test('safeNotify does not throw after dispose', () {
      // Create a separate provider that we manually dispose
      final disposableProvider = TosProvider(repository: mockRepository);
      disposableProvider.dispose();

      // Calling declineTos after dispose should not throw
      // (it calls _safeNotify which checks _disposed)
      expect(() => disposableProvider.declineTos(), returnsNormally);
    });
  });
}
