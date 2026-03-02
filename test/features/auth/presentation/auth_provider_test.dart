import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Mock AuthRepository for testing register flow.
class _MockAuthRepository implements AuthRepository {
  bool registerCalled = false;
  Exception? registerError;

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
    if (registerError != null) throw registerError!;
    return const RegisterResult(
      user: UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Test',
        lastName: 'User',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      ),
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
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

  group('AuthProvider initial state', () {
    test('starts with loading false, error null, user null', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.user, isNull);
    });
  });

  group('AuthProvider.register', () {
    test('transitions loading → data on success', () async {
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final success = await provider.register(
        firstName: 'Test',
        lastName: 'User',
        phone: '+2250701020304',
        email: 'test@example.com',
        dateOfBirth: '2000-01-01',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(success, true);
      expect(mockRepository.registerCalled, true);
      expect(provider.user, isNotNull);
      expect(provider.user!.phone, '+2250701020304');
      expect(provider.user!.role, 'creator');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(loadingStates.first, true); // loading set first
    });

    test('transitions loading → error on failure', () async {
      mockRepository.registerError = Exception('API error');

      final success = await provider.register(
        firstName: 'Test',
        lastName: 'User',
        phone: '+2250701020304',
        email: 'test@example.com',
        dateOfBirth: '2000-01-01',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(success, false);
      expect(provider.user, isNull);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.clearError', () {
    test('clears error state', () async {
      mockRepository.registerError = Exception('error');
      await provider.register(
        firstName: 'Test',
        lastName: 'User',
        phone: '+2250701020304',
        email: 'test@example.com',
        dateOfBirth: '2000-01-01',
        password: 'password123',
        passwordConfirmation: 'password123',
      );
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('AuthProvider.dispose', () {
    test('does not throw when notifying after dispose', () async {
      provider.dispose();
      // Should not throw after dispose
      expect(() => provider.clearError(), returnsNormally);
    });
  });
}
