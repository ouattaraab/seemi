import 'package:flutter/material.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';

/// Provider pour l'écran de détail de contenu public (deep link /c/:slug).
///
/// Conforme au pattern obligatoire : état loading / error / data + ChangeNotifier.
class ContentDetailProvider extends ChangeNotifier {
  final PublicContentRepository _repository;

  PublicContentData? _content;
  bool _isLoading = true;
  String? _error;

  PublicContentData? get content => _content;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ContentDetailProvider({
    required String slug,
    required PublicContentRepository repository,
  }) : _repository = repository {
    _loadContent(slug);
  }

  Future<void> _loadContent(String slug) async {
    try {
      final data = await _repository.getPublicContent(slug);
      _content = data;
    } on ApiException catch (e) {
      _error = e.isNotFound
          ? 'Ce contenu est introuvable ou n\'est plus disponible.'
          : 'Une erreur est survenue. Réessayez.';
    } catch (_) {
      _error = 'Impossible de charger le contenu. Vérifiez votre connexion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
