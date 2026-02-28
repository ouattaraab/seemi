import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';

// ─── Repository stubs ────────────────────────────────────────────────────────

class _SuccessWithdrawalRepository extends WalletRepository {
  final int balanceAfterWithdrawal;

  _SuccessWithdrawalRepository({this.balanceAfterWithdrawal = 250000})
      : super(dio: Dio());

  @override
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async =>
      const WithdrawalResult(
        withdrawalId: 1,
        status: 'pending',
        amount: 250000,
      );

  @override
  Future<WalletBalanceResult> getBalance() async =>
      WalletBalanceResult(balance: balanceAfterWithdrawal);
}

class _ErrorWithdrawalRepository extends WalletRepository {
  _ErrorWithdrawalRepository() : super(dio: Dio());

  @override
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async =>
      throw Exception('INSUFFICIENT_BALANCE');

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);
}

class _SlowWithdrawalRepository extends WalletRepository {
  _SlowWithdrawalRepository() : super(dio: Dio());

  @override
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 30));
    return const WithdrawalResult(
      withdrawalId: 1,
      status: 'pending',
      amount: 250000,
    );
  }

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('WalletProvider — withdrawal', () {
    // AC 8 — succès : retourne true et recharge le solde
    test('requestWithdrawal retourne true et recharge le solde', () async {
      final provider = WalletProvider(
        repository: _SuccessWithdrawalRepository(balanceAfterWithdrawal: 250000),
      );

      final result = await provider.requestWithdrawal(
        amountCentimes: 250000,
        payoutMethodId: 1,
      );

      expect(result, isTrue);
      expect(provider.isWithdrawing, isFalse);
      expect(provider.withdrawalError, isNull);
      // Solde rechargé depuis le stub (250000)
      expect(provider.balance, equals(250000));
    });

    // AC 11 — erreur : retourne false et renseigne withdrawalError
    test('requestWithdrawal retourne false et renseigne withdrawalError', () async {
      final provider = WalletProvider(
        repository: _ErrorWithdrawalRepository(),
      );

      final result = await provider.requestWithdrawal(
        amountCentimes: 500000,
        payoutMethodId: 1,
      );

      expect(result, isFalse);
      expect(provider.isWithdrawing, isFalse);
      expect(provider.withdrawalError, isNotNull);
      expect(provider.withdrawalError, contains('INSUFFICIENT_BALANCE'));
    });

    // AC 12 — guard anti-concurrent : second appel retourne false immédiatement
    test('guard anti-concurrent : second appel retourne false', () async {
      final provider = WalletProvider(
        repository: _SlowWithdrawalRepository(),
      );

      // Lancer le premier appel (long) sans await
      final first = provider.requestWithdrawal(
        amountCentimes: 250000,
        payoutMethodId: 1,
      );

      // Laisser une frame pour que isWithdrawing passe à true
      await Future<void>.delayed(Duration.zero);

      // Le second appel doit retourner false immédiatement
      final secondResult = await provider.requestWithdrawal(
        amountCentimes: 250000,
        payoutMethodId: 1,
      );

      expect(secondResult, isFalse);

      // Le premier appel (30 s) est laissé en cours.
      // Future.ignore() supprime l'avertissement analyzer sur le Future non-awaité.
      // Le timer expire après la fin du test sans impact sur le résultat.
      first.ignore();
    });

    // clearWithdrawalError remet withdrawalError à null
    test('clearWithdrawalError remet withdrawalError à null', () async {
      final provider = WalletProvider(
        repository: _ErrorWithdrawalRepository(),
      );

      await provider.requestWithdrawal(
        amountCentimes: 500000,
        payoutMethodId: 1,
      );
      expect(provider.withdrawalError, isNotNull);

      provider.clearWithdrawalError();
      expect(provider.withdrawalError, isNull);
    });
  });
}
