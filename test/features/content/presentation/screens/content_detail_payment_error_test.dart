import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/screens/content_detail_screen.dart';
import 'package:ppv_app/features/payment/data/payment_repository.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';

// ─── Repository mocks ────────────────────────────────────────────────────────

class _ContentSuccessRepository extends PublicContentRepository {
  final PublicContentData _data;
  _ContentSuccessRepository(this._data);

  @override
  Future<PublicContentData> getPublicContent(String slug) async => _data;
}

/// Retourne paymentStatus='failed' immédiatement — simule un paiement échoué.
class _FailedCheckRepository extends PaymentRepository {
  @override
  Future<PaymentStatusResult> checkPaymentStatus({
    required String slug,
    required String reference,
  }) async =>
      const PaymentStatusResult(isPaid: false, paymentStatus: 'failed');
}

// ─── Helper ──────────────────────────────────────────────────────────────────

PublicContentData _makeContent() => PublicContentData(
      id: 1,
      slug: 'test-slug',
      type: 'photo',
      blurPathUrl: null,
      priceFcfa: 500,
      creatorName: 'Alice Dupont',
      viewCount: 3,
    );

Widget _buildScreenWithFailedPayment() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ContentDetailProvider(
          slug: 'test-slug',
          repository: _ContentSuccessRepository(_makeContent()),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => PaymentProvider(repository: _FailedCheckRepository()),
      ),
    ],
    child: const MaterialApp(
      home: ContentDetailScreen(paymentReference: 'ref-001'),
    ),
  );
}

/// Avance le temps pour permettre au chargement du contenu et à la vérification
/// du paiement (1s de délai initial) de se terminer.
Future<void> _advancePastPaymentCheck(WidgetTester tester) async {
  await tester.pumpWidget(_buildScreenWithFailedPayment());
  // Avancer après le délai initial (1s) du checkPaymentAndReveal
  await tester.pump(const Duration(seconds: 2));
  // Traiter le rebuild UI suite à paymentFailed=true
  await tester.pump();
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ContentDetailScreen — payment error UI (Story 5.5)', () {
    // AC 1, 5 — Message d'erreur visible après échec
    testWidgets('affiche le bandeau d\'erreur quand paymentFailed=true',
        (tester) async {
      await _advancePastPaymentCheck(tester);

      expect(
        find.text(
          'Le paiement n\'a pas abouti. Réessayez ou changez de moyen de paiement.',
        ),
        findsOneWidget,
      );
    });

    // AC 7, 8 — Le bouton Payer est masqué (remplacé par le bandeau)
    testWidgets('masque le bouton Payer quand paymentFailed=true',
        (tester) async {
      await _advancePastPaymentCheck(tester);

      expect(find.byKey(const Key('btn-pay')), findsNothing);
    });

    // AC 7 — Le bouton Réessayer réinitialise l'état et rouvre le dialog
    testWidgets('tap Réessayer remet le provider à zéro et ouvre le dialog de paiement',
        (tester) async {
      await _advancePastPaymentCheck(tester);

      expect(find.byKey(const Key('btn-retry-payment')), findsOneWidget);

      // Le bouton peut être en dehors du viewport — scroller jusqu'à lui
      await tester.ensureVisible(find.byKey(const Key('btn-retry-payment')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-retry-payment')));
      await tester.pumpAndSettle();

      // Le BottomSheet de paiement doit être ouvert
      expect(find.byKey(const Key('btn-confirm-pay')), findsOneWidget);
    });
  });
}
