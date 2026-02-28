import 'package:share_plus/share_plus.dart';

/// Contrat de partage de contenu — abstrait pour permettre le mock en tests.
abstract class ShareRepository {
  Future<void> shareContent(String shareUrl);
}

/// Implémentation utilisant la share sheet native via `share_plus`.
class ShareRepositoryImpl implements ShareRepository {
  @override
  Future<void> shareContent(String shareUrl) async {
    await Share.share(
      'Découvrez ce contenu exclusif sur PPV ! Payez pour le voir 👀\n$shareUrl',
      subject: 'Contenu PPV',
    );
  }
}
