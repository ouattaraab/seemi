import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/content/presentation/screens/sharing_screen.dart';

void main() {
  const testShareUrl = 'https://ppv.example.com/c/abc123xyz';

  Widget buildTestWidget() {
    return const MaterialApp(
      home: SharingScreen(shareUrl: testShareUrl),
    );
  }

  group('SharingScreen', () {
    testWidgets('renders share URL as selectable text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text(testShareUrl), findsOneWidget);
    });

    testWidgets('displays success message', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Contenu publié avec succès !'), findsOneWidget);
    });

    testWidgets('displays copy button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Copier le lien'), findsOneWidget);
    });

    testWidgets('displays back to home button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text("Retour à l'accueil"), findsOneWidget);
    });

    testWidgets('copy button copies to clipboard and shows snackbar',
        (tester) async {
      final List<MethodCall> log = [];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          return null;
        },
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Copier le lien'));
      await tester.pump();

      final clipboardCall = log.firstWhere(
        (c) => c.method == 'Clipboard.setData',
        orElse: () => throw TestFailure('Clipboard.setData not called'),
      );
      expect(clipboardCall.arguments['text'], testShareUrl);
    });

    testWidgets('shows "Lien copié !" snackbar after copy', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.text('Copier le lien'));
      await tester.pump();

      expect(find.text('Lien copié !'), findsOneWidget);
    });

    testWidgets('app bar shows correct title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Lien de partage'), findsOneWidget);
    });

    testWidgets('displays success icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
