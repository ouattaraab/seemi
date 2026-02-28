import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/payout/data/payout_method_model.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';

class _MockPayoutRepository implements PayoutRepository {
  bool shouldFail = false;
  String failMessage = 'Erreur serveur';
  int configureCallCount = 0;
  int getCallCount = 0;
  PayoutMethodModel? existingPayoutMethod;

  @override
  Future<PayoutMethodModel> configurePayoutMethod({
    required String payoutType,
    String? provider,
    required String accountNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    configureCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
    }
    return PayoutMethodModel(
      id: 1,
      payoutType: payoutType,
      provider: provider,
      accountNumberMasked: '****${accountNumber.substring(accountNumber.length - 4)}',
      accountHolderName: accountHolderName,
      bankName: bankName,
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<PayoutMethodModel?> getPayoutMethod() async {
    getCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
    }
    return existingPayoutMethod;
  }
}

void main() {
  late _MockPayoutRepository mockRepository;
  late PayoutMethodProvider provider;

  setUp(() {
    mockRepository = _MockPayoutRepository();
    provider = PayoutMethodProvider(repository: mockRepository);
  });

  group('PayoutMethodProvider', () {
    test('initial state is correct', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.selectedType, 'mobile_money');
      expect(provider.selectedProvider, 'orange');
      expect(provider.existingPayoutMethod, isNull);
    });

    test('setPayoutType changes selected type', () {
      provider.setPayoutType('bank_account');
      expect(provider.selectedType, 'bank_account');
    });

    test('setProvider changes selected provider', () {
      provider.setProvider('mtn');
      expect(provider.selectedProvider, 'mtn');
    });

    test('submitPayoutMethod success returns true', () async {
      final result = await provider.submitPayoutMethod(
        accountNumber: '0701020304',
        accountHolderName: 'Aminata Koné',
      );

      expect(result, true);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.existingPayoutMethod, isNotNull);
      expect(provider.existingPayoutMethod!.payoutType, 'mobile_money');
      expect(mockRepository.configureCallCount, 1);
    });

    test('submitPayoutMethod failure sets error', () async {
      mockRepository.shouldFail = true;
      mockRepository.failMessage = 'Numéro invalide';

      final result = await provider.submitPayoutMethod(
        accountNumber: '1234567890',
        accountHolderName: 'Test',
      );

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.error, contains('Numéro invalide'));
    });

    test('loadExistingPayoutMethod sets state from existing data', () async {
      mockRepository.existingPayoutMethod = PayoutMethodModel(
        id: 5,
        payoutType: 'bank_account',
        accountNumberMasked: '****5678',
        accountHolderName: 'Aminata Koné',
        bankName: 'Banque Atlantique',
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await provider.loadExistingPayoutMethod();

      expect(provider.existingPayoutMethod, isNotNull);
      expect(provider.selectedType, 'bank_account');
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(mockRepository.getCallCount, 1);
    });

    test('loadExistingPayoutMethod handles null (no existing)', () async {
      await provider.loadExistingPayoutMethod();

      expect(provider.existingPayoutMethod, isNull);
      expect(provider.selectedType, 'mobile_money'); // unchanged
      expect(provider.isLoading, false);
    });

    test('loadExistingPayoutMethod handles error', () async {
      mockRepository.shouldFail = true;
      mockRepository.failMessage = 'Connexion impossible';

      await provider.loadExistingPayoutMethod();

      expect(provider.error, contains('Connexion impossible'));
      expect(provider.isLoading, false);
    });

    test('clearError resets error state', () async {
      mockRepository.shouldFail = true;
      await provider.submitPayoutMethod(
        accountNumber: '0701020304',
        accountHolderName: 'Test',
      );

      expect(provider.error, isNotNull);

      provider.clearError();

      expect(provider.error, isNull);
    });

    test('isValidMobileMoneyNumber validates correctly', () {
      expect(provider.isValidMobileMoneyNumber('0701020304'), true);
      expect(provider.isValidMobileMoneyNumber('0501020304'), true);
      expect(provider.isValidMobileMoneyNumber('0101020304'), true);
      expect(provider.isValidMobileMoneyNumber('1234567890'), false);
      expect(provider.isValidMobileMoneyNumber('070102030'), false); // too short
      expect(provider.isValidMobileMoneyNumber('07010203045'), false); // too long
      expect(provider.isValidMobileMoneyNumber('0201020304'), false); // invalid prefix
    });

    test('safeNotify does not throw after dispose', () {
      final disposableProvider =
          PayoutMethodProvider(repository: mockRepository);
      disposableProvider.dispose();

      expect(
          () => disposableProvider.setPayoutType('bank_account'),
          returnsNormally);
    });
  });
}
