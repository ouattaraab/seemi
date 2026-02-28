import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Information minimale d'un contact utile pour le partage.
class ContactInfo {
  final String name;
  final String phoneNumber;

  const ContactInfo({required this.name, required this.phoneNumber});
}

/// Contrat de partage par contact — abstrait pour permettre le mock en tests.
abstract class ContactRepository {
  /// Demande la permission d'accéder aux contacts. Retourne true si accordée.
  Future<bool> requestPermission();

  /// Retourne la liste des contacts ayant au moins un numéro de téléphone.
  Future<List<ContactInfo>> getContacts();

  /// Ouvre l'app SMS avec le lien pré-rempli pour les numéros sélectionnés.
  Future<void> shareViaContact(String shareUrl, List<String> phoneNumbers);
}

/// Implémentation utilisant flutter_contacts, permission_handler et url_launcher.
class ContactRepositoryImpl implements ContactRepository {
  @override
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  @override
  Future<List<ContactInfo>> getContacts() async {
    final contacts =
        await FlutterContacts.getContacts(withProperties: true);
    return contacts
        .where((c) => c.phones.isNotEmpty)
        .map((c) => ContactInfo(
              name: c.displayName,
              phoneNumber: c.phones.first.number,
            ))
        .toList();
  }

  @override
  Future<void> shareViaContact(
      String shareUrl, List<String> phoneNumbers) async {
    final numbers = phoneNumbers.join(',');
    final message = Uri.encodeComponent(
        'Découvrez ce contenu exclusif sur PPV ! Payez pour le voir 👀\n$shareUrl');
    final uri = Uri.parse('sms:$numbers?body=$message');
    if (!await canLaunchUrl(uri)) {
      throw Exception(
          "Impossible d'ouvrir l'application SMS sur cet appareil.");
    }
    await launchUrl(uri);
  }
}
