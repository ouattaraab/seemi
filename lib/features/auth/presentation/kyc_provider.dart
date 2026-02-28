import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';

/// Provider KYC — gère le flux multi-étapes de vérification d'identité.
class KycProvider extends ChangeNotifier {
  final AuthRepository _repository;

  KycProvider({required AuthRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  String? _error;
  int _currentStep = 1;
  String _firstName = '';
  String _lastName = '';
  DateTime? _dateOfBirth;
  File? _documentFile;
  String? _kycStatus;
  bool _isSubmitting = false;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentStep => _currentStep;
  String get firstName => _firstName;
  String get lastName => _lastName;
  DateTime? get dateOfBirth => _dateOfBirth;
  File? get documentFile => _documentFile;
  String? get kycStatus => _kycStatus;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Valide les données de l'étape 1 (informations personnelles).
  bool validateStep1() {
    _error = null;

    if (_firstName.trim().isEmpty) {
      _error = 'Le prénom est obligatoire.';
      _safeNotify();
      return false;
    }

    if (_lastName.trim().isEmpty) {
      _error = 'Le nom est obligatoire.';
      _safeNotify();
      return false;
    }

    if (_dateOfBirth == null) {
      _error = 'La date de naissance est obligatoire.';
      _safeNotify();
      return false;
    }

    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    if (age < 18) {
      _error = 'Vous devez avoir au moins 18 ans pour utiliser PPV.';
      _safeNotify();
      return false;
    }

    _safeNotify();
    return true;
  }

  /// Met à jour le prénom.
  void setFirstName(String value) {
    _firstName = value;
  }

  /// Met à jour le nom.
  void setLastName(String value) {
    _lastName = value;
  }

  /// Met à jour la date de naissance.
  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    _error = null;
    _safeNotify();
  }

  /// Stocke le fichier document sélectionné.
  void setDocument(File file) {
    _documentFile = file;
    _error = null;
    _safeNotify();
  }

  /// Passe à l'étape suivante.
  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      _error = null;
      _safeNotify();
    }
  }

  /// Revient à l'étape précédente.
  void previousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      _error = null;
      _safeNotify();
    }
  }

  /// Soumet les données KYC au serveur.
  Future<bool> submitKyc() async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final dateStr =
          '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}';

      final user = await _repository.submitKyc(
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        dateOfBirth: dateStr,
        document: _documentFile!,
      );

      _kycStatus = user.kycStatus;
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      _safeNotify();
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _safeNotify();
  }
}
