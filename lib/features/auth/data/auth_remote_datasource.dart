import 'dart:io';

import 'package:dio/dio.dart';

/// Source de données distante pour l'authentification.
///
/// Utilise email/mot de passe (pas Firebase OTP).
class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource({required Dio dio}) : _dio = dio;

  // Options partagées pour les endpoints publics (sans Bearer token).
  // LiteSpeed/Hostinger ne parse pas php://input (JSON) sans Authorization header.
  // form-urlencoded est lu nativement par PHP via $_POST, contourne le problème.
  static final _formUrlEncoded = Options(contentType: 'application/x-www-form-urlencoded');

  /// Parse une DioException en AuthApiException avec messages en français.
  AuthApiException _parseAuthError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code    = data['code'] as String?;
      final message = data['message'] as String? ?? 'Erreur serveur';
      return AuthApiException(message: message, code: code);
    }
    // Fallback sur le header retry-after si le corps n'est pas JSON
    if (e.response?.statusCode == 429) {
      final retryAfter = e.response?.headers.value('retry-after');
      final secs = retryAfter != null ? int.tryParse(retryAfter) : null;
      final msg = secs != null
          ? 'Trop de tentatives. Réessayez dans $secs secondes.'
          : 'Trop de tentatives. Réessayez dans quelques instants.';
      return AuthApiException(message: msg, code: 'TOO_MANY_ATTEMPTS');
    }
    // Messages explicites selon le type d'erreur réseau
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const AuthApiException(
          message: 'Le serveur met trop de temps à répondre. Vérifiez votre connexion internet.',
          code: 'TIMEOUT',
        ),
      DioExceptionType.connectionError =>
        const AuthApiException(
          message: 'Impossible de joindre le serveur. Vérifiez votre connexion internet.',
          code: 'NO_CONNECTION',
        ),
      DioExceptionType.badCertificate =>
        const AuthApiException(
          message: 'Certificat de sécurité invalide. Contactez le support.',
          code: 'BAD_CERTIFICATE',
        ),
      _ => const AuthApiException(
          message: 'Une erreur inattendue est survenue. Réessayez.',
          code: 'UNKNOWN',
        ),
    };
  }

  /// Inscrit un nouvel utilisateur avec email + mot de passe.
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String dateOfBirth,
    required String password,
    required String passwordConfirmation,
    String? referralCode,
    required bool consentCgu,
    required bool consentAge,
    required bool consentData,
    bool consentMarketing = false,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        options: _formUrlEncoded,
        data: {
          'first_name':             firstName,
          'last_name':              lastName,
          'phone':                  phone,
          'email':                  email,
          'date_of_birth':          dateOfBirth,
          'password':               password,
          'password_confirmation':  passwordConfirmation,
          if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
          'consent_cgu':      consentCgu ? '1' : '0',
          'consent_age':      consentAge ? '1' : '0',
          'consent_data':     consentData ? '1' : '0',
          'consent_marketing': consentMarketing ? '1' : '0',
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
          throw AuthApiException(message: message, code: responseData['code'] as String?);
        }
        throw _parseAuthError(e);
      }
      throw _parseAuthError(e);
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
        options: _formUrlEncoded,
        data: {
          'email_or_phone': emailOrPhone,
          'password':       password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseAuthError(e);
    }
  }

  /// Soumet les données KYC à l'API.
  Future<Map<String, dynamic>> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
    required File documentBack,
    required File selfie,
  }) async {
    final formData = FormData.fromMap({
      'first_name':      firstName,
      'last_name':       lastName,
      'date_of_birth':   dateOfBirth,
      'id_document':     await MultipartFile.fromFile(
        document.path,
        filename: document.path.split('/').last,
      ),
      'id_document_back': await MultipartFile.fromFile(
        documentBack.path,
        filename: documentBack.path.split('/').last,
      ),
      'selfie':          await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.path.split('/').last,
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

  /// Enregistre un lot de consentements (créateur post-KYC, acheteur, etc.).
  Future<void> acceptConsentsBatch({required List<String> types}) async {
    try {
      await _dio.post('/auth/accept-tos-batch', data: {'types': types});
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

    try {
      if (avatar != null) {
        // PHP ne peuple pas $_FILES pour les requêtes PUT multipart.
        // Laravel method spoofing : POST + _method=PUT pour les uploads fichier.
        map['_method'] = 'PUT';
        map['avatar'] = await MultipartFile.fromFile(
          avatar.path,
          filename: avatar.path.split('/').last,
        );
        final response = await _dio.post('/profile', data: FormData.fromMap(map));
        return response.data as Map<String, dynamic>;
      } else {
        final response = await _dio.put('/profile', data: map.isNotEmpty ? map : null);
        return response.data as Map<String, dynamic>;
      }
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

  /// Envoie un email de réinitialisation de mot de passe.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post('/auth/forgot-password', options: _formUrlEncoded, data: {'email': email});
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw AuthApiException(message: message);
    }
  }

  /// Vérifie si le token de réinitialisation est encore valide, SANS le consommer.
  /// Lance [AuthApiException] si invalide ou expiré.
  Future<void> checkResetToken({
    required String email,
    required String token,
  }) async {
    try {
      await _dio.post('/auth/check-reset-token', options: _formUrlEncoded, data: {
        'email': email,
        'token': token,
      });
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final code    = responseData is Map ? responseData['code']    as String? : null;
      final message = responseData is Map ? responseData['message'] as String? ?? 'Lien invalide' : 'Erreur de connexion au serveur';
      throw AuthApiException(message: message, code: code);
    }
  }

  /// Réinitialise le mot de passe avec le token reçu par email.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post('/auth/reset-password', options: _formUrlEncoded, data: {
        'email':                 email,
        'token':                 token,
        'password':              password,
        'password_confirmation': passwordConfirmation,
      });
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw AuthApiException(message: message);
    }
  }

  /// Change le mot de passe de l'utilisateur connecté.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _dio.put('/auth/password', data: {
        'current_password':          currentPassword,
        'new_password':              newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw AuthApiException(message: message);
    }
  }

  /// Supprime le compte de l'utilisateur connecté (RGPD).
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/auth/delete-account');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw AuthApiException(message: message);
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
