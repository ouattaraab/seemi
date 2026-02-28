import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ppv_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('PpvApp renders without errors', (WidgetTester tester) async {
    // PpvApp now wraps with MultiProvider (AuthProvider).
    // Firebase mocked via setupFirebaseCoreMocks().
    await tester.pumpWidget(const PpvApp());
    await tester.pump();

    // La route initiale est splash (/) — affiche 'PPV'
    // pump() au lieu de pumpAndSettle() car le splash a un timer de 2s
    expect(find.text('PPV'), findsOneWidget);
  });

  testWidgets('PpvApp uses MaterialApp.router with dark theme',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PpvApp());

    final materialApp =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.routerConfig, isNotNull);
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
    expect(materialApp.title, equals('PPV - Paye Pour Voir'));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(materialApp.theme, isNotNull);
  });
}
