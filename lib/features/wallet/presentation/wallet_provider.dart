import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';

// C2 — Clés de cache SharedPreferences pour le mode hors-ligne
const _kCacheBalance     = 'cache_wallet_balance';
const _kCacheTotalCredits = 'cache_wallet_total_credits';

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

  /// Charge le solde depuis l'API. Affiche le cache immédiatement si disponible (C2).
  /// Ignore les appels concurrents si un chargement est déjà en cours.
  Future<void> loadBalance() async {
    if (_isLoading) return;

    // C2 — Afficher les données cached en attendant la réponse réseau
    await _restoreBalanceFromCache();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getBalance();
      _balance = result.balance;
      await _persistBalanceToCache(_balance);
    } on Exception catch (e) {
      _error = e.toString();
      // En mode hors-ligne, le solde cached reste affiché — pas d'écrasement
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreBalanceFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(_kCacheBalance);
      if (cached != null && _balance == 0) {
        _balance = cached;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistBalanceToCache(int balance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCacheBalance, balance);
    } catch (_) {}
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
      // C2 — Persister le total des gains pour affichage hors-ligne
      await _persistTotalCreditsToCache(_totalCredits);
    } on Exception catch (e) {
      _transactionsError = e.toString();
      // C2 — Restaurer le total cached si le réseau est indisponible
      if (refresh) await _restoreTotalCreditsFromCache();
    } finally {
      _isFetchingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> _persistTotalCreditsToCache(int totalCredits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCacheTotalCredits, totalCredits);
    } catch (_) {}
  }

  Future<void> _restoreTotalCreditsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(_kCacheTotalCredits);
      if (cached != null) {
        _totalCredits = cached;
      }
    } catch (_) {}
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

}
