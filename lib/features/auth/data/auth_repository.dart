import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';

/// Résultat d'une inscription réussie.
class RegisterResult {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const RegisterResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Résultat d'une connexion réussie.
class LoginResult {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Repository d'authentification — orchestre DataSource + SecureStorage.
class AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final SecureStorageService _storageService;

  AuthRepository({
    required AuthRemoteDataSource dataSource,
    required SecureStorageService storageService,
  })  : _dataSource = dataSource,
        _storageService = storageService;

  /// Envoie un OTP au numéro de téléphone.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase.FirebaseAuthException error)
        onVerificationFailed,
    required void Function(firebase.PhoneAuthCredential credential)
        onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    return _dataSource.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  /// Vérifie le code OTP et retourne le UserCredential Firebase.
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) {
    return _dataSource.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Inscription complète : Firebase token → API register → stockage JWT.
  Future<RegisterResult> register({
    String? firstName,
    String? lastName,
  }) async {
    final firebaseToken = await _dataSource.getFirebaseIdToken();
    if (firebaseToken == null) {
      throw Exception('No Firebase token available');
    }

    final response = await _dataSource.registerWithFirebaseToken(
      firebaseToken: firebaseToken,
      firstName: firstName,
      lastName: lastName,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final userData = data['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing user data');
    }

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw Exception('Invalid API response: missing tokens');
    }

    final user = UserModel.fromJson(userData);

    await _storageService.saveTokens(access: accessToken, refresh: refreshToken);

    return RegisterResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Soumet les données KYC.
  Future<UserModel> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    final response = await _dataSource.submitKyc(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      document: document,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final userData = data['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing user data');
    }

    return UserModel.fromJson(userData);
  }

  /// Enregistre l'acceptation des CGU.
  Future<TosAcceptanceModel> acceptTos({
    required String type,
  }) async {
    final response = await _dataSource.acceptTos(
      type: type,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    return TosAcceptanceModel.fromJson(data);
  }

  /// Connexion : Firebase token → API login → stockage JWT.
  ///
  /// Propage [AuthApiException] si ACCOUNT_NOT_FOUND ou ACCOUNT_DISABLED.
  Future<LoginResult> login() async {
    final firebaseToken = await _dataSource.getFirebaseIdToken();
    if (firebaseToken == null) {
      throw Exception('No Firebase token available');
    }

    final response = await _dataSource.login(firebaseToken: firebaseToken);

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final userData = data['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing user data');
    }

    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    if (accessToken == null || refreshToken == null) {
      throw Exception('Invalid API response: missing tokens');
    }

    final user = UserModel.fromJson(userData);

    await _storageService.saveTokens(access: accessToken, refresh: refreshToken);

    return LoginResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// Rafraîchit les tokens JWT via l'API.
  Future<void> refreshToken() async {
    final currentRefreshToken = await _storageService.getRefreshToken();
    if (currentRefreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _dataSource.refreshToken(
      refreshToken: currentRefreshToken,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final accessToken = data['access_token'] as String?;
    final newRefreshToken = data['refresh_token'] as String?;
    if (accessToken == null || newRefreshToken == null) {
      throw Exception('Invalid API response: missing tokens');
    }

    await _storageService.saveTokens(
      access: accessToken,
      refresh: newRefreshToken,
    );
  }

  /// Déconnexion : appel API + nettoyage tokens locaux.
  Future<void> logout() async {
    await _dataSource.logout();
    await _storageService.clearTokens();
  }

  /// Enregistre ou met à jour le FCM token du device côté API.
  ///
  /// Best-effort — ne jamais propager l'exception au caller.
  Future<void> registerFcmToken(String token) async {
    await _dataSource.registerFcmToken(token);
  }

  /// Met à jour le profil utilisateur.
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    final response = await _dataSource.updateProfile(
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final userData = data['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing user data');
    }

    return UserModel.fromJson(userData);
  }

  /// Récupère le profil utilisateur.
  Future<UserModel> getProfile() async {
    final response = await _dataSource.getProfile();

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    final userData = data['user'];
    if (userData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing user data');
    }

    return UserModel.fromJson(userData);
  }
}
