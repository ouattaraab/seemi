import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;

  WalletProvider({required WalletRepository repository})
      : _repository = repository;

  // ─── Balance state ───────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  int _balance = 0; // centimes FCFA

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _balance;

  /// Charge le solde depuis l'API.
  /// Ignore les appels concurrents si un chargement est déjà en cours.
  Future<void> loadBalance() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getBalance();
      _balance = result.balance;
    } on Exception catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Transactions state ──────────────────────────────────────────────────

  List<WalletTransaction> _transactions = [];
  bool _isFetchingTransactions = false;
  String? _transactionsError;
  String? _transactionsNextCursor;
  bool _hasMoreTransactions = false;
  int _totalCredits = 0; // centimes FCFA

  List<WalletTransaction> get transactions => _transactions;
  bool get isFetchingTransactions => _isFetchingTransactions;
  String? get transactionsError => _transactionsError;
  bool get hasMoreTransactions => _hasMoreTransactions;
  int get totalCredits => _totalCredits;

  /// Charge (ou recharge) la liste des transactions.
  /// [refresh] = true recharge depuis le début (reset du curseur).
  Future<void> loadTransactions({bool refresh = false}) async {
    if (_isFetchingTransactions) return;
    if (!refresh && !_hasMoreTransactions && _transactions.isNotEmpty) return;

    if (refresh) {
      _transactions = [];
      _transactionsNextCursor = null;
      _hasMoreTransactions = false;
    }

    _isFetchingTransactions = true;
    _transactionsError = null;
    notifyListeners();

    try {
      final result = await _repository.getTransactions(
        cursor: _transactionsNextCursor,
      );
      _transactions = refresh
          ? result.transactions
          : [..._transactions, ...result.transactions];
      _transactionsNextCursor = result.nextCursor;
      _hasMoreTransactions = result.hasMore;
      _totalCredits = result.totalCredits;
    } on Exception catch (e) {
      _transactionsError = e.toString();
    } finally {
      _isFetchingTransactions = false;
      notifyListeners();
    }
  }

  // ─── Withdrawal state ─────────────────────────────────────────────────────

  bool _isWithdrawing = false;
  String? _withdrawalError;

  bool get isWithdrawing => _isWithdrawing;
  String? get withdrawalError => _withdrawalError;

  /// Remet à zéro l'erreur de retrait (appelé à l'ouverture du bottom sheet).
  void clearWithdrawalError() {
    _withdrawalError = null;
    notifyListeners();
  }

  /// Envoie une demande de retrait.
  /// Retourne [true] en cas de succès, [false] sinon.
  /// En cas de succès, recharge le solde automatiquement.
  Future<bool> requestWithdrawal({
    required int amountCentimes,
    required int payoutMethodId,
  }) async {
    if (_isWithdrawing) return false;

    _isWithdrawing = true;
    _withdrawalError = null;
    notifyListeners();

    try {
      await _repository.postWithdrawal(
        amountCentimes: amountCentimes,
        payoutMethodId: payoutMethodId,
      );
      _isWithdrawing = false;
      notifyListeners();
      await loadBalance();
      await loadWithdrawals();
      return true;
    } on Exception catch (e) {
      _withdrawalError = e.toString().replaceFirst('Exception: ', '');
      _isWithdrawing = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Withdrawals list state ───────────────────────────────────────────────

  List<WithdrawalSummary> _withdrawals = [];
  bool _isLoadingWithdrawals = false;
  bool _hasMoreWithdrawals = false;
  String? _nextWithdrawalCursor;

  List<WithdrawalSummary> get withdrawals => _withdrawals;
  bool get isLoadingWithdrawals => _isLoadingWithdrawals;
  bool get hasMoreWithdrawals => _hasMoreWithdrawals;

  /// Charge (ou recharge) la liste des retraits depuis le début.
  Future<void> loadWithdrawals() async {
    if (_isLoadingWithdrawals) return;
    _isLoadingWithdrawals = true;
    notifyListeners();

    try {
      final result = await _repository.getWithdrawals();
      _withdrawals = result.withdrawals;
      _hasMoreWithdrawals = result.hasMore;
      _nextWithdrawalCursor = result.nextCursor;
    } catch (_) {
      // Silence — liste reste vide
    } finally {
      _isLoadingWithdrawals = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante des retraits (pagination curseur).
  Future<void> loadMoreWithdrawals() async {
    if (_isLoadingWithdrawals || !_hasMoreWithdrawals) return;
    _isLoadingWithdrawals = true;
    notifyListeners();

    try {
      final result = await _repository.getWithdrawals(cursor: _nextWithdrawalCursor);
      _withdrawals = [..._withdrawals, ...result.withdrawals];
      _hasMoreWithdrawals = result.hasMore;
      _nextWithdrawalCursor = result.nextCursor;
    } catch (_) {
      // Silence
    } finally {
      _isLoadingWithdrawals = false;
      notifyListeners();
    }
  }
}
