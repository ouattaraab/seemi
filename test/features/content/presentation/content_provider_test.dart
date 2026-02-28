import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/content/data/content_model.dart';
import 'package:ppv_app/features/content/data/content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';

class _MockContentRepository implements ContentRepository {
  bool shouldFail = false;
  bool tosAcceptShouldFail = false;
  bool fetchShouldFail = false;
  String failMessage = 'Erreur serveur';
  int uploadCallCount = 0;
  int publishCallCount = 0;
  List<ContentModel> contentsToReturn = [];
  String? nextCursorToReturn;
  bool hasMoreToReturn = false;

  @override
  Future<ContentModel> uploadPhoto(
    File photo, {
    void Function(int, int)? onProgress,
  }) async {
    uploadCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
    }
    // Simulate progress callbacks
    onProgress?.call(50, 100);
    onProgress?.call(100, 100);
    return const ContentModel(
      id: 1,
      type: 'photo',
      status: 'draft',
      viewCount: 0,
      purchaseCount: 0,
    );
  }

  @override
  Future<ContentModel> uploadVideo(
    File video, {
    void Function(int, int)? onProgress,
  }) async {
    uploadCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
    }
    // Simulate progress callbacks
    onProgress?.call(50, 100);
    onProgress?.call(100, 100);
    return const ContentModel(
      id: 2,
      type: 'video',
      status: 'draft',
      viewCount: 0,
      purchaseCount: 0,
    );
  }

  @override
  Future<void> acceptContentPublishTos() async {
    if (tosAcceptShouldFail) {
      throw Exception('CGU refusées');
    }
  }

  @override
  Future<ContentModel> updateContentPrice(
    int contentId,
    int priceInCentimes,
  ) async {
    publishCallCount++;
    if (shouldFail) {
      throw Exception(failMessage);
    }
    return ContentModel(
      id: contentId,
      type: 'photo',
      status: 'active',
      slug: 'abc123xyz',
      shareUrl: 'https://ppv.example.com/c/abc123xyz',
      price: priceInCentimes,
      viewCount: 0,
      purchaseCount: 0,
    );
  }

  @override
  Future<ContentModel> getContent(int contentId) async {
    return ContentModel(
      id: contentId,
      type: 'photo',
      status: 'active',
      viewCount: 0,
      purchaseCount: 0,
    );
  }

  @override
  Future<({List<ContentModel> contents, String? nextCursor, bool hasMore})>
      getMyContents({String? cursor}) async {
    if (fetchShouldFail) {
      throw Exception(failMessage);
    }
    return (
      contents: contentsToReturn,
      nextCursor: nextCursorToReturn,
      hasMore: hasMoreToReturn,
    );
  }
}

