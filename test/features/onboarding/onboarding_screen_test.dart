import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: OnboardingScreen(),
    );
  }

  group('OnboardingScreen', () {
    testWidgets('displays first page content on launch', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Partagez vos photos'), findsOneWidget);
      expect(
        find.text(
          'Prenez ou sélectionnez vos plus belles photos depuis votre galerie',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays Suivant button on first page', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Commencer'), findsNothing);
    });

    testWidgets('navigates to second page on Suivant tap', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Fixez votre prix'), findsOneWidget);
    });

    testWidgets('navigates to third page and shows Commencer',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Go to page 2
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      // Go to page 3
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();

      expect(find.text('Gagnez de l\'argent'), findsOneWidget);
      expect(find.text('Commencer'), findsOneWidget);
      expect(find.text('Suivant'), findsNothing);
    });

    testWidgets('displays 3 page indicator dots', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // AnimatedContainer widgets for dots
      final dots = find.byType(AnimatedContainer);
      expect(dots, findsNWidgets(3));
    });

    testWidgets('supports swipe navigation between pages', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Swipe left to page 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Fixez votre prix'), findsOneWidget);
    });
  });
}
