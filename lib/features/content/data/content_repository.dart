import 'dart:io';
import 'dart:typed_data';

import 'package:ppv_app/features/content/data/content_model.dart';
import 'package:ppv_app/features/content/data/content_remote_datasource.dart';
import 'package:ppv_app/features/content/domain/content.dart';

/// Résultat d'un upload vidéo chunked.
class ChunkedUploadSession {
  final String uploadId;
  final int totalChunks;
  final int chunkSize;

  const ChunkedUploadSession({
    required this.uploadId,
    required this.totalChunks,
    required this.chunkSize,
  });
}

/// Repository contenus — orchestre ContentRemoteDataSource.
class ContentRepository {
  final ContentRemoteDataSource _dataSource;

  ContentRepository({required ContentRemoteDataSource dataSource})
      : _dataSource = dataSource;

  // ─── Photos ──────────────────────────────────────────────────────────────

  /// Upload une photo et retourne le ContentModel créé.
  /// [fileHash] : SHA-256 hex pour détection de doublons.
  Future<ContentModel> uploadPhoto(
    File photo, {
    void Function(int, int)? onProgress,
    String? fileHash,
  }) async {
    final response = await _dataSource.uploadPhoto(
      photo,
      onProgress: onProgress,
      fileHash: fileHash,
    );
    return _extractContent(response);
  }

  // ─── Vidéos (upload standard — fichier compressé ≤ 50 Mo) ────────────────

  /// Upload une vidéo compressée avec miniature client.
  /// [thumbnail] : bytes JPEG extraits via video_thumbnail.
  /// [fileHash]  : SHA-256 du fichier AVANT compression.
  Future<ContentModel> uploadVideo(
    File video, {
    void Function(int, int)? onProgress,
    Uint8List? thumbnail,
    String? fileHash,
  }) async {
    final response = await _dataSource.uploadVideo(
      video,
      onProgress: onProgress,
      thumbnail: thumbnail,
      fileHash: fileHash,
    );
    return _extractContent(response);
  }

  // ─── Vidéos (upload chunked — gros fichiers, reprise réseau) ─────────────

  /// Initialise un upload chunked. Détecte les doublons avant tout transfert.
  /// Si doublon : retourne (null, existingContent).
  Future<(ChunkedUploadSession?, ContentModel?)> initChunkedUpload({
    required String type,
    required String originalName,
    required int totalSize,
    String? fileHash,
  }) async {
    final response = await _dataSource.initChunkedUpload(
      type: type,
      originalName: originalName,
      totalSize: totalSize,
      fileHash: fileHash,
    );

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Réponse API invalide');

    // Doublon détecté
    if (data['duplicate'] == true) {
      final contentData = data['content'];
      if (contentData is Map<String, dynamic>) {
        return (null, ContentModel.fromJson(contentData));
      }
    }

    return (
      ChunkedUploadSession(
        uploadId:    data['upload_id'] as String,
        totalChunks: data['total_chunks'] as int,
        chunkSize:   data['chunk_size'] as int,
      ),
      null,
    );
  }

  /// Envoie un chunk individuel. Retourne le pourcentage de progression (0-100).
  Future<int> uploadChunk(
    String uploadId,
    int index,
    Uint8List chunkData, {
    void Function(int, int)? onProgress,
  }) async {
    final response = await _dataSource.uploadChunk(
      uploadId,
      index,
      chunkData,
      onProgress: onProgress,
    );
    final data = response['data'] as Map<String, dynamic>?;
    return data?['progress'] as int? ?? 0;
  }

  /// Récupère l'état d'un upload en cours (pour reprise).
  Future<({int receivedChunks, int totalChunks, String status})>
      getChunkedUploadStatus(String uploadId) async {
    final response = await _dataSource.getChunkedUploadStatus(uploadId);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return (
      receivedChunks: data['received_chunks'] as int? ?? 0,
      totalChunks:    data['total_chunks'] as int? ?? 0,
      status:         data['status'] as String? ?? 'uploading',
    );
  }

  /// Finalise l'upload chunked et retourne le Content créé.
  Future<ContentModel> completeChunkedUpload(
    String uploadId, {
    Uint8List? thumbnail,
  }) async {
    final response = await _dataSource.completeChunkedUpload(
      uploadId,
      thumbnail: thumbnail,
    );
    return _extractContent(response);
  }

  // ─── Statut contenu (backoff exponentiel) ────────────────────────────────

  /// Retourne `{status, blurUrl, processingStatus, hlsUrl, bunnyVideoId}`
  /// pour surveiller la fin du traitement blur et du transcodage HLS (F13).
  Future<({String status, String? blurUrl, String? processingStatus, String? hlsUrl, String? bunnyVideoId})>
      getContentStatus(int contentId) async {
    final response = await _dataSource.getContentStatus(contentId);
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return (
      status:           data['status'] as String? ?? 'processing',
      blurUrl:          data['blur_url'] as String?,
      processingStatus: data['processing_status'] as String?,
      hlsUrl:           data['hls_url'] as String?,
      bunnyVideoId:     data['bunny_video_id'] as String?,
    );
  }

  // ─── Méthodes existantes ─────────────────────────────────────────────────

  Future<void> acceptContentPublishTos() async {
    await _dataSource.acceptContentPublishTos();
  }

  Future<ContentModel> updateContentPrice(
    int contentId,
    int priceInCentimes, {
    bool viewOnce = false,
  }) async {
    final response = await _dataSource.updateContentPrice(
      contentId,
      priceInCentimes,
      viewOnce: viewOnce,
    );
    return _extractContent(response);
  }

  Future<ContentModel> updateContent(
    int contentId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _dataSource.updateContent(contentId, fields);
    return _extractContent(response);
  }

  Future<ContentModel> getContent(int contentId) async {
    final response = await _dataSource.getContent(contentId);
    return _extractContent(response);
  }

  Future<({List<ContentModel> contents, String? nextCursor, bool hasMore})>
      getMyContents({String? cursor}) async {
    final response = await _dataSource.getMyContents(cursor: cursor);
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }
    final rawList = data['contents'];
    if (rawList is! List) {
      throw Exception('Invalid API response: contents is not a list');
    }
    return (
      contents: rawList
          .cast<Map<String, dynamic>>()
          .map(ContentModel.fromJson)
          .toList(),
      nextCursor: data['next_cursor'] as String?,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<({List<ContentBuyer> buyers, String? nextCursor, bool hasMore})>
      getContentBuyers(int contentId, {String? cursor}) async {
    final response =
        await _dataSource.getContentBuyers(contentId, cursor: cursor);
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }
    final rawList = data['buyers'];
    if (rawList is! List) {
      throw Exception('Invalid API response: buyers is not a list');
    }
    return (
      buyers: rawList
          .cast<Map<String, dynamic>>()
          .map(ContentBuyer.fromJson)
          .toList(),
      nextCursor: data['next_cursor'] as String?,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<void> deleteContent(int contentId) async {
    await _dataSource.deleteContent(contentId);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  ContentModel _extractContent(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }
    final contentData = data['content'];
    if (contentData is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing content data');
    }
    return ContentModel.fromJson(contentData);
  }
}