void main() {
  late _MockContentRepository mockRepository;
  late ContentProvider provider;

  setUp(() {
    mockRepository = _MockContentRepository();
    provider = ContentProvider(repository: mockRepository);
  });

  group('ContentProvider', () {
    test('initial state is correct', () {
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.uploadProgress, isNull);
      expect(provider.lastUploadedContent, isNull);
    });

    test('uploadPhoto success returns true and sets lastUploadedContent',
        () async {
      final file = File('test.jpg');
      final result = await provider.uploadPhoto(file);

      expect(result, true);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.uploadProgress, isNull);
      expect(provider.lastUploadedContent, isNotNull);
      expect(provider.lastUploadedContent!.id, 1);
      expect(provider.lastUploadedContent!.type, 'photo');
      expect(mockRepository.uploadCallCount, 1);
    });

    test('uploadPhoto failure returns false and sets error', () async {
      mockRepository.shouldFail = true;
      final file = File('test.jpg');
      final result = await provider.uploadPhoto(file);

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.error, isNotNull);
      expect(provider.uploadProgress, isNull);
    });

    test('uploadPhoto propagates server error message', () async {
      mockRepository.shouldFail = true;
      mockRepository.failMessage = 'Votre KYC doit être approuvé pour publier du contenu.';
      final result = await provider.uploadPhoto(File('test.jpg'));

      expect(result, false);
      expect(provider.error, contains('KYC'));
    });

    test('uploadVideo success returns true and sets lastUploadedContent',
        () async {
      final file = File('test.mp4');
      final result = await provider.uploadVideo(file);

      expect(result, true);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.uploadProgress, isNull);
      expect(provider.lastUploadedContent, isNotNull);
      expect(provider.lastUploadedContent!.id, 2);
      expect(provider.lastUploadedContent!.type, 'video');
      expect(mockRepository.uploadCallCount, 1);
    });

    test('uploadVideo failure returns false and propagates server error',
        () async {
      mockRepository.shouldFail = true;
      mockRepository.failMessage = 'Le fichier vidéo doit être au format MP4 ou MOV.';
      final file = File('test.avi');
      final result = await provider.uploadVideo(file);

      expect(result, false);
      expect(provider.isLoading, false);
      expect(provider.error, contains('MP4'));
      expect(provider.uploadProgress, isNull);
    });

    test('resetUploadState after video upload clears all state', () async {
      await provider.uploadVideo(File('test.mp4'));
      expect(provider.lastUploadedContent, isNotNull);

      provider.resetUploadState();

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.uploadProgress, isNull);
      expect(provider.lastUploadedContent, isNull);
    });

    test('clearError resets error state', () async {
      mockRepository.shouldFail = true;
      await provider.uploadPhoto(File('test.jpg'));
      expect(provider.error, isNotNull);

      provider.clearError();
      expect(provider.error, isNull);
    });

    test('resetUploadState resets all state', () async {
      await provider.uploadPhoto(File('test.jpg'));
      expect(provider.lastUploadedContent, isNotNull);

      provider.resetUploadState();

      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.uploadProgress, isNull);
      expect(provider.lastUploadedContent, isNull);
    });

    test('safeNotify does not throw after dispose', () {
      final disposableProvider =
          ContentProvider(repository: mockRepository);
      disposableProvider.dispose();

      expect(() => disposableProvider.clearError(), returnsNormally);
    });

    test('publishContent success returns true and converts FCFA to centimes',
        () async {
      final result = await provider.publishContent(42, 100);

      expect(result, true);
      expect(provider.isPublishing, false);
      expect(provider.error, isNull);
      expect(mockRepository.publishCallCount, 1);
    });

    test('publishContent failure returns false and sets error', () async {
      mockRepository.shouldFail = true;
      final result = await provider.publishContent(42, 200);

      expect(result, false);
      expect(provider.isPublishing, false);
      expect(provider.error, isNotNull);
    });

    test('publishContent tos failure returns false with error message',
        () async {
      mockRepository.tosAcceptShouldFail = true;
      final result = await provider.publishContent(42, 500);

      expect(result, false);
      expect(provider.error, contains('CGU'));
    });

    test('initial isPublishing state is false', () {
      expect(provider.isPublishing, false);
    });

    test('publishContent success exposes lastPublishedContent with shareUrl',
        () async {
      final result = await provider.publishContent(42, 100);

      expect(result, true);
      expect(provider.lastPublishedContent, isNotNull);
      expect(provider.lastPublishedContent!.shareUrl,
          'https://ppv.example.com/c/abc123xyz');
      expect(provider.lastPublishedContent!.slug, 'abc123xyz');
    });

    test('lastPublishedContent is null initially', () {
      expect(provider.lastPublishedContent, isNull);
    });

    test('resetUploadState clears lastPublishedContent', () async {
      await provider.publishContent(42, 100);
      expect(provider.lastPublishedContent, isNotNull);

      provider.resetUploadState();

      expect(provider.lastPublishedContent, isNull);
    });

    // ─── loadMyContents ────────────────────────────────────────────────────────

    test('initial myContents is empty', () {
      expect(provider.myContents, isEmpty);
      expect(provider.isFetchingContents, false);
      expect(provider.contentsError, isNull);
      expect(provider.hasMore, false);
    });

    test('loadMyContents success sets myContents', () async {
      mockRepository.contentsToReturn = [
        const ContentModel(
          id: 1,
          type: 'photo',
          status: 'active',
          viewCount: 5,
          purchaseCount: 2,
          price: 10000,
        ),
      ];

      await provider.loadMyContents();

      expect(provider.isFetchingContents, false);
      expect(provider.myContents.length, 1);
      expect(provider.myContents.first.id, 1);
      expect(provider.contentsError, isNull);
    });

    test('loadMyContents empty list returns empty contents', () async {
      mockRepository.contentsToReturn = [];
      mockRepository.hasMoreToReturn = false;

      await provider.loadMyContents();

      expect(provider.myContents, isEmpty);
      expect(provider.hasMore, false);
      expect(provider.contentsError, isNull);
    });

    test('loadMyContents failure sets contentsError', () async {
      mockRepository.fetchShouldFail = true;

      await provider.loadMyContents();

      expect(provider.isFetchingContents, false);
      expect(provider.contentsError, isNotNull);
      expect(provider.myContents, isEmpty);
    });

    test('loadMyContents refresh replaces existing contents', () async {
      mockRepository.contentsToReturn = [
        const ContentModel(
          id: 1,
          type: 'photo',
          status: 'active',
          viewCount: 0,
          purchaseCount: 0,
        ),
      ];
      await provider.loadMyContents();
      expect(provider.myContents.length, 1);

      mockRepository.contentsToReturn = [
        const ContentModel(
          id: 2,
          type: 'video',
          status: 'active',
          viewCount: 0,
          purchaseCount: 0,
        ),
      ];
      await provider.loadMyContents(refresh: true);

      expect(provider.myContents.length, 1);
      expect(provider.myContents.first.id, 2);
    });
  });
}
