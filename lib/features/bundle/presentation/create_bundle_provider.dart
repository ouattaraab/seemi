import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/bundle/data/bundle_repository.dart';
import 'package:ppv_app/features/bundle/domain/bundle.dart';

/// Provider — état du formulaire de création de bundle.
class CreateBundleProvider extends ChangeNotifier {
  String title = '';
  String description = '';
  List<int> selectedContentIds = [];
  int discountPercent = 0;
  bool isSaving = false;
  String? error;

  void setTitle(String value) {
    title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setDiscountPercent(int value) {
    discountPercent = value;
    notifyListeners();
  }

  void toggleContent(int id, bool selected) {
    if (selected) {
      if (!selectedContentIds.contains(id)) {
        selectedContentIds = [...selectedContentIds, id];
      }
    } else {
      selectedContentIds = selectedContentIds.where((e) => e != id).toList();
    }
    notifyListeners();
  }

  /// Valide et envoie la création du bundle.
  /// Retourne le [Bundle] créé en cas de succès, null sinon.
  Future<Bundle?> save(BundleRepository repo) async {
    if (title.trim().isEmpty) {
      error = 'Le titre est obligatoire.';
      notifyListeners();
      return null;
    }
    if (selectedContentIds.isEmpty) {
      error = 'Sélectionnez au moins un contenu.';
      notifyListeners();
      return null;
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final bundle = await repo.createBundle(
        title: title.trim(),
        description: description.trim().isEmpty ? null : description.trim(),
        contentIds: selectedContentIds,
        discountPercent: discountPercent,
      );
      return bundle;
    } catch (e) {
      error = 'Erreur lors de la création du bundle. Réessayez.';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
