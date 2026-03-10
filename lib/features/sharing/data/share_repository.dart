import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contrat de partage de contenu — abstrait pour permettre le mock en tests.
abstract class ShareRepository {
  Future<void> shareContent(String shareUrl);
  Future<bool> shareToWhatsApp({
    required String shareUrl,
    required int priceFcfa,
    required String creatorName,
  });
}

/// Implémentation utilisant la share sheet native via `share_plus`.
class ShareRepositoryImpl implements ShareRepository {
  @override
  Future<void> shareContent(String shareUrl) async {
    await Share.share(
      'Découvrez ce contenu exclusif sur SeeMi ! Payez pour le voir 👀\n$shareUrl',
      subject: 'Contenu SeeMi',
    );
  }

  @override
  Future<bool> shareToWhatsApp({
    required String shareUrl,
    required int priceFcfa,
    required String creatorName,
  }) async {
    final message = Uri.encodeComponent(
      '🔒 Contenu exclusif de $creatorName sur SeeMi !\n'
      '💰 Prix : $priceFcfa FCFA\n'
      '👁 Débloquer ici : $shareUrl',
    );

    // Try native WhatsApp first
    final nativeUri = Uri.parse('whatsapp://send?text=$message');
    if (await canLaunchUrl(nativeUri)) {
      await launchUrl(nativeUri);
      return true;
    }

    // Fallback to web WhatsApp
    final webUri = Uri.parse('https://api.whatsapp.com/send?text=$message');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }
}
