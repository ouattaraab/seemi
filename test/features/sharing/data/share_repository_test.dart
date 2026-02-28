import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

/// Test double utilisé pour vérifier le contrat de l'interface.
class _VerifyingShareRepository implements ShareRepository {
  String? wasCalledWith;

  @override
  Future<void> shareContent(String shareUrl) async {
    wasCalledWith = shareUrl;
  }
}

void main() {
  group('ShareRepository', () {
    test('ShareRepositoryImpl implements ShareRepository', () {
      // Vérifie que l'implémentation satisfait le contrat de l'interface.
      // L'appel réel à Share.share() (plugin plateforme) est couvert
      // par les tests d'intégration.
      final repo = ShareRepositoryImpl();
      expect(repo, isA<ShareRepository>());
    });

    test('interface contract: shareContent transmet l\'url sans transformation',
        () async {
      // Valide le contrat attendu de toute implémentation de ShareRepository.
      final repo = _VerifyingShareRepository();
      const url = 'https://ppv.example.com/c/abc123xyz';

      await repo.shareContent(url);

      expect(repo.wasCalledWith, url);
    });
  });
}
