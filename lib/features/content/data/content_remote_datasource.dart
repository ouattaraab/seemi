import 'dart:io';

import 'package:dio/dio.dart';

/// Source de données distante pour les contenus.
class ContentRemoteDataSource {
  final Dio _dio;

  ContentRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Upload une photo vers POST /api/v1/contents.
  Future<Map<String, dynamic>> uploadPhoto(
    File photo, {
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
      'type': 'photo',
    });

    try {
      final response = await _dio.post(
        '/contents',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
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

  /// Accepte les CGU de publication via POST /api/v1/auth/accept-tos.
  Future<Map<String, dynamic>> acceptContentPublishTos() async {
    try {
      final response = await _dio.post(
        '/auth/accept-tos',
        data: {'type': 'content_publish'},
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

  /// Met à jour le prix (et optionnellement le mode vue unique) via PUT /api/v1/contents/{id}.
  Future<Map<String, dynamic>> updateContentPrice(
    int contentId,
    int priceInCentimes, {
    bool viewOnce = false,
  }) async {
    try {
      final response = await _dio.put(
        '/contents/$contentId',
        data: {'price': priceInCentimes, 'view_once': viewOnce},
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

  /// Récupère la liste des acheteurs d'un contenu via GET /api/v1/contents/{id}/buyers.
  Future<Map<String, dynamic>> getContentBuyers(int contentId) async {
    try {
      final response = await _dio.get('/contents/$contentId/buyers');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Récupère un contenu via GET /api/v1/contents/{id}.
  Future<Map<String, dynamic>> getContent(int contentId) async {
    try {
      final response = await _dio.get('/contents/$contentId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Récupère la liste des contenus de l'utilisateur courant via GET /api/v1/contents.
  Future<Map<String, dynamic>> getMyContents({String? cursor}) async {
    try {
      final response = await _dio.get(
        '/contents',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
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

  /// Supprime un contenu via DELETE /api/v1/contents/{id}.
  Future<void> deleteContent(int contentId) async {
    try {
      await _dio.delete('/contents/$contentId');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Upload une vidéo vers POST /api/v1/contents.
  Future<Map<String, dynamic>> uploadVideo(
    File video, {
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        video.path,
        filename: video.path.split('/').last,
      ),
      'type': 'video',
    });

    try {
      final response = await _dio.post(
        '/contents',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 120),
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
}
