import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

class _MockAuthRepository implements AuthRepository {
  bool loginCalled = false;
  bool logoutCalled = false;
  Exception? loginError;
  Exception? logoutError;

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
    if (loginError != null) throw loginError!;
    return const LoginResult(
      user: UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'none',
        acceptedTosAt: null,
        tosVersion: null,
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
    logoutCalled = true;
    if (logoutError != null) throw logoutError!;
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
  late AuthProvider provider;

  setUp(() {
    mockRepository = _MockAuthRepository();
    provider = AuthProvider(repository: mockRepository);
  });

  group('AuthProvider.login', () {
    test('transitions loading → data on success', () async {
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final success = await provider.login(
        emailOrPhone: 'aminata@example.com',
        password: 'password123',
      );

      expect(success, true);
      expect(mockRepository.loginCalled, true);
      expect(provider.user, isNotNull);
      expect(provider.user!.phone, '+2250701020304');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.accountNotFound, false);
      expect(loadingStates.first, true);
    });

    test('sets accountNotFound on ACCOUNT_NOT_FOUND error', () async {
      mockRepository.loginError = const AuthApiException(
        message: 'Aucun compte associé',
        code: 'ACCOUNT_NOT_FOUND',
      );

      final success = await provider.login(
        emailOrPhone: 'unknown@example.com',
        password: 'password123',
      );

      expect(success, false);
      expect(provider.accountNotFound, true);
      expect(provider.error, contains('trouvé'));
      expect(provider.isLoading, false);
    });

    test('sets error on INVALID_PASSWORD', () async {
      mockRepository.loginError = const AuthApiException(
        message: 'Mot de passe incorrect',
        code: 'INVALID_PASSWORD',
      );

      final success = await provider.login(
        emailOrPhone: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(success, false);
      expect(provider.accountNotFound, false);
      expect(provider.error, contains('Mot de passe'));
      expect(provider.isLoading, false);
    });

    test('sets error on other AuthApiException', () async {
      mockRepository.loginError = const AuthApiException(
        message: 'Compte désactivé',
        code: 'ACCOUNT_DISABLED',
      );

      final success = await provider.login(
        emailOrPhone: 'test@example.com',
        password: 'password123',
      );

      expect(success, false);
      expect(provider.accountNotFound, false);
      expect(provider.error, 'Compte désactivé');
      expect(provider.isLoading, false);
    });

    test('sets generic error on unknown exception', () async {
      mockRepository.loginError = Exception('Network error');

      final success = await provider.login(
        emailOrPhone: 'test@example.com',
        password: 'password123',
      );

      expect(success, false);
      expect(provider.error, contains('connexion'));
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.logout', () {
    test('clears user and state on success', () async {
      // First login to have a user
      await provider.login(
        emailOrPhone: 'aminata@example.com',
        password: 'password123',
      );
      expect(provider.user, isNotNull);

      await provider.logout();

      expect(mockRepository.logoutCalled, true);
      expect(provider.user, isNull);
      expect(provider.accountNotFound, false);
      expect(provider.isLoading, false);
    });

    test('clears state even on logout error', () async {
      await provider.login(
        emailOrPhone: 'aminata@example.com',
        password: 'password123',
      );
      mockRepository.logoutError = Exception('Server error');

      await provider.logout();

      expect(provider.user, isNull);
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.clearError (login)', () {
    test('clears accountNotFound flag', () async {
      mockRepository.loginError = const AuthApiException(
        message: 'Not found',
        code: 'ACCOUNT_NOT_FOUND',
      );
      await provider.login(
        emailOrPhone: 'unknown@example.com',
        password: 'password123',
      );
      expect(provider.accountNotFound, true);

      provider.clearError();

      expect(provider.accountNotFound, false);
      expect(provider.error, isNull);
    });
  });

  group('AuthProvider.dispose (login)', () {
    test('does not throw when calling clearError after dispose', () async {
      provider.dispose();
      // Should not throw after dispose
      expect(() => provider.clearError(), returnsNormally);
    });
  });
}
