import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/payout/data/payout_method_model.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/payout/presentation/screens/payout_method_screen.dart';

class _MockPayoutRepository implements PayoutRepository {
  bool shouldFail = false;
  PayoutMethodModel? existingPayoutMethod;

  @override
  Future<PayoutMethodModel> configurePayoutMethod({
    required String payoutType,
    String? provider,
    required String accountNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    if (shouldFail) {
      throw Exception('Erreur serveur');
    }
    return PayoutMethodModel(
      id: 1,
      payoutType: payoutType,
      provider: provider,
      accountNumberMasked: '****0304',
      accountHolderName: accountHolderName,
      bankName: bankName,
      isActive: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<PayoutMethodModel?> getPayoutMethod() async {
    if (shouldFail) {
      throw Exception('Erreur serveur');
    }
    return existingPayoutMethod;
  }
}

void main() {
  late _MockPayoutRepository mockRepository;

  setUp(() {
    mockRepository = _MockPayoutRepository();
  });

  Widget createTestWidget({PayoutMethodProvider? provider}) {
    return ChangeNotifierProvider(
      create: (_) =>
          provider ?? PayoutMethodProvider(repository: mockRepository),
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/payout-method',
          routes: [
            GoRoute(
              path: '/payout-method',
              builder: (_, _) => const PayoutMethodScreen(),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('PayoutMethodScreen', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Moyen de reversement'), findsOneWidget);
    });

    testWidgets('displays type selector with Mobile Money selected by default',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mobile Money'), findsOneWidget);
      expect(find.text('Compte bancaire'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('displays Mobile Money form by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Opérateur'), findsOneWidget);
      expect(find.text('Numéro de téléphone'), findsOneWidget);
      expect(find.text('Nom du titulaire'), findsOneWidget);
    });

    testWidgets('switching to bank account shows bank form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Compte bancaire'));
      await tester.pumpAndSettle();

      expect(find.text('Nom de la banque'), findsOneWidget);
      expect(find.text('Numéro de compte (RIB)'), findsOneWidget);
      expect(find.text('Titulaire du compte'), findsOneWidget);
    });

    testWidgets('switching back to Mobile Money shows mobile form',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to bank
      await tester.tap(find.text('Compte bancaire'));
      await tester.pumpAndSettle();

      // Switch back to mobile money
      await tester.tap(find.text('Mobile Money'));
      await tester.pumpAndSettle();

      expect(find.text('Opérateur'), findsOneWidget);
      expect(find.text('Numéro de téléphone'), findsOneWidget);
    });

    testWidgets('submit button is disabled when form is empty',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('displays Enregistrer button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('displays provider dropdown with Orange, MTN, Wave',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap the dropdown to open it
      await tester.tap(find.text('Orange Money'));
      await tester.pumpAndSettle();

      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('Wave'), findsOneWidget);
    });

    testWidgets('displays choose payout type heading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
          find.text('Choisissez votre moyen de reversement'), findsOneWidget);
    });

    testWidgets('displays error message when submit fails', (tester) async {
      mockRepository.shouldFail = false; // load succeeds, submit fails later
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      mockRepository.shouldFail = true; // now fail on submit

      // Fill Mobile Money form with valid data
      await tester.enterText(
          find.widgetWithText(TextField, 'Numéro de téléphone'), '0701020304');
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom du titulaire'), 'Aminata Koné');
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.text('Erreur serveur'), findsOneWidget);
    });

    testWidgets('successful submit shows SnackBar and navigates to home',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Fill Mobile Money form with valid data
      await tester.enterText(
          find.widgetWithText(TextField, 'Numéro de téléphone'), '0701020304');
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom du titulaire'), 'Aminata Koné');
      await tester.pumpAndSettle();

      // Tap submit
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Verify SnackBar
      expect(find.text('Moyen de reversement enregistré'), findsOneWidget);

      // Verify navigation to home
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('switching type clears account number field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter phone number in Mobile Money form
      await tester.enterText(
          find.widgetWithText(TextField, 'Numéro de téléphone'), '0701020304');
      await tester.pumpAndSettle();

      // Switch to bank account
      await tester.tap(find.text('Compte bancaire'));
      await tester.pumpAndSettle();

      // RIB field should be empty (controller cleared)
      final ribField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Numéro de compte (RIB)'));
      expect(ribField.controller?.text, isEmpty);
    });
  });
}
