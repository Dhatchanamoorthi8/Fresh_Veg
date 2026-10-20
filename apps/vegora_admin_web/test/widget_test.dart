import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegora_admin_web/features/admin/admin_shell.dart';

void main() {
  testWidgets(
    'AdminScaffold renders desktop sidebar with all menu options in Web Console',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminScaffold(
              currentSection: AdminMenuSection.dashboard,
              title: 'Dashboard Overview',
              body: Center(child: Text('Dashboard Content Body')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vegora'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Manage Branches'), findsOneWidget);
      expect(find.text('Manage Vegetables'), findsOneWidget);
    },
  );
}
