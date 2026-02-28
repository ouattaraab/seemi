import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/payout/data/payout_remote_datasource.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_screen.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/transaction_list_item.dart';

// ─── Repository stubs ────────────────────────────────────────────────────────

class _BalanceRepository extends WalletRepository {
  final int balance;
  final int totalCredits;
  final List<WalletTransaction> transactions;

  _BalanceRepository(
    this.balance, {
    this.totalCredits = 0,
    this.transactions = const [],
  }) : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      WalletBalanceResult(balance: balance);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      WalletTransactionsResult(
        transactions: transactions,
        totalCredits: totalCredits,
        hasMore: false,
        nextCursor: null,
      );
}

class _SlowLoadingRepository extends WalletRepository {
  _SlowLoadingRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async {
    // Simule un chargement en cours
    await Future<void>.delayed(const Duration(seconds: 30));
    return const WalletBalanceResult(balance: 0);
  }

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      const WalletTransactionsResult(
        transactions: [],
        totalCredits: 0,
        hasMore: false,
        nextCursor: null,
      );
}

// ─── Helper ──────────────────────────────────────────────────────────────────

/// DataSource stub — retourne null immédiatement sans appel réseau.
/// Requis car WalletScreen.initState appelle loadExistingPayoutMethod().
class _NullPayoutRemoteDataSource extends PayoutRemoteDataSource {
  _NullPayoutRemoteDataSource() : super(dio: Dio());

  @override
  Future<Map<String, dynamic>?> getPayoutMethod() async => null;
}

/// PayoutMethodProvider stub — pas de moyen de reversement, pas d'appel réseau.
PayoutMethodProvider _stubPayoutProvider() => PayoutMethodProvider(
      repository: PayoutRepository(
        dataSource: _NullPayoutRemoteDataSource(),
      ),
    );

Widget _buildScreen(WalletProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WalletProvider>.value(value: provider),
      ChangeNotifierProvider<PayoutMethodProvider>(
        create: (_) => _stubPayoutProvider(),
      ),
    ],
    child: const MaterialApp(home: WalletScreen()),
  );
}

WalletTransaction _makeTx(int id) => WalletTransaction(
      id: id,
      type: 'credit',
      amount: 80000,
      commissionAmount: 20000,
      buyerEmail: 'buyer$id@example.com',
      paymentMethod: 'mobile_money',
      createdAt: DateTime.now(),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('WalletScreen', () {
    // AC 8 — solde affiché en FCFA après chargement
    testWidgets('affiche le solde en FCFA après chargement', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(250000), // 2500 FCFA
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wallet-balance-text')), findsOneWidget);
      expect(find.text('2 500 FCFA'), findsOneWidget);
    });

    // AC 8 — spinner pendant le chargement
    testWidgets('affiche un spinner pendant le chargement', (tester) async {
      final provider = WalletProvider(
        repository: _SlowLoadingRepository(),
      );

      await tester.pumpWidget(_buildScreen(provider));
      // Un seul pump pour voir l'état intermédiaire (avant pumpAndSettle)
      await tester.pump();
      await tester.pump(); // déclenche le PostFrameCallback

      // isLoading = true → WalletCard affiche CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Compléter les timers pour éviter les fuites
      await tester.pump(const Duration(seconds: 31));
    });

    // AC 10 — bouton Retirer désactivé
    testWidgets('affiche le bouton Retirer désactivé', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(0),
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn-withdraw')),
      );

      expect(button.onPressed, isNull);
    });

    // AC 8 — solde zéro affiché correctement
    testWidgets('affiche 0 FCFA pour un nouveau créateur', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(0),
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.text('0 FCFA'), findsOneWidget);
    });

    // AC 8 — titre de l'écran
    testWidgets('affiche le titre Portefeuille', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(0),
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.text('Portefeuille'), findsOneWidget);
    });

    // AC 2 — total des gains affiché avec format et séparateur de milliers
    testWidgets('affiche le total des gains', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(0, totalCredits: 125000), // 1250 FCFA
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('total-credits-text')), findsOneWidget);
      // 125000 centimes ÷ 100 = 1250 FCFA → "1 250 FCFA" avec séparateur
      expect(find.text('1 250 FCFA gagnés au total'), findsOneWidget);
    });

    // AC 3 — transactions affichées via TransactionListItem
    testWidgets('affiche les transactions', (tester) async {
      final provider = WalletProvider(
        repository: _BalanceRepository(
          0,
          transactions: [_makeTx(1), _makeTx(2)],
        ),
      );

      await tester.pumpWidget(_buildScreen(provider));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionListItem), findsNWidgets(2));
    });
  });
}
