import 'package:flutter/foundation.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository;
  // MED-03 — Cache financier stocké dans SecureStorage (chiffré) au lieu de SharedPreferences.
  // Injectable pour faciliter les tests (évite les timeouts pumpAndSettle).
  final SecureStorageService _secureStorage;

  WalletProvider({
    required WalletRepository repository,
    SecureStorageService secureStorage = const SecureStorageService(),
  })  : _repository = repository,
        _secureStorage = secureStorage;

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
      _error = e is ApiException ? e.message
               : e is NetworkException ? e.message
               : 'Une erreur inattendue est survenue.';
      // En mode hors-ligne, le solde cached reste affiché — pas d'écrasement
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreBalanceFromCache() async {
    try {
      final cached = await _secureStorage.getCachedBalance();
      if (cached != null && _balance == 0) {
        _balance = cached;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistBalanceToCache(int balance) async {
    try {
      await _secureStorage.saveWalletCache(
        balance: balance,
        totalCredits: _totalCredits,
      );
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
      // C2 — Persister le total des gains pour affichage hors-ligne (SecureStorage)
      await _persistBalanceToCache(_balance);
    } on Exception catch (e) {
      _transactionsError = e is ApiException ? e.message
               : e is NetworkException ? e.message
               : 'Une erreur inattendue est survenue.';
      // C2 — Restaurer le total cached si le réseau est indisponible
      if (refresh) await _restoreTotalCreditsFromCache();

    } finally {
      _isFetchingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> _restoreTotalCreditsFromCache() async {
    try {
      final cached = await _secureStorage.getCachedTotalCredits();
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
      _withdrawalError = e is ApiException ? e.message
               : e is NetworkException ? e.message
               : 'Une erreur inattendue est survenue.';
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
  String? _withdrawalsError;

  List<WithdrawalSummary> get withdrawals => _withdrawals;
  bool get isLoadingWithdrawals => _isLoadingWithdrawals;
  bool get hasMoreWithdrawals => _hasMoreWithdrawals;
  String? get withdrawalsError => _withdrawalsError;

  /// Charge (ou recharge) la liste des retraits depuis le début.
  Future<void> loadWithdrawals() async {
    if (_isLoadingWithdrawals) return;
    _isLoadingWithdrawals = true;
    _withdrawalsError = null;
    notifyListeners();

    try {
      final result = await _repository.getWithdrawals();
      _withdrawals = result.withdrawals;
      _hasMoreWithdrawals = result.hasMore;
      _nextWithdrawalCursor = result.nextCursor;
    } on Exception catch (e) {
      _withdrawalsError = e is ApiException
          ? e.message
          : e is NetworkException
              ? e.message
              : 'Impossible de charger les retraits. Réessayez.';
    } finally {
      _isLoadingWithdrawals = false;
      notifyListeners();
    }
  }

}
