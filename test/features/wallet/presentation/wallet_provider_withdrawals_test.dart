import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';

// ─── Repository stubs ────────────────────────────────────────────────────────

class _OneWithdrawalRepository extends WalletRepository {
  _OneWithdrawalRepository() : super(dio: Dio());

  @override
  Future<WithdrawalsResult> getWithdrawals({String? cursor}) async =>
      WithdrawalsResult(
        withdrawals: [
          WithdrawalSummary(
            id: 1,
            amount: 250000,
            status: 'pending',
            createdAt: DateTime(2026, 2, 26),
            payoutMethodLabel: 'Orange Mobile Money — ****1234',
          ),
        ],
        hasMore: false,
      );

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);
}

class _EmptyWithdrawalsRepository extends WalletRepository {
  _EmptyWithdrawalsRepository() : super(dio: Dio());

  @override
  Future<WithdrawalsResult> getWithdrawals({String? cursor}) async =>
      const WithdrawalsResult(withdrawals: [], hasMore: false);

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);
}

class _SlowWithdrawalsRepository extends WalletRepository {
  _SlowWithdrawalsRepository() : super(dio: Dio());

  @override
  Future<WithdrawalsResult> getWithdrawals({String? cursor}) async {
    await Future<void>.delayed(const Duration(seconds: 30));
    return const WithdrawalsResult(withdrawals: [], hasMore: false);
  }

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('WalletProvider — withdrawals list', () {
    // AC 1 — loadWithdrawals popule la liste
    test('loadWithdrawals popule provider.withdrawals', () async {
      final provider = WalletProvider(repository: _OneWithdrawalRepository());

      await provider.loadWithdrawals();

      expect(provider.withdrawals, hasLength(1));
      expect(provider.withdrawals.first.id, equals(1));
      expect(provider.withdrawals.first.status, equals('pending'));
      expect(provider.withdrawals.first.amount, equals(250000));
      expect(provider.isLoadingWithdrawals, isFalse);
    });

    // AC 3 — liste vide
    test('loadWithdrawals avec liste vide → withdrawals.isEmpty', () async {
      final provider = WalletProvider(repository: _EmptyWithdrawalsRepository());

      await provider.loadWithdrawals();

      expect(provider.withdrawals, isEmpty);
      expect(provider.isLoadingWithdrawals, isFalse);
    });

    // Guard anti-concurrent
    test('guard anti-concurrent : second appel sans effet pendant chargement', () async {
      final provider = WalletProvider(repository: _SlowWithdrawalsRepository());

      // Premier appel (long) sans await
      final first = provider.loadWithdrawals();

      // Laisser une frame pour que isLoadingWithdrawals passe à true
      await Future<void>.delayed(Duration.zero);
      expect(provider.isLoadingWithdrawals, isTrue);

      // Second appel doit retourner immédiatement sans changer l'état
      await provider.loadWithdrawals();
      expect(provider.isLoadingWithdrawals, isTrue); // toujours true (premier en cours)

      // Nettoyer le timer 30s
      first.ignore();
    });
  });
}
