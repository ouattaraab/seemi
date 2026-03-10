import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/bundle/data/bundle_repository.dart';
import 'package:ppv_app/features/bundle/domain/bundle.dart';

/// Provider — liste des bundles du créateur connecté.
class MyBundlesProvider extends ChangeNotifier {
  final BundleRepository _repository;

  MyBundlesProvider({BundleRepository? repository})
      : _repository = repository ?? BundleRepositoryImpl();

  List<Bundle> bundles = [];
  bool isLoading = false;
  String? error;

  /// Charge la liste des bundles depuis l'API.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      bundles = await _repository.myBundles();
    } catch (e) {
      error = 'Impossible de charger vos bundles. Réessayez.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Supprime un bundle de façon optimiste (suppression locale immédiate,
  /// rollback si l'API échoue). Retourne true si succès.
  Future<bool> deleteBundle(int id) async {
    final index = bundles.indexWhere((b) => b.id == id);
    if (index < 0) return false;

    final removed = bundles[index];
    bundles.removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteBundle(id);
      return true;
    } catch (_) {
      // Rollback
      bundles.insert(index, removed);
      notifyListeners();
      return false;
    }
  }
}
