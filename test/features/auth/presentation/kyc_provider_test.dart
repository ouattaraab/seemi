import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/kyc_provider.dart';

class _MockAuthRepository implements AuthRepository {
  bool submitKycCalled = false;
  Exception? submitKycError;

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
    submitKycCalled = true;
    if (submitKycError != null) throw submitKycError!;
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
  late KycProvider provider;

  setUp(() {
    mockRepository = _MockAuthRepository();
    provider = KycProvider(repository: mockRepository);
  });

  group('KycProvider initial state', () {
    test('starts with step 1, no loading, no error', () {
      expect(provider.currentStep, 1);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.firstName, '');
      expect(provider.lastName, '');
      expect(provider.dateOfBirth, isNull);
      expect(provider.documentFile, isNull);
    });
  });

  group('KycProvider step navigation', () {
    test('nextStep increments current step', () {
      provider.nextStep();
      expect(provider.currentStep, 2);
    });

    test('nextStep does not go past step 3', () {
      provider.nextStep(); // 2
      provider.nextStep(); // 3
      provider.nextStep(); // still 3
      expect(provider.currentStep, 3);
    });

    test('previousStep decrements current step', () {
      provider.nextStep(); // 2
      provider.previousStep(); // 1
      expect(provider.currentStep, 1);
    });

    test('previousStep does not go below step 1', () {
      provider.previousStep(); // still 1
      expect(provider.currentStep, 1);
    });
  });

  group('KycProvider.validateStep1', () {
    test('returns false when firstName is empty', () {
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));

      expect(provider.validateStep1(), false);
      expect(provider.error, contains('prénom'));
    });

    test('returns false when lastName is empty', () {
      provider.setFirstName('Aminata');
      provider.setDateOfBirth(DateTime(2000, 3, 15));

      expect(provider.validateStep1(), false);
      expect(provider.error, contains('nom'));
    });

    test('returns false when dateOfBirth is null', () {
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');

      expect(provider.validateStep1(), false);
      expect(provider.error, contains('date'));
    });

    test('returns false when user is under 18', () {
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime.now().subtract(const Duration(days: 365 * 17)));

      expect(provider.validateStep1(), false);
      expect(provider.error, contains('18 ans'));
    });

    test('returns true when all step 1 fields are valid', () {
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));

      expect(provider.validateStep1(), true);
      expect(provider.error, isNull);
    });
  });

  group('KycProvider.submitKyc', () {
    test('transitions loading → success', () async {
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.setDocument(File('/fake/path/id.jpg'));

      final loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final success = await provider.submitKyc();

      expect(success, true);
      expect(mockRepository.submitKycCalled, true);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(loadingStates.first, true);
    });

    test('transitions loading → error on failure', () async {
      provider.setFirstName('Aminata');
      provider.setLastName('Koné');
      provider.setDateOfBirth(DateTime(2000, 3, 15));
      provider.setDocument(File('/fake/path/id.jpg'));

      mockRepository.submitKycError = Exception('KYC error');

      final success = await provider.submitKyc();

      expect(success, false);
      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
    });
  });

  group('KycProvider.clearError', () {
    test('clears error state', () {
      provider.setFirstName('');
      provider.validateStep1();
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });
  });

  group('KycProvider.dispose', () {
    test('does not throw when notifying after dispose', () {
      provider.dispose();
      expect(() => provider.clearError(), returnsNormally);
    });
  });
}
