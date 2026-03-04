import 'dart:io';

import 'package:ppv_app/features/content/data/content_model.dart';
import 'package:ppv_app/features/content/data/content_remote_datasource.dart';
import 'package:ppv_app/features/content/domain/content.dart';

/// Repository contenus — orchestre ContentRemoteDataSource.
class ContentRepository {
  final ContentRemoteDataSource _dataSource;

  ContentRepository({required ContentRemoteDataSource dataSource})
      : _dataSource = dataSource;

  /// Upload une photo et retourne le ContentModel créé.
  Future<ContentModel> uploadPhoto(
    File photo, {
    void Function(int, int)? onProgress,
  }) async {
    final response = await _dataSource.uploadPhoto(
      photo,
      onProgress: onProgress,
    );

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

  /// Accepte les CGU de publication (type "content_publish").
  Future<void> acceptContentPublishTos() async {
    await _dataSource.acceptContentPublishTos();
  }

  /// Met à jour le prix (et le mode vue unique) d'un contenu.
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

  /// Récupère un contenu par son ID.
  Future<ContentModel> getContent(int contentId) async {
    final response = await _dataSource.getContent(contentId);

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

  /// Récupère la liste paginée des contenus de l'utilisateur courant.
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

  /// Récupère une page d'acheteurs d'un contenu.
  /// Retourne un record Dart 3 : buyers, nextCursor, hasMore.
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

  /// Supprime un contenu (soft-delete côté API).
  Future<void> deleteContent(int contentId) async {
    await _dataSource.deleteContent(contentId);
  }

  /// Upload une vidéo et retourne le ContentModel créé.
  Future<ContentModel> uploadVideo(
    File video, {
    void Function(int, int)? onProgress,
  }) async {
    final response = await _dataSource.uploadVideo(
      video,
      onProgress: onProgress,
    );

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
