import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/domain/payout_method.dart';

/// Provider moyen de reversement — gère la configuration et l'affichage.
class PayoutMethodProvider extends ChangeNotifier {
  final PayoutRepository _repository;

  PayoutMethodProvider({required PayoutRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  String _selectedType = 'mobile_money';
  String _selectedProvider = 'orange';
  PayoutMethod? _existingPayoutMethod;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedType => _selectedType;
  String get selectedProvider => _selectedProvider;
  PayoutMethod? get existingPayoutMethod => _existingPayoutMethod;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Change le type de reversement (mobile_money / bank_account).
  void setPayoutType(String type) {
    _selectedType = type;
    _safeNotify();
  }

  /// Change le provider Mobile Money (orange / mtn / wave).
  void setProvider(String provider) {
    _selectedProvider = provider;
    _safeNotify();
  }

  /// Charge le moyen de reversement existant.
  Future<void> loadExistingPayoutMethod() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _existingPayoutMethod = await _repository.getPayoutMethod();
      if (_existingPayoutMethod != null) {
        _selectedType = _existingPayoutMethod!.payoutType;
        if (_existingPayoutMethod!.provider != null) {
          _selectedProvider = _existingPayoutMethod!.provider!;
        }
      }
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Valide le numéro Mobile Money CI (format: 0[157]XXXXXXXX).
  bool isValidMobileMoneyNumber(String number) {
    return RegExp(r'^0[157]\d{8}$').hasMatch(number);
  }

  /// Envoie la configuration du moyen de reversement.
  Future<bool> submitPayoutMethod({
    required String accountNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _existingPayoutMethod = await _repository.configurePayoutMethod(
        payoutType: _selectedType,
        provider: _selectedType == 'mobile_money' ? _selectedProvider : null,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        bankName: _selectedType == 'bank_account' ? bankName : null,
      );
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _safeNotify();
  }
}
