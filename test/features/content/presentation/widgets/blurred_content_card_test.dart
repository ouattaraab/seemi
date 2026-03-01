import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/widgets/blurred_content_card.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';

class _MockShareRepository implements ShareRepository {
  final List<String> sharedUrls = [];

  @override
  Future<void> shareContent(String shareUrl) async {
    sharedUrls.add(shareUrl);
  }
}

void main() {
  late _MockShareRepository mockShareRepo;

  setUp(() {
    mockShareRepo = _MockShareRepository();
    // Mock clipboard platform channel pour éviter MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async => null,
    );
  });

  Widget buildCard(Content content) {
    return MaterialApp(
      home: Scaffold(
        body: Provider<ShareRepository>.value(
          value: mockShareRepo,
          child: BlurredContentCard(content: content),
        ),
      ),
    );
  }

  const baseContent = Content(
    id: 1,
    type: 'photo',
    status: 'active',
    viewCount: 12,
    purchaseCount: 3,
    price: 50000,
  );

  const contentWithShareUrl = Content(
    id: 5,
    type: 'photo',
    status: 'active',
    viewCount: 4,
    purchaseCount: 1,
    price: 20000,
    shareUrl: 'https://ppv.example.com/c/abc123xyz',
  );

  group('BlurredContentCard', () {
    testWidgets('displays price in FCFA', (tester) async {
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.text('500 FCFA'), findsOneWidget);
    });

    testWidgets('displays view count', (tester) async {
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.text('12 vues'), findsOneWidget);
    });

    testWidgets('displays purchase count', (tester) async {
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.text('3 ventes'), findsOneWidget);
    });

    testWidgets('displays total gained', (tester) async {
      // price=50000 centimes = 500 FCFA × 3 ventes = 1500 FCFA
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.text('1\u202f500 FCFA gagné'), findsOneWidget);
    });

    testWidgets('shows placeholder when blur_url is null', (tester) async {
      const noUrl = Content(
        id: 2,
        type: 'photo',
        status: 'active',
        viewCount: 0,
        purchaseCount: 0,
      );
      await tester.pumpWidget(buildCard(noUrl));
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });

    testWidgets('shows "Prix non défini" when price is null', (tester) async {
      const noPrice = Content(
        id: 3,
        type: 'photo',
        status: 'active',
        viewCount: 0,
        purchaseCount: 0,
      );
      await tester.pumpWidget(buildCard(noPrice));
      expect(find.text('Prix non défini'), findsOneWidget);
    });

    testWidgets('displays singular "vue" for 1 view', (tester) async {
      const oneView = Content(
        id: 4,
        type: 'photo',
        status: 'active',
        viewCount: 1,
        purchaseCount: 1,
        price: 10000,
      );
      await tester.pumpWidget(buildCard(oneView));
      expect(find.text('1 vue'), findsOneWidget);
      expect(find.text('1 vente'), findsOneWidget);
    });

    // ─── Bouton Partager ──────────────────────────────────────────────────────

    testWidgets('shows share button when share_url is present', (tester) async {
      await tester.pumpWidget(buildCard(contentWithShareUrl));
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('hides share button when share_url is null', (tester) async {
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.byIcon(Icons.share_rounded), findsNothing);
    });

    testWidgets('share button calls ShareRepository with share url',
        (tester) async {
      await tester.pumpWidget(buildCard(contentWithShareUrl));
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.pump();

      expect(mockShareRepo.sharedUrls.length, 1);
      expect(mockShareRepo.sharedUrls.first,
          'https://ppv.example.com/c/abc123xyz');
    });

    testWidgets('share button calls ShareRepository when tapped', (tester) async {
      await tester.pumpWidget(buildCard(contentWithShareUrl));
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.pump();

      expect(mockShareRepo.sharedUrls.length, 1);
      expect(mockShareRepo.sharedUrls.first,
          'https://ppv.example.com/c/abc123xyz');
    });

    // ─── Icône Copier le lien ────────────────────────────────────────────────

    testWidgets('shows copy link icon when share_url is present',
        (tester) async {
      await tester.pumpWidget(buildCard(contentWithShareUrl));
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });

    testWidgets('hides copy link icon when share_url is null', (tester) async {
      await tester.pumpWidget(buildCard(baseContent));
      expect(find.byIcon(Icons.link_rounded), findsNothing);
    });

    testWidgets('copy link icon shows snackbar "Lien copié !"', (tester) async {
      await tester.pumpWidget(buildCard(contentWithShareUrl));
      await tester.tap(find.byIcon(Icons.link_rounded));
      await tester.pump();

      expect(find.text('Lien copié !'), findsOneWidget);
    });
  });
}
