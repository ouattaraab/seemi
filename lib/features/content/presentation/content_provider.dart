import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppv_app/features/content/data/content_repository.dart';
import 'package:ppv_app/features/content/domain/content.dart';

// C2 — Clés de cache SharedPreferences pour les stats hors-ligne
const _kCacheStatsViews = 'cache_stats_total_views';
const _kCacheStatsSales = 'cache_stats_total_sales';

// Clés pour la reprise d'upload chunked
const _kPendingUploadId   = 'pending_chunked_upload_id';
const _kPendingUploadType = 'pending_chunked_upload_type';

/// Phase d'upload visible par l'UI.
enum UploadPhase { idle, compressing, uploading, processing }

/// Provider de gestion des contenus — pattern loading/error/data avec progression upload.
class ContentProvider extends ChangeNotifier {
  final ContentRepository _repository;

  ContentProvider({required ContentRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading    = false;
  bool _isPublishing = false;
  String? _error;

  // Phase courante visible par l'UI
  UploadPhase _uploadPhase    = UploadPhase.idle;
  double?     _uploadProgress; // 0.0–1.0 (compression ou transfert)

  Content? _lastUploadedContent;
  Content? _lastPublishedContent;
  bool _disposed = false;

  // --- List state ---
  List<Content> _myContents     = [];
  bool          _isFetchingContents = false;
  String?       _contentsError;
  String?       _nextCursor;
  bool          _hasMore = false;

  // C2 — Stats cached pour affichage hors-ligne
  int _cachedTotalViews = 0;
  int _cachedTotalSales = 0;

  bool         get isLoading             => _isLoading;
  bool         get isPublishing          => _isPublishing;
  String?      get error                 => _error;
  UploadPhase  get uploadPhase           => _uploadPhase;
  double?      get uploadProgress        => _uploadProgress;
  Content?     get lastUploadedContent   => _lastUploadedContent;
  Content?     get lastPublishedContent  => _lastPublishedContent;

  List<Content> get myContents       => _myContents;
  bool          get isFetchingContents => _isFetchingContents;
  String?       get contentsError    => _contentsError;
  bool          get hasMore          => _hasMore;

  int get totalViews => _myContents.isNotEmpty
      ? _myContents.fold(0, (s, c) => s + c.viewCount)
      : _cachedTotalViews;
  int get totalSales => _myContents.isNotEmpty
      ? _myContents.fold(0, (s, c) => s + c.purchaseCount)
      : _cachedTotalSales;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ─── Upload photo ─────────────────────────────────────────────────────────

  /// Upload une photo via le repository.
  /// [fileHash] : SHA-256 hex pour détection doublon.
  Future<bool> uploadPhoto(File photo, {String? fileHash}) async {
    _isLoading    = true;
    _uploadPhase  = UploadPhase.uploading;
    _error        = null;
    _uploadProgress = 0;
    _safeNotify();

    try {
      _lastUploadedContent = await _repository.uploadPhoto(
        photo,
        fileHash: fileHash,
        onProgress: (sent, total) {
          _uploadProgress = total > 0 ? sent / total : null;
          _safeNotify();
        },
      );
      return true;
    } catch (e) {
      _error = _clean(e, 'Erreur lors du téléchargement de la photo.');
      return false;
    } finally {
      _isLoading      = false;
      _uploadPhase    = UploadPhase.idle;
      _uploadProgress = null;
      _safeNotify();
    }
  }

  // ─── Upload vidéo chunked ────────────────────────────────────────────────

  /// Upload une vidéo en chunks avec reprise sur coupure réseau.
  ///
  /// Phases :
  ///   1. Compression (délégué à l'écran avant appel)
  ///   2. Init session chunked (+ détection doublon)
  ///   3. Upload chunk par chunk avec progression 0→1
  ///   4. Complete (assemblage côté serveur)
  ///
  /// [video]      : fichier compressé.
  /// [thumbnail]  : miniature JPEG extraite côté client.
  /// [fileHash]   : SHA-256 du fichier AVANT compression.
  /// [onChunkSent]: callback(chunkIndex, totalChunks) pour la progression fine.
  Future<bool> uploadVideoChunked(
    File video, {
    Uint8List? thumbnail,
    String? fileHash,
    void Function(int sent, int total)? onChunkSent,
  }) async {
    _isLoading      = true;
    _uploadPhase    = UploadPhase.uploading;
    _error          = null;
    _uploadProgress = 0;
    _safeNotify();

    final prefs = await SharedPreferences.getInstance();

    try {
      final fileSize = await video.length();
      final fileName = video.path.split('/').last;

      // 1. Init (détection doublon incluse)
      final (session, duplicate) = await _repository.initChunkedUpload(
        type:         'video',
        originalName: fileName,
        totalSize:    fileSize,
        fileHash:     fileHash,
      );

      // Doublon détecté → réutiliser le contenu existant directement
      if (duplicate != null) {
        _lastUploadedContent = duplicate;
        return true;
      }

      final uploadId    = session!.uploadId;
      final chunkSize   = session.chunkSize;
      final totalChunks = session.totalChunks;

      // Sauvegarder l'uploadId pour reprise potentielle
      await prefs.setString(_kPendingUploadId, uploadId);
      await prefs.setString(_kPendingUploadType, 'video');

      // 2. Vérifier si un upload partiel existe (reprise)
      int startChunk = 0;
      try {
        final status = await _repository.getChunkedUploadStatus(uploadId);
        if (status.status == 'uploading' && status.receivedChunks > 0) {
          startChunk = status.receivedChunks;
        }
      } catch (_) {
        // Ignore — on repart du début si le statut est inaccessible
      }

      // 3. Upload chunk par chunk — lecture séquentielle sans tout charger en RAM
      final raf = await video.open(mode: FileMode.read);
      try {
        for (int i = startChunk; i < totalChunks; i++) {
          final start = i * chunkSize;
          final end   = (start + chunkSize).clamp(0, fileSize);
          await raf.setPosition(start);
          final chunk = await raf.read(end - start);

          // Retry par chunk (3 tentatives)
          bool chunkOk = false;
          for (int attempt = 0; attempt < 3 && !chunkOk; attempt++) {
            try {
              await _repository.uploadChunk(uploadId, i, chunk);
              chunkOk = true;
            } catch (_) {
              if (attempt == 2) rethrow;
              await Future.delayed(Duration(seconds: attempt + 1));
            }
          }

          _uploadProgress = (i + 1) / totalChunks;
          onChunkSent?.call(i + 1, totalChunks);
          _safeNotify();
        }
      } finally {
        await raf.close();
      }

      // 4. Complete
      _lastUploadedContent = await _repository.completeChunkedUpload(
        uploadId,
        thumbnail: thumbnail,
      );

      // Nettoyer la sauvegarde de reprise
      await prefs.remove(_kPendingUploadId);
      await prefs.remove(_kPendingUploadType);

      return true;
    } catch (e) {
      _error = _clean(e, 'Erreur lors du téléchargement de la vidéo.');
      return false;
    } finally {
      _isLoading      = false;
      _uploadPhase    = UploadPhase.idle;
      _uploadProgress = null;
      _safeNotify();
    }
  }

  // ─── Compatibilité ancienne API ──────────────────────────────────────────

  /// Conservé pour compatibilité — délègue vers uploadVideoChunked.
  Future<bool> uploadVideo(File video) async {
    return uploadVideoChunked(video);
  }

  // ─── Statut blur (backoff exponentiel) ───────────────────────────────────

  /// Surveille la fin du traitement blur avec backoff exponentiel.
  /// Retourne le blur_url quand disponible, ou null après épuisement des tentatives.
  ///
  /// Intervalles : 1 s, 2 s, 3 s, 4 s, 5 s, 6 s, 7 s, 8 s (total ≈ 36 s, 8 polls)
  Future<String?> pollBlurWithBackoff(int contentId) async {
    const maxAttempts = 8;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final waitSecs = attempt + 1; // 1, 2, 3, 4, 5, 6, 7, 8
      await Future.delayed(Duration(seconds: waitSecs));

      try {
        final result = await _repository.getContentStatus(contentId);
        if (result.blurUrl != null) {
          return result.blurUrl;
        }
        // Si le statut revient 'draft' (échec traitement), on arrête
        if (result.status == 'draft') return null;
      } catch (_) {
        // Continuer même si une requête échoue
      }
    }
    return null; // Timeout atteint
  }

  // ─── Publication ─────────────────────────────────────────────────────────

  /// Accepte les CGU et définit le prix du contenu.
  Future<bool> publishContent(
    int contentId,
    int priceInFcfa, {
    bool viewOnce = false,
  }) async {
    _isPublishing = true;
    _error        = null;
    _safeNotify();

    try {
      await _repository.acceptContentPublishTos();
      _lastPublishedContent = await _repository.updateContentPrice(
        contentId,
        priceInFcfa * 100,
        viewOnce: viewOnce,
      );
      return true;
    } catch (e) {
      _error = _clean(e, 'Erreur lors de la publication.');
      return false;
    } finally {
      _isPublishing = false;
      _safeNotify();
    }
  }

  // ─── Liste des contenus ───────────────────────────────────────────────────

  Future<void> loadMyContents({bool refresh = false}) async {
    if (_isFetchingContents) return;
    if (!refresh && !_hasMore && _myContents.isNotEmpty) return;

    if (refresh || _myContents.isEmpty) {
      await _restoreStatsFromCache();
    }

    if (refresh) {
      _myContents  = [];
      _nextCursor  = null;
      _hasMore     = false;
    }

    _isFetchingContents = true;
    _contentsError      = null;
    _safeNotify();

    try {
      final result = await _repository.getMyContents(cursor: _nextCursor);
      _myContents  = refresh ? result.contents : [..._myContents, ...result.contents];
      _nextCursor  = result.nextCursor;
      _hasMore     = result.hasMore;
      await _persistStatsToCache();
    } catch (e) {
      _contentsError = _clean(e, 'Erreur lors du chargement des contenus.');
    } finally {
      _isFetchingContents = false;
      _safeNotify();
    }
  }

  Future<void> _persistStatsToCache() async {
    try {
      final prefs  = await SharedPreferences.getInstance();
      final views  = _myContents.fold(0, (s, c) => s + c.viewCount);
      final sales  = _myContents.fold(0, (s, c) => s + c.purchaseCount);
      await prefs.setInt(_kCacheStatsViews, views);
      await prefs.setInt(_kCacheStatsSales, sales);
      _cachedTotalViews = views;
      _cachedTotalSales = sales;
    } catch (_) {}
  }

  Future<void> _restoreStatsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedTotalViews = prefs.getInt(_kCacheStatsViews) ?? 0;
      _cachedTotalSales = prefs.getInt(_kCacheStatsSales) ?? 0;
    } catch (_) {}
  }

  // --- Delete ---
  bool    _isDeletingContent  = false;
  String? _deleteContentError;

  bool    get isDeletingContent  => _isDeletingContent;
  String? get deleteContentError => _deleteContentError;

  Future<bool> deleteContent(int contentId) async {
    if (_isDeletingContent) return false;
    _isDeletingContent  = true;
    _deleteContentError = null;
    _safeNotify();

    try {
      await _repository.deleteContent(contentId);
      _myContents.removeWhere((c) => c.id == contentId);
      return true;
    } catch (e) {
      _deleteContentError = _clean(e, 'Erreur lors de la suppression.');
      return false;
    } finally {
      _isDeletingContent = false;
      _safeNotify();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<Content?> getContent(int id) async {
    try {
      return await _repository.getContent(id);
    } catch (_) {
      return null;
    }
  }

  Future<({List<ContentBuyer> buyers, String? nextCursor, bool hasMore})>
      getContentBuyers(int contentId, {String? cursor}) async {
    return _repository.getContentBuyers(contentId, cursor: cursor);
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  void resetUploadState() {
    _isLoading           = false;
    _error               = null;
    _uploadPhase         = UploadPhase.idle;
    _uploadProgress      = null;
    _lastUploadedContent = null;
    _lastPublishedContent = null;
    _safeNotify();
  }

  String _clean(Object e, String fallback) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    return raw.isNotEmpty ? raw : fallback;
  }
}
