import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/payout/data/payout_remote_datasource.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_bottom_sheet.dart';

// ─── WalletRepository stubs ───────────────────────────────────────────────────

class _SuccessWalletRepository extends WalletRepository {
  _SuccessWalletRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 500000); // 5000 FCFA

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      const WalletTransactionsResult(
        transactions: [],
        totalCredits: 0,
        hasMore: false,
        nextCursor: null,
      );

  @override
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async =>
      const WithdrawalResult(withdrawalId: 1, status: 'pending', amount: 250000);
}

class _ErrorWalletRepository extends WalletRepository {
  _ErrorWalletRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 500000);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      const WalletTransactionsResult(
        transactions: [],
        totalCredits: 0,
        hasMore: false,
        nextCursor: null,
      );

  @override
  Future<WithdrawalResult> postWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async =>
      throw Exception('Erreur API');
}

class _SlowWalletRepository extends WalletRepository {
  _SlowWalletRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 500000);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      const WalletTransactionsResult(
        transactions: [],
        totalCredits: 0,
        hasMore: false,
        nextCursor: null,
      );

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
}

// ─── PayoutRemoteDataSource stub ─────────────────────────────────────────────

/// Retourne un moyen de reversement Orange Money ****1234 sans appel réseau.
class _StubPayoutRemoteDataSource extends PayoutRemoteDataSource {
  _StubPayoutRemoteDataSource() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>?> getPayoutMethod() async => {
        'data': {
          'id': 1,
          'payout_type': 'mobile_money',
          'provider': 'orange',
          'account_number_masked': '****1234',
          'account_holder_name': 'Jean Créateur',
          'bank_name': null,
          'is_active': true,
          'updated_at': null,
        },
      };
}

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _buildSheet({
  required WalletProvider walletProvider,
  required PayoutMethodProvider payoutProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
      ChangeNotifierProvider<PayoutMethodProvider>.value(value: payoutProvider),
    ],
    child: const MaterialApp(
      home: Scaffold(body: WithdrawalBottomSheet()),
    ),
  );
}

Future<PayoutMethodProvider> _loadedPayoutProvider() async {
  final provider = PayoutMethodProvider(
    repository: PayoutRepository(
      dataSource: _StubPayoutRemoteDataSource(),
    ),
  );
  await provider.loadExistingPayoutMethod();
  return provider;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('WithdrawalBottomSheet', () {
    // AC 1 — solde et moyen de reversement affichés
    testWidgets('affiche le solde disponible et le moyen de reversement', (tester) async {
      final walletProvider = WalletProvider(repository: _SuccessWalletRepository());
      await walletProvider.loadBalance(); // 500000 centimes = 5000 FCFA

      final payoutProvider = await _loadedPayoutProvider();

      await tester.pumpWidget(
        _buildSheet(walletProvider: walletProvider, payoutProvider: payoutProvider),
      );
      await tester.pump();

      // Solde disponible affiché
      expect(find.byKey(const Key('withdrawal-balance-display')), findsOneWidget);
      expect(find.text('5 000 FCFA'), findsOneWidget);

      // Moyen de reversement affiché (numéro masqué)
      expect(find.byKey(const Key('withdrawal-payout-method-display')), findsOneWidget);
      expect(find.textContaining('****1234'), findsOneWidget);
    });

    // AC 11 — erreur API affichée dans le sheet sans fermer
    testWidgets('affiche erreur API dans le sheet sans fermer', (tester) async {
      final walletProvider = WalletProvider(repository: _ErrorWalletRepository());
      await walletProvider.loadBalance();
      // Déclencher l'erreur avant d'afficher le sheet
      await walletProvider.requestWithdrawal(
        amountCentimes: 250000,
        payoutMethodId: 1,
      );

      final payoutProvider = await _loadedPayoutProvider();

      await tester.pumpWidget(
        _buildSheet(walletProvider: walletProvider, payoutProvider: payoutProvider),
      );
      await tester.pump();

      // Erreur visible dans le sheet
      expect(find.text('Erreur API'), findsOneWidget);

      // Sheet toujours ouvert (bouton Confirmer toujours présent)
      expect(find.byKey(const Key('btn-confirm-withdrawal')), findsOneWidget);
    });

    // AC 12 — bouton Confirmer affiche CircularProgressIndicator pendant isWithdrawing
    testWidgets('bouton Confirmer affiche spinner pendant isWithdrawing', (tester) async {
      final walletProvider = WalletProvider(repository: _SlowWalletRepository());
      await walletProvider.loadBalance(); // 500000 centimes = 5000 FCFA

      final payoutProvider = await _loadedPayoutProvider();

      await tester.pumpWidget(
        _buildSheet(walletProvider: walletProvider, payoutProvider: payoutProvider),
      );
      await tester.pump();

      // Saisir un montant valide (2500 FCFA ≥ 500 FCFA min, ≤ 5000 FCFA solde)
      await tester.enterText(
        find.byKey(const Key('withdrawal-amount-input')),
        '2500',
      );

      // Taper Confirmer → _submit() → requestWithdrawal() → isWithdrawing = true → notifyListeners()
      await tester.tap(find.byKey(const Key('btn-confirm-withdrawal')));
      await tester.pump(); // traite la mise à jour synchrone isWithdrawing = true

      // Spinner visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Nettoyer le timer 30s
      await tester.pump(const Duration(seconds: 31));
    });
  });
}
