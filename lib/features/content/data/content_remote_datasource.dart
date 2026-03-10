import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Source de données distante pour les contenus.
class ContentRemoteDataSource {
  final Dio _dio;

  ContentRemoteDataSource({required Dio dio}) : _dio = dio;

  // ─── Upload photo ─────────────────────────────────────────────────────────

  /// Upload une photo vers POST /api/v1/contents.
  /// [fileHash] : SHA-256 hex du fichier (détection de doublon côté serveur).
  Future<Map<String, dynamic>> uploadPhoto(
    File photo, {
    void Function(int, int)? onProgress,
    String? fileHash,
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
          headers: fileHash != null ? {'X-Content-Hash': fileHash} : null,
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Upload vidéo (standard — fichiers compressés ≤ 50 Mo) ───────────────

  /// Upload une vidéo compressée + sa miniature vers POST /api/v1/contents.
  /// [thumbnail] : bytes JPEG extraits côté client (optionnel).
  /// [fileHash]  : SHA-256 hex du fichier original avant compression.
  Future<Map<String, dynamic>> uploadVideo(
    File video, {
    void Function(int, int)? onProgress,
    Uint8List? thumbnail,
    String? fileHash,
  }) async {
    final map = <String, dynamic>{
      'file': await MultipartFile.fromFile(
        video.path,
        filename: video.path.split('/').last,
      ),
      'type': 'video',
    };

    if (thumbnail != null) {
      map['thumbnail'] = MultipartFile.fromBytes(
        thumbnail,
        filename: 'thumbnail.jpg',
      );
    }

    final formData = FormData.fromMap(map);

    try {
      final response = await _dio.post(
        '/contents',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 180),
          headers: fileHash != null ? {'X-Content-Hash': fileHash} : null,
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Upload chunked ───────────────────────────────────────────────────────

  /// Initialise une session d'upload chunked.
  /// Retourne `{upload_id, total_chunks, chunk_size}` ou `{duplicate:true, content:{...}}`.
  Future<Map<String, dynamic>> initChunkedUpload({
    required String type,
    required String originalName,
    required int totalSize,
    String? fileHash,
  }) async {
    try {
      final response = await _dio.post(
        '/uploads/init',
        data: {
          'type':          type,
          'original_name': originalName,
          'total_size':    totalSize,
          if (fileHash != null) 'file_hash': fileHash,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Envoie un chunk (données brutes) vers PUT /uploads/{uploadId}/chunk/{index}.
  Future<Map<String, dynamic>> uploadChunk(
    String uploadId,
    int index,
    Uint8List chunkData, {
    void Function(int, int)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'chunk': MultipartFile.fromBytes(
        chunkData,
        filename: 'chunk_$index.part',
      ),
    });

    try {
      // POST au lieu de PUT : PHP ne remplit pas $_FILES pour les requêtes PUT
      final response = await _dio.post(
        '/uploads/$uploadId/chunk/$index',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Récupère l'état d'une session chunked (pour reprise après reconnexion).
  Future<Map<String, dynamic>> getChunkedUploadStatus(String uploadId) async {
    try {
      final response = await _dio.get('/uploads/$uploadId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Finalise l'upload chunked : assemble les chunks et crée le Content.
  /// [thumbnail] : miniature JPEG client (optionnelle).
  Future<Map<String, dynamic>> completeChunkedUpload(
    String uploadId, {
    Uint8List? thumbnail,
  }) async {
    final map = <String, dynamic>{};
    if (thumbnail != null) {
      map['thumbnail'] = MultipartFile.fromBytes(thumbnail, filename: 'thumbnail.jpg');
    }

    try {
      final response = await _dio.post(
        '/uploads/$uploadId/complete',
        data: map.isEmpty ? null : FormData.fromMap(map),
        options: Options(
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Statut contenu (backoff exponentiel) ────────────────────────────────

  /// Statut allégé : `{id, status, blur_url}`.
  /// Utilisé après upload pour surveiller la fin du traitement avec backoff côté client.
  Future<Map<String, dynamic>> getContentStatus(int contentId) async {
    try {
      final response = await _dio.get('/contents/$contentId/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Méthodes existantes ─────────────────────────────────────────────────

  /// Accepte les CGU de publication via POST /api/v1/auth/accept-tos.
  Future<Map<String, dynamic>> acceptContentPublishTos() async {
    try {
      final response = await _dio.post(
        '/auth/accept-tos',
        data: {'type': 'content_publish'},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
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
      throw _parseError(e);
    }
  }

  /// Met à jour un contenu avec des champs arbitraires via PUT /api/v1/contents/{id}.
  Future<Map<String, dynamic>> updateContent(
    int contentId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _dio.put(
        '/contents/$contentId',
        data: fields,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Récupère la liste paginée des acheteurs d'un contenu.
  Future<Map<String, dynamic>> getContentBuyers(
    int contentId, {
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/contents/$contentId/buyers',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Récupère un contenu via GET /api/v1/contents/{id}.
  Future<Map<String, dynamic>> getContent(int contentId) async {
    try {
      final response = await _dio.get('/contents/$contentId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Récupère la liste des contenus de l'utilisateur courant.
  Future<Map<String, dynamic>> getMyContents({String? cursor}) async {
    try {
      final response = await _dio.get(
        '/contents',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  /// Supprime un contenu via DELETE /api/v1/contents/{id}.
  Future<void> deleteContent(int contentId) async {
    try {
      await _dio.delete('/contents/$contentId');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Exception _parseError(DioException e) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      return Exception(responseData['message'] as String? ?? 'Erreur serveur');
    }
    // Timeout ou pas de réponse : donner un message précis selon le type d'erreur
    return switch (e.type) {
      DioExceptionType.connectionTimeout => Exception('Délai de connexion dépassé. Vérifiez votre réseau.'),
      DioExceptionType.sendTimeout      => Exception('Envoi trop lent. Réessayez sur Wi-Fi.'),
      DioExceptionType.receiveTimeout   => Exception('Le serveur ne répond pas. Réessayez.'),
      DioExceptionType.connectionError  => Exception('Pas de connexion réseau.'),
      _                                 => Exception('Erreur de connexion au serveur (${e.type.name}).'),
    };
  }
}
