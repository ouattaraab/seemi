import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_theme.dart';
import 'package:ppv_app/features/design_showcase/presentation/screens/design_showcase_screen.dart';

void main() {
  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const DesignShowcaseScreen(),
    );
  }

  group('DesignShowcaseScreen - Sections', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('SeeMi Design System'), findsOneWidget);
    });

    testWidgets('renders palette section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Palette de Couleurs'), findsOneWidget);
      expect(find.text('Backgrounds'), findsOneWidget);
      expect(find.text('Primary Teal'), findsOneWidget);
    });

    testWidgets('renders typography section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Typographie'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Typographie'), findsOneWidget);
      // 'Display Large 32px' may be just below the fold after dragging to Typographie
      expect(find.text('Display Large 32px', skipOffstage: false), findsOneWidget);
    });

    testWidgets('renders buttons section title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      // Scroll to find Boutons section
      await tester.dragUntilVisible(
        find.text('Boutons'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Boutons'), findsOneWidget);
    });

    testWidgets('renders CTA button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Payer 500 FCFA (CTA)'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Payer 500 FCFA (CTA)'), findsOneWidget);
    });

    testWidgets('renders destructive button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Supprimer (Destructive)'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Supprimer (Destructive)'), findsOneWidget);
    });

    testWidgets('renders cards section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Card Title'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Card Title'), findsOneWidget);
    });

    testWidgets('renders inputs section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Inputs'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Inputs'), findsOneWidget);
    });

    testWidgets('renders spacing section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.dragUntilVisible(
        find.text('Spacing'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Spacing'), findsOneWidget);
      expect(find.text('Xs (4px)'), findsOneWidget);
    });
  });

  group('DesignShowcaseScreen - Theme integration', () {
    testWidgets('uses dark theme with correct scaffold bg', (tester) async {
      await tester.pumpWidget(createTestWidget());
      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).scaffoldBackgroundColor,
          const Color(0xFFFDFBF7)); // kBgBase — crème chaud
    });
  });
}
