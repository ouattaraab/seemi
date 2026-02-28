import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/domain/tos_acceptance.dart';

/// Provider CGU — gère l'acceptation des conditions générales.
class TosProvider extends ChangeNotifier {
  final AuthRepository _repository;

  TosProvider({required AuthRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  bool _tosAccepted = false;
  bool _tosDeclined = false;
  TosAcceptance? _lastAcceptance;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get tosAccepted => _tosAccepted;
  bool get tosDeclined => _tosDeclined;
  TosAcceptance? get lastAcceptance => _lastAcceptance;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Accepte les CGU pour le type donné.
  Future<bool> acceptTos(String type) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _lastAcceptance = await _repository.acceptTos(type: type);
      _tosAccepted = true;
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

  /// Refuse les CGU — bloque l'accès.
  void declineTos() {
    _tosDeclined = true;
    _tosAccepted = false;
    _safeNotify();
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _safeNotify();
  }

  /// Reset l'état complet (pour réutilisation).
  void reset() {
    _isLoading = false;
    _error = null;
    _tosAccepted = false;
    _tosDeclined = false;
    _lastAcceptance = null;
    _safeNotify();
  }
}
