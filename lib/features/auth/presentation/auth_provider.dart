import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:ppv_app/core/services/fcm_service.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/domain/user.dart';

/// Provider d'authentification — pattern loading/error/data.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({required AuthRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  User? _user;
  String? _verificationId;
  int? _resendToken;
  bool _disposed = false;
  bool _isLoginFlow = false;
  bool _accountNotFound = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  String? get verificationId => _verificationId;
  bool get isLoginFlow => _isLoginFlow;
  bool get accountNotFound => _accountNotFound;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Envoie un OTP au numéro de téléphone.
  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _repository.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          _safeNotify();
        },
        onVerificationFailed: (firebase.FirebaseAuthException e) {
          _error = _mapFirebaseError(e.code);
          _isLoading = false;
          _safeNotify();
        },
        onVerificationCompleted: (firebase.PhoneAuthCredential credential) {
          // Android auto-verification — trigger verify if code available
          final smsCode = credential.smsCode;
          if (smsCode != null && _verificationId != null) {
            verifyOtp(smsCode);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      _error = 'Erreur lors de l\'envoi du code. Veuillez réessayer.';
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Vérifie le code OTP saisi.
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _error = 'Session expirée. Veuillez renvoyer le code.';
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _repository.verifyOtp(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      _isLoading = false;
      _safeNotify();
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Erreur lors de la vérification. Veuillez réessayer.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Inscription côté API après vérification OTP réussie.
  Future<bool> register({String? firstName, String? lastName}) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final result = await _repository.register(
        firstName: firstName,
        lastName: lastName,
      );
      _user = result.user;
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'inscription. Veuillez réessayer.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Envoie un OTP pour le flow de connexion.
  Future<void> loginSendOtp(String phoneNumber) async {
    _isLoginFlow = true;
    _accountNotFound = false;
    await sendOtp(phoneNumber);
  }

  /// Connexion côté API après vérification OTP réussie.
  Future<bool> loginAfterOtp() async {
    _isLoading = true;
    _error = null;
    _accountNotFound = false;
    _safeNotify();

    try {
      final result = await _repository.login();
      _user = result.user;
      _isLoading = false;
      _safeNotify();

      // Best-effort FCM token registration — ne bloque jamais le flux de connexion
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
        // FCM non disponible (tests, permissions refusées, Firebase absent)
      }

      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'ACCOUNT_NOT_FOUND') {
        _accountNotFound = true;
        _error = 'Aucun compte associé à ce numéro. Veuillez vous inscrire.';
      } else {
        _error = e.message;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Erreur lors de la connexion. Veuillez réessayer.';
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
    } catch (_) {
      // Ignorer les erreurs — on clear l'état dans tous les cas
    }

    _user = null;
    _isLoginFlow = false;
    _accountNotFound = false;
    _verificationId = null;
    _resendToken = null;
    _isLoading = false;
    _safeNotify();
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _accountNotFound = false;
    _safeNotify();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'invalid-verification-code':
        return 'Code de vérification incorrect.';
      case 'session-expired':
        return 'Session expirée. Veuillez renvoyer le code.';
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }
}
