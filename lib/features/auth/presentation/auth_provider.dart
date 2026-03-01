import 'package:flutter/foundation.dart';
import 'package:ppv_app/core/services/fcm_service.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/domain/user.dart';

/// Provider d'authentification — email/mot de passe.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({required AuthRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  User? _user;
  bool _disposed = false;
  bool _accountNotFound = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get accountNotFound => _accountNotFound;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Inscription complète avec email + mot de passe.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final result = await _repository.register(
        firstName:            firstName,
        lastName:             lastName,
        phone:                phone,
        email:                email,
        dateOfBirth:          dateOfBirth,
        password:             password,
        passwordConfirmation: passwordConfirmation,
      );
      _user = result.user;
      _isLoading = false;
      _safeNotify();
      return true;
    } on AuthApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _error = "Erreur lors de l'inscription. Veuillez réessayer.";
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Connexion avec email ou téléphone + mot de passe.
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _accountNotFound = false;
    _safeNotify();

    try {
      final result = await _repository.login(
        emailOrPhone: emailOrPhone,
        password:     password,
      );
      _user = result.user;
      _isLoading = false;
      _safeNotify();

      // Best-effort FCM token registration
      try {
        final fcmToken = await FcmService.instance.initialize();
        if (fcmToken != null) {
          await _repository.registerFcmToken(fcmToken);
        }
        FcmService.instance.listenTokenRefresh((newToken) async {
          try {
            await _repository.registerFcmToken(newToken);
          } catch (_) {}
        });
      } catch (_) {
        // FCM non disponible — ne bloque pas le flow de connexion
      }

      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'ACCOUNT_NOT_FOUND') {
        _accountNotFound = true;
        _error = 'Aucun compte trouvé avec cet identifiant.';
      } else if (e.code == 'INVALID_PASSWORD') {
        _error = 'Mot de passe incorrect.';
      } else {
        _error = e.message;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Erreur de connexion. Veuillez réessayer.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Déconnexion — appel API + nettoyage état.
  Future<void> logout() async {
    _isLoading = true;
    _safeNotify();

    try {
      await _repository.logout();
    } catch (_) {}

    _user = null;
    _accountNotFound = false;
    _isLoading = false;
    _safeNotify();
  }

  void clearError() {
    _error = null;
    _accountNotFound = false;
    _safeNotify();
  }
}
