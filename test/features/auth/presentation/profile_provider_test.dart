import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';

class _MockAuthRepository implements AuthRepository {
  bool getProfileCalled = false;
  bool updateProfileCalled = false;
  bool logoutCalled = false;
  UserModel? profileToReturn;
  UserModel? updatedProfileToReturn;
  Exception? getProfileError;
  Exception? updateProfileError;

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
    getProfileCalled = true;
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
          avatarUrl: avatar != null ? 'https://example.com/avatar.jpg' : null,
          role: 'creator',
          kycStatus: 'approved',
          isActive: true,
        );
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
  late ProfileProvider provider;

  setUp(() {
    mockRepository = _MockAuthRepository();
    provider = ProfileProvider(repository: mockRepository);
  });

  tearDown(() {
    provider.dispose();
  });

  group('ProfileProvider', () {
    test('loadProfile success populates user', () async {
      await provider.loadProfile();

      expect(provider.user, isNotNull);
      expect(provider.user!.firstName, 'Aminata');
      expect(provider.user!.lastName, 'Koné');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(mockRepository.getProfileCalled, true);
    });

    test('loadProfile failure sets error', () async {
      mockRepository.getProfileError = Exception('Network error');

      await provider.loadProfile();

      expect(provider.error, isNotNull);
      expect(provider.user, isNull);
      expect(provider.isLoading, false);
    });

    test('updateProfile success updates user', () async {
      final success = await provider.updateProfile(
        firstName: 'Moussa',
        lastName: 'Diallo',
      );

      expect(success, true);
      expect(provider.user, isNotNull);
      expect(provider.user!.firstName, 'Moussa');
      expect(provider.user!.lastName, 'Diallo');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(mockRepository.updateProfileCalled, true);
    });

    test('updateProfile failure sets error', () async {
      mockRepository.updateProfileError = Exception('Server error');

      final success = await provider.updateProfile(firstName: 'Test');

      expect(success, false);
      expect(provider.error, isNotNull);
      expect(provider.isLoading, false);
    });

    test('isProfileComplete returns true when names are set', () async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: 'Aminata',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      );

      await provider.loadProfile();
      expect(provider.isProfileComplete, true);
    });

    test('isProfileComplete returns false when firstName is null', () async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: null,
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      );

      await provider.loadProfile();
      expect(provider.isProfileComplete, false);
    });

    test('state transitions loading → data on loadProfile', () async {
      final states = <bool>[];
      provider.addListener(() {
        states.add(provider.isLoading);
      });

      await provider.loadProfile();

      // Should have: loading=true, then loading=false
      expect(states, contains(true));
      expect(states.last, false);
    });

    test('state transitions loading → error on failed loadProfile', () async {
      mockRepository.getProfileError = Exception('fail');

      final errors = <String?>[];
      provider.addListener(() {
        errors.add(provider.error);
      });

      await provider.loadProfile();

      expect(errors.last, isNotNull);
    });

    test('clearError resets error state', () async {
      mockRepository.getProfileError = Exception('fail');
      await provider.loadProfile();
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });

    test('isProfileComplete returns false when firstName is empty string',
        () async {
      mockRepository.profileToReturn = const UserModel(
        id: 1,
        phone: '+2250701020304',
        firstName: '',
        lastName: 'Koné',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      );

      await provider.loadProfile();
      expect(provider.isProfileComplete, false);
    });

    test('logout clears user state and calls repository', () async {
      await provider.loadProfile();
      expect(provider.user, isNotNull);

      await provider.logout();

      expect(mockRepository.logoutCalled, true);
      expect(provider.user, isNull);
      expect(provider.error, isNull);
      expect(provider.isLoading, false);
    });
  });
}
