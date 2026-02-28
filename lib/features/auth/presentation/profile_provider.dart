import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/domain/user.dart';

/// Provider de gestion du profil — pattern loading/error/data.
class ProfileProvider extends ChangeNotifier {
  final AuthRepository _repository;

  ProfileProvider({required AuthRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  User? _user;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isProfileComplete =>
      (_user?.firstName?.isNotEmpty ?? false) &&
      (_user?.lastName?.isNotEmpty ?? false);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Charge le profil utilisateur depuis l'API.
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _user = await _repository.getProfile();
    } catch (e) {
      _error = 'Erreur lors du chargement du profil.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Met à jour le profil (nom, prénom, avatar).
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _user = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        avatar: avatar,
      );
      return true;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du profil.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _safeNotify();
  }

  /// Déconnecte l'utilisateur : invalide JWT serveur + clear state local.
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignorer les erreurs réseau lors du logout
    }
    _user = null;
    _error = null;
    _isLoading = false;
    _safeNotify();
  }
}
