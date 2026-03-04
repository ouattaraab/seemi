import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppv_app/features/content/data/content_repository.dart';
import 'package:ppv_app/features/content/domain/content.dart';

// C2 — Clés de cache SharedPreferences pour les stats hors-ligne
const _kCacheStatsViews    = 'cache_stats_total_views';
const _kCacheStatsSales    = 'cache_stats_total_sales';

/// Provider de gestion des contenus — pattern loading/error/data avec progression upload.
class ContentProvider extends ChangeNotifier {
  final ContentRepository _repository;

  ContentProvider({required ContentRepository repository})
      : _repository = repository;

  // --- State ---
  bool _isLoading = false;
  bool _isPublishing = false;
  String? _error;
  double? _uploadProgress;
  Content? _lastUploadedContent;
  Content? _lastPublishedContent;
  bool _disposed = false;

  // --- List state ---
  List<Content> _myContents = [];
  bool _isFetchingContents = false;
  String? _contentsError;
  String? _nextCursor;
  bool _hasMore = false;

  // C2 — Stats cached pour affichage hors-ligne
  int _cachedTotalViews = 0;
  int _cachedTotalSales = 0;

  bool get isLoading => _isLoading;
  bool get isPublishing => _isPublishing;
  String? get error => _error;
  double? get uploadProgress => _uploadProgress;
  Content? get lastUploadedContent => _lastUploadedContent;
  Content? get lastPublishedContent => _lastPublishedContent;

  List<Content> get myContents => _myContents;
  bool get isFetchingContents => _isFetchingContents;
  String? get contentsError => _contentsError;
  bool get hasMore => _hasMore;

  // C2 — Getters stats offline (valeurs live si contenus chargés, sinon cache)
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

  /// Upload une photo via le repository.
  Future<bool> uploadPhoto(File photo) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0;
    _safeNotify();

    try {
      _lastUploadedContent = await _repository.uploadPhoto(
        photo,
        onProgress: (sent, total) {
          _uploadProgress = total > 0 ? sent / total : null;
          _safeNotify();
        },
      );
      return true;
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _error = raw.isNotEmpty ? raw : 'Erreur lors du téléchargement de la photo.';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = null;
      _safeNotify();
    }
  }

  /// Upload une vidéo via le repository.
  Future<bool> uploadVideo(File video) async {
    _isLoading = true;
    _error = null;
    _uploadProgress = 0;
    _safeNotify();

    try {
      _lastUploadedContent = await _repository.uploadVideo(
        video,
        onProgress: (sent, total) {
          _uploadProgress = total > 0 ? sent / total : null;
          _safeNotify();
        },
      );
      return true;
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _error = raw.isNotEmpty ? raw : 'Erreur lors du téléchargement de la vidéo.';
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = null;
      _safeNotify();
    }
  }

  /// Accepte les CGU de publication et définit le prix du contenu.
  ///
  /// [priceInFcfa] est en FCFA — la conversion en centimes est faite ici.
  /// [viewOnce] active le mode vue unique (consultation unique pour l'acheteur).
  Future<bool> publishContent(
    int contentId,
    int priceInFcfa, {
    bool viewOnce = false,
  }) async {
    _isPublishing = true;
    _error = null;
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
      final raw = e.toString().replaceFirst('Exception: ', '');
      _error = raw.isNotEmpty ? raw : 'Erreur lors de la publication.';
      return false;
    } finally {
      _isPublishing = false;
      _safeNotify();
    }
  }

  /// Charge la liste des contenus de l'utilisateur courant avec pagination cursor-based.
  /// Affiche les stats cached immédiatement si disponibles (C2 — mode hors-ligne).
  ///
  /// [refresh] = true recharge depuis le début.
  Future<void> loadMyContents({bool refresh = false}) async {
    if (_isFetchingContents) return;
    if (!refresh && !_hasMore && _myContents.isNotEmpty) return;

    // C2 — Restaurer les stats cached avant la requête réseau
    if (refresh || _myContents.isEmpty) {
      await _restoreStatsFromCache();
    }

    if (refresh) {
      _myContents = [];
      _nextCursor = null;
      _hasMore = false;
    }

    _isFetchingContents = true;
    _contentsError = null;
    _safeNotify();

    try {
      final result = await _repository.getMyContents(cursor: _nextCursor);
      _myContents = refresh
          ? result.contents
          : [..._myContents, ...result.contents];
      _nextCursor = result.nextCursor;
      _hasMore = result.hasMore;
      // C2 — Persister les stats après chargement réseau réussi
      await _persistStatsToCache();
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _contentsError =
          raw.isNotEmpty ? raw : 'Erreur lors du chargement des contenus.';
      // C2 — En mode hors-ligne, les stats cached restent affichées via totalViews/totalSales
    } finally {
      _isFetchingContents = false;
      _safeNotify();
    }
  }

  Future<void> _persistStatsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final views = _myContents.fold(0, (s, c) => s + c.viewCount);
      final sales = _myContents.fold(0, (s, c) => s + c.purchaseCount);
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

  // --- Delete state ---
  bool _isDeletingContent = false;
  String? _deleteContentError;

  bool get isDeletingContent => _isDeletingContent;
  String? get deleteContentError => _deleteContentError;

  /// Supprime un contenu et le retire de la liste locale.
  /// Retourne [true] en cas de succès, [false] sinon.
  Future<bool> deleteContent(int contentId) async {
    if (_isDeletingContent) return false;
    _isDeletingContent = true;
    _deleteContentError = null;
    _safeNotify();

    try {
      await _repository.deleteContent(contentId);
      _myContents.removeWhere((c) => c.id == contentId);
      return true;
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _deleteContentError =
          raw.isNotEmpty ? raw : 'Erreur lors de la suppression.';
      return false;
    } finally {
      _isDeletingContent = false;
      _safeNotify();
    }
  }

  /// Récupère un contenu par son ID (utilisé pour le polling du blur).
  Future<Content?> getContent(int id) async {
    try {
      return await _repository.getContent(id);
    } catch (_) {
      return null;
    }
  }

  /// Récupère la liste des acheteurs d'un contenu (vue créateur).
  Future<List<ContentBuyer>?> getContentBuyers(int contentId) async {
    try {
      return await _repository.getContentBuyers(contentId);
    } catch (_) {
      return null;
    }
  }

  /// Reset l'état d'erreur.
  void clearError() {
    _error = null;
    _safeNotify();
  }

  /// Reset l'état complet d'upload.
  void resetUploadState() {
    _isLoading = false;
    _error = null;
    _uploadProgress = null;
    _lastUploadedContent = null;
    _lastPublishedContent = null;
    _safeNotify();
  }
}
