import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

/// Source de données distante pour l'authentification.
///
/// Orchestre Firebase Auth (OTP) et l'API Laravel (JWT).
class AuthRemoteDataSource {
  final firebase.FirebaseAuth _firebaseAuth;
  final Dio _dio;

  AuthRemoteDataSource({
    firebase.FirebaseAuth? firebaseAuth,
    required Dio dio,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _dio = dio;

  /// Envoie un OTP au numéro de téléphone via Firebase Auth.
  ///
  /// Retourne le [verificationId] via le callback [onCodeSent].
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase.FirebaseAuthException error)
        onVerificationFailed,
    required void Function(firebase.PhoneAuthCredential credential)
        onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Vérifie le code OTP saisi par l'utilisateur et se connecte à Firebase.
  ///
  /// Retourne le [UserCredential] Firebase.
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = firebase.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  /// Récupère le Firebase ID token de l'utilisateur connecté.
  Future<String?> getFirebaseIdToken() async {
    return _firebaseAuth.currentUser?.getIdToken();
  }

  /// Enregistre l'utilisateur côté API Laravel avec le Firebase token.
  ///
  /// Retourne la réponse de `POST /api/v1/auth/register`.
  Future<Map<String, dynamic>> registerWithFirebaseToken({
    required String firebaseToken,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'firebase_token': firebaseToken,
          // ignore: use_null_aware_elements
          if (firstName != null) 'first_name': firstName,
          // ignore: use_null_aware_elements
          if (lastName != null) 'last_name': lastName,
        },
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

  /// Soumet les données KYC à l'API.
  Future<Map<String, dynamic>> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'id_document': await MultipartFile.fromFile(
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
  Future<Map<String, dynamic>> acceptTos({
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/accept-tos',
        data: {
          'type': type,
        },
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

  /// Authentifie un utilisateur existant côté API avec le Firebase token.
  ///
  /// Retourne la réponse de `POST /api/v1/auth/login`.
  Future<Map<String, dynamic>> login({
    required String firebaseToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'firebase_token': firebaseToken},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final code = responseData['code'] as String?;
        final message =
            responseData['message'] as String? ?? 'Erreur serveur';
        throw AuthApiException(message: message, code: code);
      }
      throw const AuthApiException(message: 'Erreur de connexion au serveur');
    }
  }

  /// Rafraîchit le JWT access token.
  ///
  /// Retourne la réponse de `POST /api/v1/auth/refresh`.
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
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

  /// Déconnecte l'utilisateur côté API (invalide le JWT).
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Ignorer les erreurs lors du logout — on clear les tokens localement
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
    if (lastName != null) map['last_name'] = lastName;
    if (avatar != null) {
      map['avatar'] = await MultipartFile.fromFile(
        avatar.path,
        filename: avatar.path.split('/').last,
      );
    }
    final formData = FormData.fromMap(map);

    try {
      final response = await _dio.put('/profile', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Récupère le profil utilisateur depuis l'API.
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
  ///
  /// POST /api/v1/profile/fcm-token
  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post<void>(
        '/profile/fcm-token',
        data: {'token': token},
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
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
