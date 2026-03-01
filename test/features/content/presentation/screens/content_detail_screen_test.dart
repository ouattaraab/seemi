import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/content_detail_screen.dart';
import 'package:ppv_app/features/payment/data/payment_repository.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';

// ─── Repository mocks — contenu ──────────────────────────────────────────────

class _SuccessRepository extends PublicContentRepository {
  final PublicContentData _data;
  _SuccessRepository(this._data);

  @override
  Future<PublicContentData> getPublicContent(String slug) async => _data;
}

class _NotFoundRepository extends PublicContentRepository {
  @override
  Future<PublicContentData> getPublicContent(String slug) async {
    throw const ApiException(
      message: 'Not found',
      statusCode: 404,
      errorCode: 'NOT_FOUND',
    );
  }
}

class _NetworkErrorRepository extends PublicContentRepository {
  @override
  Future<PublicContentData> getPublicContent(String slug) async {
    throw const NetworkException(
      message: 'Pas de connexion internet.',
      type: NetworkExceptionType.noConnection,
    );
  }
}

// ─── Repository mock — paiement (idle) ───────────────────────────────────────

class _IdlePaymentRepository extends PaymentRepository {
  @override
  Future<PaymentInitiationResult> initiatePayment({
    required String slug,
    required String email,
    String? phone,
  }) async =>
      throw UnimplementedError('Non appelé dans ces tests');
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _buildScreen(PublicContentRepository repo, {String slug = 'test-slug'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ContentDetailProvider(slug: slug, repository: repo),
      ),
      ChangeNotifierProvider(
        create: (_) => PaymentProvider(repository: _IdlePaymentRepository()),
      ),
    ],
    child: const MaterialApp(
      home: ContentDetailScreen(),
    ),
  );
}

PublicContentData _makeContent({
  int priceFcfa = 500,
  int viewCount = 5,
  String creatorName = 'Alice Dupont',
  String? blurPathUrl,
  String type = 'photo',
}) {
  return PublicContentData(
    id: 1,
    slug: 'test-slug',
    type: type,
    blurPathUrl: blurPathUrl,
    priceFcfa: priceFcfa,
    creatorName: creatorName,
    viewCount: viewCount,
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ContentDetailScreen', () {
    testWidgets('affiche un indicateur de chargement pendant le fetch',
        (tester) async {
      final repo = _SuccessRepository(_makeContent());

      await tester.pumpWidget(_buildScreen(repo));

      // pump() sans settle → indicateur visible avant la résolution async
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('affiche le nom du créateur et le prix après chargement',
        (tester) async {
      final repo = _SuccessRepository(_makeContent(
        creatorName: 'Bob Créateur',
        priceFcfa: 1500,
      ));

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Bob Créateur'), findsOneWidget);
      expect(
        find.textContaining('Payez 1500 FCFA pour la voir.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche le bouton Payer avec le prix correct', (tester) async {
      final repo = _SuccessRepository(_makeContent(priceFcfa: 750));

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn-pay')), findsOneWidget);
      expect(find.text('Débloquer · 750 FCFA'), findsOneWidget);
    });

    testWidgets('affiche le compteur de vues (pluriel)', (tester) async {
      final repo = _SuccessRepository(_makeContent(viewCount: 12));

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('affiche le compteur de vues (singulier)', (tester) async {
      final repo = _SuccessRepository(_makeContent(viewCount: 1));

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('affiche l\'état d\'erreur quand le slug est introuvable',
        (tester) async {
      final repo = _NotFoundRepository();

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('introuvable'), findsOneWidget);
      expect(find.byKey(const Key('btn-pay')), findsNothing);
    });

    testWidgets('affiche l\'état d\'erreur sur erreur réseau', (tester) async {
      final repo = _NetworkErrorRepository();

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      expect(find.textContaining('connexion'), findsOneWidget);
    });

    testWidgets('tap btn-pay ouvre le BottomSheet de paiement', (tester) async {
      final repo = _SuccessRepository(_makeContent(priceFcfa: 1000));

      await tester.pumpWidget(_buildScreen(repo));
      await tester.pumpAndSettle();

      // Scroll jusqu'au bouton (il peut être hors-écran sur la taille de test)
      await tester.ensureVisible(find.byKey(const Key('btn-pay')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-pay')));
      await tester.pumpAndSettle();

      // Le BottomSheet contient le bouton de confirmation
      expect(find.byKey(const Key('btn-confirm-pay')), findsOneWidget);
    });
  });
}
