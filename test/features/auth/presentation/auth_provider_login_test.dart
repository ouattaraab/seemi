import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

class _FakeUserCredential implements firebase.UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockAuthRepository implements AuthRepository {
  bool loginCalled = false;
  bool logoutCalled = false;
  bool sendOtpCalled = false;
  Exception? loginError;
  Exception? logoutError;

  void Function(String, int?)? onCodeSentCallback;

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
    onCodeSentCallback = onCodeSent;
    onCodeSent('test_verification_id', null);
  }

  @override
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    return _FakeUserCredential();
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
}

void main() {
  late _MockAuthRepository mockRepository;
  late AuthProvider provider;

  setUp(() {
    mockRepository = _MockAuthRepository();
    provider = AuthProvider(repository: mockRepository);
  });

  group('AuthProvider.loginSendOtp', () {
    test('sets isLoginFlow to true and sends OTP', () async {
      await provider.loginSendOtp('+2250701020304');

      expect(provider.isLoginFlow, true);
      expect(mockRepository.sendOtpCalled, true);
      expect(provider.verificationId, 'test_verification_id');
      expect(provider.accountNotFound, false);
    });
  });

  group('AuthProvider.loginAfterOtp', () {
    test('transitions loading → data on success', () async {
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final success = await provider.loginAfterOtp();

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

      final success = await provider.loginAfterOtp();

      expect(success, false);
      expect(provider.accountNotFound, true);
      expect(provider.error, contains('inscrire'));
      expect(provider.isLoading, false);
    });

    test('sets error on other AuthApiException', () async {
      mockRepository.loginError = const AuthApiException(
        message: 'Compte désactivé',
        code: 'ACCOUNT_DISABLED',
      );

      final success = await provider.loginAfterOtp();

      expect(success, false);
      expect(provider.accountNotFound, false);
      expect(provider.error, 'Compte désactivé');
      expect(provider.isLoading, false);
    });

    test('sets generic error on unknown exception', () async {
      mockRepository.loginError = Exception('Network error');

      final success = await provider.loginAfterOtp();

      expect(success, false);
      expect(provider.error, contains('connexion'));
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.logout', () {
    test('clears user and state on success', () async {
      // First login to have a user
      await provider.loginAfterOtp();
      expect(provider.user, isNotNull);

      await provider.logout();

      expect(mockRepository.logoutCalled, true);
      expect(provider.user, isNull);
      expect(provider.isLoginFlow, false);
      expect(provider.accountNotFound, false);
      expect(provider.isLoading, false);
    });

    test('clears state even on logout error', () async {
      await provider.loginAfterOtp();
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
      await provider.loginAfterOtp();
      expect(provider.accountNotFound, true);

      provider.clearError();

      expect(provider.accountNotFound, false);
      expect(provider.error, isNull);
    });
  });

  group('AuthProvider.dispose (login)', () {
    test('does not throw when calling loginAfterOtp after dispose', () async {
      provider.dispose();
      // Should not throw after dispose
      final result = await provider.loginAfterOtp();
      expect(result, true);
    });
  });
}
