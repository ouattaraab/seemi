import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/content/data/content_repository.dart';
import 'package:ppv_app/features/content/domain/content.dart';

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
  Future<bool> publishContent(int contentId, int priceInFcfa) async {
    _isPublishing = true;
    _error = null;
    _safeNotify();

    try {
      await _repository.acceptContentPublishTos();
      _lastPublishedContent =
          await _repository.updateContentPrice(contentId, priceInFcfa * 100);
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
  ///
  /// [refresh] = true recharge depuis le début.
  Future<void> loadMyContents({bool refresh = false}) async {
    if (_isFetchingContents) return;
    if (!refresh && !_hasMore && _myContents.isNotEmpty) return;

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
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _contentsError =
          raw.isNotEmpty ? raw : 'Erreur lors du chargement des contenus.';
    } finally {
      _isFetchingContents = false;
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
