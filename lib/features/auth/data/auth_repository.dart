import 'dart:io';

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

  /// Inscription avec email + mot de passe.
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dataSource.registerWithEmailPassword(
      firstName:             firstName,
      lastName:              lastName,
      phone:                 phone,
      email:                 email,
      dateOfBirth:           dateOfBirth,
      password:              password,
      passwordConfirmation:  passwordConfirmation,
    );

    return _parseAuthResponse(response);
  }

  /// Connexion avec email/téléphone + mot de passe.
  ///
  /// Propage [AuthApiException] si ACCOUNT_NOT_FOUND, INVALID_PASSWORD ou ACCOUNT_DISABLED.
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await _dataSource.loginWithEmailPassword(
      emailOrPhone: emailOrPhone,
      password:     password,
    );

    final result = _parseAuthResponse(response);
    return LoginResult(
      user:         result.user,
      accessToken:  result.accessToken,
      refreshToken: result.refreshToken,
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
      firstName:   firstName,
      lastName:    lastName,
      dateOfBirth: dateOfBirth,
      document:    document,
    );
    return _parseUserFromResponse(response);
  }

  /// Enregistre l'acceptation des CGU.
  Future<TosAcceptanceModel> acceptTos({required String type}) async {
    final response = await _dataSource.acceptTos(type: type);
    final data = response['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid API response');
    return TosAcceptanceModel.fromJson(data);
  }

  /// Rafraîchit les tokens JWT.
  Future<void> refreshToken() async {
    final currentRefreshToken = await _storageService.getRefreshToken();
    if (currentRefreshToken == null) throw Exception('No refresh token');

    final response = await _dataSource.refreshToken(refreshToken: currentRefreshToken);
    final data = response['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid API response');

    final accessToken  = data['access_token']  as String?;
    final refreshToken = data['refresh_token'] as String?;
    if (accessToken == null || refreshToken == null) throw Exception('Missing tokens');

    await _storageService.saveTokens(access: accessToken, refresh: refreshToken);
  }

  /// Déconnexion : appel API + nettoyage tokens locaux.
  Future<void> logout() async {
    await _dataSource.logout();
    await _storageService.clearTokens();
  }

  /// Enregistre ou met à jour le FCM token du device.
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
      lastName:  lastName,
      avatar:    avatar,
    );
    return _parseUserFromResponse(response);
  }

  /// Récupère le profil utilisateur.
  Future<UserModel> getProfile() async {
    final response = await _dataSource.getProfile();
    return _parseUserFromResponse(response);
  }

  // --- Helpers ---

  RegisterResult _parseAuthResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid API response: missing data');

    final userData     = data['user'];
    final accessToken  = data['access_token']  as String?;
    final refreshToken = data['refresh_token'] as String?;

    if (userData is! Map<String, dynamic>) throw Exception('Missing user data');
    if (accessToken == null || refreshToken == null) throw Exception('Missing tokens');

    final user = UserModel.fromJson(userData);
    _storageService.saveTokens(access: accessToken, refresh: refreshToken);

    return RegisterResult(
      user:         user,
      accessToken:  accessToken,
      refreshToken: refreshToken,
    );
  }

  UserModel _parseUserFromResponse(Map<String, dynamic> response) {
    final data     = response['data'];
    final userData = (data is Map<String, dynamic>) ? data['user'] : null;
    if (userData is! Map<String, dynamic>) throw Exception('Invalid API response: missing user');
    return UserModel.fromJson(userData);
  }
}
