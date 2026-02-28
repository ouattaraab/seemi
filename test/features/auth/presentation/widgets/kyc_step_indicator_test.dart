import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/auth/presentation/widgets/kyc_step_indicator.dart';

void main() {
  Widget createTestWidget({required int currentStep}) {
    return MaterialApp(
      home: Scaffold(
        body: KycStepIndicator(currentStep: currentStep),
      ),
    );
  }

  group('KycStepIndicator', () {
    testWidgets('renders 3 step circles', (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 1));

      // 3 step circles + 2 connector lines = 5 children in the Row
      final row = find.byType(Row);
      expect(row, findsOneWidget);

      // Should show numbers 1, 2, 3
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('step 1 current: shows step 1 as current, 2 and 3 as upcoming',
        (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 1));

      // Step 1 should have primary color (teal)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // No check icon on step 1
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('step 2 current: shows step 1 completed with check icon',
        (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 2));

      // Step 1 is completed — check icon should appear
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Steps 2 and 3 should still show numbers
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('step 3 current: shows steps 1 and 2 completed',
        (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 3));

      // Steps 1 and 2 completed — 2 check icons
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // Step 3 shows number
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('completed steps have success color', (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 3));

      // Find containers with success color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final successContainers = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == AppColors.kSuccess;
        }
        return false;
      });

      // Steps 1 and 2 should have success color
      expect(successContainers.length, 2);
    });

    testWidgets('current step has primary color', (tester) async {
      await tester.pumpWidget(createTestWidget(currentStep: 2));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final primaryContainers = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == AppColors.kPrimary;
        }
        return false;
      });

      // Only step 2 (current) should have primary color
      expect(primaryContainers.length, 1);
    });
  });
}
