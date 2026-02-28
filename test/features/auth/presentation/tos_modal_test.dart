import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/auth/presentation/widgets/tos_modal.dart';

void main() {
  group('TosModal', () {
    testWidgets('displays title and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TosModal.show(context),
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Rappel des CGU'), findsOneWidget);
      expect(find.text("J'accepte"), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
    });

    testWidgets('accept returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TosModal.show(context);
                },
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("J'accepte"));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('decline returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await TosModal.show(context);
                },
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refuser'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('displays engagement sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TosModal.show(context),
                child: const Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Vos engagements'), findsOneWidget);
      expect(find.text('Nos engagements'), findsOneWidget);
    });
  });
}
