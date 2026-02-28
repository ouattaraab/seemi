import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Fake UserCredential — AuthProvider ignores the return value.
class _FakeUserCredential implements firebase.UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock AuthRepository for testing.
class _MockAuthRepository implements AuthRepository {
  bool sendOtpCalled = false;
  bool verifyOtpCalled = false;
  bool registerCalled = false;
  Exception? sendOtpError;
  Exception? verifyOtpError;
  Exception? registerError;
  String? capturedVerificationId;
  String? capturedSmsCode;

  // Simulate Firebase callbacks
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
    if (sendOtpError != null) throw sendOtpError!;
    onCodeSentCallback = onCodeSent;
    onCodeSent('test_verification_id', null);
  }

  @override
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyOtpCalled = true;
    capturedVerificationId = verificationId;
    capturedSmsCode = smsCode;
    if (verifyOtpError != null) throw verifyOtpError!;
    return _FakeUserCredential();
  }

  @override
  Future<RegisterResult> register({
    String? firstName,
    String? lastName,
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
      expect(provider.verificationId, isNull);
    });
  });

  group('AuthProvider.sendOtp', () {
    test('sets loading then completes with verificationId', () async {
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      await provider.sendOtp('+2250701020304');

      expect(mockRepository.sendOtpCalled, true);
      expect(provider.verificationId, 'test_verification_id');
      expect(provider.error, isNull);
      // loading was set true then false via callback
      expect(loadingStates, contains(true));
      expect(provider.isLoading, false);
    });

    test('sets error on failure', () async {
      mockRepository.sendOtpError = Exception('Network error');

      await provider.sendOtp('+2250701020304');

      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.verifyOtp', () {
    test('returns true on success after sendOtp', () async {
      await provider.sendOtp('+2250701020304');

      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final result = await provider.verifyOtp('123456');

      expect(result, true);
      expect(mockRepository.verifyOtpCalled, true);
      expect(mockRepository.capturedVerificationId, 'test_verification_id');
      expect(mockRepository.capturedSmsCode, '123456');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('returns false when no verificationId', () async {
      final result = await provider.verifyOtp('123456');

      expect(result, false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Session expirée'));
    });

    test('returns false on FirebaseAuthException', () async {
      await provider.sendOtp('+2250701020304');
      mockRepository.verifyOtpError = firebase.FirebaseAuthException(
        code: 'invalid-verification-code',
      );

      final result = await provider.verifyOtp('000000');

      expect(result, false);
      expect(provider.error, contains('incorrect'));
      expect(provider.isLoading, false);
    });

    test('returns false on generic error', () async {
      await provider.sendOtp('+2250701020304');
      mockRepository.verifyOtpError = Exception('Unknown error');

      final result = await provider.verifyOtp('123456');

      expect(result, false);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.register', () {
    test('transitions loading → data on success', () async {
      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final success = await provider.register();

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

      final success = await provider.register();

      expect(success, false);
      expect(provider.user, isNull);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });
  });

  group('AuthProvider.clearError', () {
    test('clears error state', () async {
      mockRepository.registerError = Exception('error');
      await provider.register();
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
