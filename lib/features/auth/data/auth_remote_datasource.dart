import 'dart:io';

import 'package:dio/dio.dart';

/// Source de données distante pour l'authentification.
///
/// Utilise email/mot de passe (pas Firebase OTP).
class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Inscrit un nouvel utilisateur avec email + mot de passe.
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'first_name':             firstName,
          'last_name':              lastName,
          'phone':                  phone,
          'email':                  email,
          'date_of_birth':          dateOfBirth,
          'password':               password,
          'password_confirmation':  passwordConfirmation,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final errors = responseData['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstField = errors.values.first;
          final message = firstField is List ? firstField.first as String : firstField.toString();
          throw AuthApiException(message: message);
        }
        final message = responseData['message'] as String? ?? 'Erreur serveur';
        throw AuthApiException(message: message);
      }
      throw const AuthApiException(message: 'Erreur de connexion au serveur');
    }
  }

  /// Connecte un utilisateur avec email ou téléphone + mot de passe.
  Future<Map<String, dynamic>> loginWithEmailPassword({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email_or_phone': emailOrPhone,
          'password':       password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final code    = responseData['code'] as String?;
        final message = responseData['message'] as String? ?? 'Erreur serveur';
        throw AuthApiException(message: message, code: code);
      }
      throw const AuthApiException(message: 'Erreur de connexion au serveur');
    }
  }

  /// Soumet les données KYC à l'API.
  Future<Map<String, dynamic>> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    final formData = FormData.fromMap({
      'first_name':    firstName,
      'last_name':     lastName,
      'date_of_birth': dateOfBirth,
      'id_document':   await MultipartFile.fromFile(
        document.path,
        filename: document.path.split('/').last,
      ),
    });

    try {
      final response = await _dio.post('/profile/kyc', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Enregistre l'acceptation des CGU.
  Future<Map<String, dynamic>> acceptTos({required String type}) async {
    try {
      final response = await _dio.post('/auth/accept-tos', data: {'type': type});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Rafraîchit le JWT access token.
  Future<Map<String, dynamic>> refreshToken({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Déconnecte l'utilisateur côté API.
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Ignorer — on clear les tokens localement
    }
  }

  /// Met à jour le profil utilisateur.
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    final map = <String, dynamic>{};
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null)  map['last_name']  = lastName;
    if (avatar != null) {
      map['avatar'] = await MultipartFile.fromFile(
        avatar.path,
        filename: avatar.path.split('/').last,
      );
    }

    try {
      final response = await _dio.put('/profile', data: FormData.fromMap(map));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Récupère le profil utilisateur.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Enregistre ou met à jour le FCM token du device.
  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post<void>('/profile/fcm-token', data: {'token': token});
    } on DioException {
      // Best-effort — ignorer silencieusement
    }
  }
}

/// Exception API d'authentification avec code d'erreur.
class AuthApiException implements Exception {
  final String message;
  final String? code;

  const AuthApiException({required this.message, this.code});

  @override
  String toString() => message;
}
