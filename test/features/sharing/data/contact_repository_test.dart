import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';

/// Test double utilisé pour valider le contrat de l'interface.
class _VerifyingContactRepository implements ContactRepository {
  bool _permissionResult = true;
  final List<ContactInfo> _contacts;
  String? lastSharedUrl;
  List<String>? lastSharedPhones;

  _VerifyingContactRepository({
    bool permissionResult = true,
    List<ContactInfo> contacts = const [],
  })  : _permissionResult = permissionResult,
        _contacts = contacts;

  @override
  Future<bool> requestPermission() async => _permissionResult;

  @override
  Future<List<ContactInfo>> getContacts() async => _contacts;

  @override
  Future<void> shareViaContact(
      String shareUrl, List<String> phoneNumbers) async {
    lastSharedUrl = shareUrl;
    lastSharedPhones = phoneNumbers;
  }
}

void main() {
  group('ContactRepository', () {
    test('ContactRepositoryImpl implements ContactRepository', () {
      // Vérifie que l'implémentation satisfait le contrat de l'interface.
      // Les appels réels aux plugins (flutter_contacts, permission_handler,
      // url_launcher) sont couverts par les tests d'intégration.
      final repo = ContactRepositoryImpl();
      expect(repo, isA<ContactRepository>());
    });

    test('interface contract: requestPermission retourne un bool', () async {
      final repo = _VerifyingContactRepository(permissionResult: true);
      final result = await repo.requestPermission();
      expect(result, isTrue);
    });

    test('interface contract: getContacts retourne la liste fournie', () async {
      const contacts = [
        ContactInfo(name: 'Alice', phoneNumber: '+22501000001'),
        ContactInfo(name: 'Bob', phoneNumber: '+22501000002'),
      ];
      final repo = _VerifyingContactRepository(contacts: contacts);
      final result = await repo.getContacts();
      expect(result.length, 2);
      expect(result.first.name, 'Alice');
    });

    test('interface contract: shareViaContact transmet url et numéros',
        () async {
      final repo = _VerifyingContactRepository();
      const url = 'https://ppv.example.com/c/abc123';
      const phones = ['+22501000001', '+22501000002'];

      await repo.shareViaContact(url, phones);

      expect(repo.lastSharedUrl, url);
      expect(repo.lastSharedPhones, phones);
    });

    test('ContactInfo stocke nom et numéro correctement', () {
      const info = ContactInfo(name: 'Alice', phoneNumber: '+22501000001');
      expect(info.name, 'Alice');
      expect(info.phoneNumber, '+22501000001');
    });
  });
}
