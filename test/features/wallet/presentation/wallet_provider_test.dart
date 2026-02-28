import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';

// ─── Repository mocks ────────────────────────────────────────────────────────

class _SuccessRepository extends WalletRepository {
  final int balance;

  _SuccessRepository(this.balance) : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      WalletBalanceResult(balance: balance);
}

class _ErrorRepository extends WalletRepository {
  _ErrorRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      throw Exception('Erreur réseau simulée');
}

class _TransactionsRepository extends WalletRepository {
  final List<WalletTransaction> txList;
  final int totalCredits;
  final bool hasMore;
  final String? nextCursor;
  int _callCount = 0;

  _TransactionsRepository({
    this.txList = const [],
    this.totalCredits = 0,
    this.hasMore = false,
    this.nextCursor,
  }) : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async {
    _callCount++;
    return WalletTransactionsResult(
      transactions: txList,
      totalCredits: totalCredits,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  int get callCount => _callCount;
}

class _EmptyTransactionsRepository extends WalletRepository {
  _EmptyTransactionsRepository() : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async =>
      const WalletTransactionsResult(
        transactions: [],
        totalCredits: 0,
        hasMore: false,
        nextCursor: null,
      );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

WalletTransaction _makeTransaction(int id, int amount) => WalletTransaction(
      id: id,
      type: 'credit',
      amount: amount,
      commissionAmount: 0,
      createdAt: DateTime.now(),
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('WalletProvider', () {
    // ── Balance tests ─────────────────────────────────────────────────────

    test('état initial — balance=0, isLoading=false, error=null', () {
      final provider = WalletProvider(repository: _SuccessRepository(0));

      expect(provider.balance, 0);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadBalance — passe par loading puis définit balance', () async {
      final provider = WalletProvider(repository: _SuccessRepository(250000));

      final states = <bool>[];
      provider.addListener(() => states.add(provider.isLoading));

      await provider.loadBalance();

      expect(states, containsAllInOrder([true, false]));
      expect(provider.balance, 250000);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadBalance — définit error si exception', () async {
      final provider = WalletProvider(repository: _ErrorRepository());

      await provider.loadBalance();

      expect(provider.error, isNotNull);
      expect(provider.error, contains('Erreur réseau simulée'));
      expect(provider.balance, 0);
      expect(provider.isLoading, isFalse);
    });

    test('loadBalance — retourne les centimes corrects', () async {
      final provider = WalletProvider(repository: _SuccessRepository(150000));

      await provider.loadBalance();

      expect(provider.balance, 150000); // 1500 FCFA en centimes
    });

    test('loadBalance — balance zéro est valide', () async {
      final provider = WalletProvider(repository: _SuccessRepository(0));

      await provider.loadBalance();

      expect(provider.balance, 0);
      expect(provider.error, isNull);
    });

    // ── Transactions tests ────────────────────────────────────────────────

    test('loadTransactions — liste vide au départ', () async {
      final provider = WalletProvider(
        repository: _EmptyTransactionsRepository(),
      );

      await provider.loadTransactions();

      expect(provider.transactions, isEmpty);
      expect(provider.hasMoreTransactions, isFalse);
      expect(provider.isFetchingTransactions, isFalse);
    });

    test('loadTransactions — charge les transactions et le total', () async {
      final txList = [
        _makeTransaction(1, 80000),
        _makeTransaction(2, 80000),
      ];
      final provider = WalletProvider(
        repository: _TransactionsRepository(
          txList: txList,
          totalCredits: 160000,
        ),
      );

      await provider.loadTransactions();

      expect(provider.transactions.length, 2);
      expect(provider.totalCredits, 160000);
      expect(provider.isFetchingTransactions, isFalse);
      expect(provider.transactionsError, isNull);
    });

    test('loadTransactions — ignore appel concurrent si isFetchingTransactions',
        () async {
      final repo = _TransactionsRepository(txList: [_makeTransaction(1, 80000)]);
      final provider = WalletProvider(repository: repo);

      // Déclencher deux appels simultanés sans await sur le premier
      final f1 = provider.loadTransactions();
      final f2 = provider.loadTransactions(); // doit être ignoré
      await Future.wait([f1, f2]);

      expect(repo.callCount, 1); // une seule requête envoyée
    });

    test('loadTransactions — refresh remet à zéro la liste', () async {
      final txFirst = [_makeTransaction(1, 80000)];
      final txRefreshed = [_makeTransaction(2, 40000), _makeTransaction(3, 40000)];

      final repo = _TransactionsRepositoryRefresh(
        firstList: txFirst,
        refreshList: txRefreshed,
        totalCredits: 80000,
      );
      final provider = WalletProvider(repository: repo);

      // Premier chargement
      await provider.loadTransactions();
      expect(provider.transactions.length, 1);
      expect(provider.transactions.first.id, 1);

      // Refresh
      await provider.loadTransactions(refresh: true);
      expect(provider.transactions.length, 2);
      expect(provider.transactions.first.id, 2);
    });
  });
}

// ─── Helper repo pour le test refresh ────────────────────────────────────────

class _TransactionsRepositoryRefresh extends WalletRepository {
  final List<WalletTransaction> firstList;
  final List<WalletTransaction> refreshList;
  final int totalCredits;
  int _callCount = 0;

  _TransactionsRepositoryRefresh({
    required this.firstList,
    required this.refreshList,
    required this.totalCredits,
  }) : super(dio: Dio());

  @override
  Future<WalletBalanceResult> getBalance() async =>
      const WalletBalanceResult(balance: 0);

  @override
  Future<WalletTransactionsResult> getTransactions({String? cursor}) async {
    _callCount++;
    final list = _callCount == 1 ? firstList : refreshList;
    return WalletTransactionsResult(
      transactions: list,
      totalCredits: totalCredits,
      hasMore: false,
      nextCursor: null,
    );
  }
}
