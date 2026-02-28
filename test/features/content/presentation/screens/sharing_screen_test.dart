import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/content/presentation/screens/sharing_screen.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

class _MockShareRepository implements ShareRepository {
  final List<String> sharedUrls = [];

  @override
  Future<void> shareContent(String shareUrl) async {
    sharedUrls.add(shareUrl);
  }
}

class _MockContactRepository implements ContactRepository {
  bool permissionGranted;
  List<ContactInfo> contacts;
  List<String>? lastSharedPhones;

  _MockContactRepository({
    this.permissionGranted = true,
    this.contacts = const [],
  });

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<List<ContactInfo>> getContacts() async => contacts;

  @override
  Future<void> shareViaContact(
      String shareUrl, List<String> phoneNumbers) async {
    lastSharedPhones = phoneNumbers;
  }
}

void main() {
  const testShareUrl = 'https://ppv.example.com/c/abc123xyz';

  late _MockShareRepository mockShareRepo;
  late _MockContactRepository mockContactRepo;

  setUp(() {
    mockShareRepo = _MockShareRepository();
    mockContactRepo = _MockContactRepository();
    // Mock clipboard platform channel pour éviter MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
  });

  Widget buildScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<ShareRepository>.value(value: mockShareRepo),
          Provider<ContactRepository>.value(value: mockContactRepo),
        ],
        child: const SharingScreen(shareUrl: testShareUrl),
      ),
    );
  }

  group('SharingScreen', () {
    testWidgets('displays share url in selectable text', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text(testShareUrl), findsOneWidget);
    });

    testWidgets('shows Partager button', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Partager'), findsOneWidget);
    });

    testWidgets('Partager button calls ShareRepository with share url',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Partager'));
      await tester.pump();

      expect(mockShareRepo.sharedUrls.length, 1);
      expect(mockShareRepo.sharedUrls.first, testShareUrl);
    });

    testWidgets('Partager button shows snackbar after sharing', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Partager'));
      await tester.pump();

      expect(find.text('Lien partagé !'), findsOneWidget);
    });

    testWidgets('shows Copier le lien button', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Copier le lien'), findsOneWidget);
    });

    testWidgets('Copier le lien button shows snackbar "Lien copié !"',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Copier le lien'));
      await tester.pump();

      expect(find.text('Lien copié !'), findsOneWidget);
    });

    testWidgets("shows Retour à l'accueil button", (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text("Retour à l'accueil"), findsOneWidget);
    });

    // ─── Bouton Partager à un contact ────────────────────────────────────────

    testWidgets('shows Partager à un contact button', (tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Partager à un contact'), findsOneWidget);
    });

    testWidgets(
        'Partager à un contact: permission accordée → bottom sheet ouverte',
        (tester) async {
      mockContactRepo = _MockContactRepository(
        permissionGranted: true,
        contacts: [
          const ContactInfo(name: 'Alice', phoneNumber: '+22501000001'),
        ],
      );
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Partager à un contact'));
      await tester.pump(); // attend requestPermission
      await tester.pump(); // attend getContacts + setState

      // La bottom sheet est ouverte et affiche le contact
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets(
        'Partager à un contact: permission refusée → snackbar affiché',
        (tester) async {
      mockContactRepo =
          _MockContactRepository(permissionGranted: false);
      await tester.pumpWidget(buildScreen());
      await tester.tap(find.text('Partager à un contact'));
      await tester.pump();

      expect(
        find.text(
            'Permission contacts refusée. Activez-la dans les paramètres.'),
        findsOneWidget,
      );
      expect(find.text('Paramètres'), findsOneWidget);
    });
  });
}
