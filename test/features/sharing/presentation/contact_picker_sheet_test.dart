import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/presentation/contact_picker_sheet.dart';

class _MockContactRepository implements ContactRepository {
  final List<ContactInfo> contacts;
  List<String>? lastSharedPhones;
  String? lastSharedUrl;

  _MockContactRepository({this.contacts = const []});

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<ContactInfo>> getContacts() async => contacts;

  @override
  Future<void> shareViaContact(
      String shareUrl, List<String> phoneNumbers) async {
    lastSharedUrl = shareUrl;
    lastSharedPhones = phoneNumbers;
  }
}

class _ThrowingContactRepository implements ContactRepository {
  final List<ContactInfo> contacts;

  _ThrowingContactRepository({required this.contacts});

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<ContactInfo>> getContacts() async => contacts;

  @override
  Future<void> shareViaContact(
      String shareUrl, List<String> phoneNumbers) async {
    throw Exception('SMS non disponible');
  }
}

const _testContacts = [
  ContactInfo(name: 'Alice', phoneNumber: '+22501000001'),
  ContactInfo(name: 'Bob', phoneNumber: '+22501000002'),
];

void main() {
  const testShareUrl = 'https://ppv.example.com/c/abc123xyz';

  late _MockContactRepository mockRepo;

  setUp(() {
    mockRepo = _MockContactRepository(contacts: _testContacts);
  });

  Widget buildSheet() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ContactPickerSheet(
            shareUrl: testShareUrl,
            repository: mockRepo,
          ),
        ),
      ),
    );
  }

  group('ContactPickerSheet', () {
    testWidgets('affiche les contacts après chargement', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump(); // attend getContacts

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('affiche les numéros de téléphone des contacts',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(find.text('+22501000001'), findsOneWidget);
      expect(find.text('+22501000002'), findsOneWidget);
    });

    testWidgets('le bouton Envoyer est désactivé si aucun contact sélectionné',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Le bouton "Envoyer (0)" doit exister mais être désactivé
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.textContaining('Envoyer'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('sélection d\'un contact active le bouton Envoyer',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Cocher Alice
      await tester.tap(find.text('Alice'));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.textContaining('Envoyer'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('appuie sur Envoyer appelle shareViaContact avec les numéros',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      // Sélectionner Alice
      await tester.tap(find.text('Alice'));
      await tester.pump();

      // Appuyer sur Envoyer (bouton avec compteur, ex: "Envoyer (1)")
      await tester.tap(find.textContaining('Envoyer ('));
      await tester.pump();

      expect(mockRepo.lastSharedUrl, testShareUrl);
      expect(mockRepo.lastSharedPhones, contains('+22501000001'));
    });

    testWidgets('affiche "Aucun contact" si la liste est vide', (tester) async {
      mockRepo = _MockContactRepository(contacts: []);
      await tester.pumpWidget(buildSheet());
      await tester.pump();

      expect(
        find.text('Aucun contact avec numéro disponible.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'erreur shareViaContact: SnackBar affiché et bouton Annuler réactivé',
        (tester) async {
      final throwingRepo =
          _ThrowingContactRepository(contacts: _testContacts);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ContactPickerSheet(
            shareUrl: testShareUrl,
            repository: throwingRepo,
          ),
        ),
      ));
      await tester.pump();

      // Sélectionner Alice
      await tester.tap(find.text('Alice'));
      await tester.pump();

      // Appuyer sur Envoyer (bouton avec compteur, ex: "Envoyer (1)")
      await tester.tap(find.textContaining('Envoyer ('));
      await tester.pump();

      // SnackBar d'erreur visible
      expect(find.textContaining("Impossible d'envoyer"), findsOneWidget);

      // Bouton Annuler réactivé (_isSending reset à false)
      final cancelButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Annuler'),
      );
      expect(cancelButton.onPressed, isNotNull);
    });
  });
}
