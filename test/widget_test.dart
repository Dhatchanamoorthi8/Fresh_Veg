import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegetable_shop/app/app.dart';

void main() {
  testWidgets('KisanFresh app boots up cleanly to Splash / Welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: KisanFreshApp()));

    // Initial pump
    await tester.pumpAndSettle();

    // Verify brand title and CTA are present on splash screen
    expect(find.text('KisanFresh'), findsOneWidget);
    expect(find.text('Start Shopping Fresh'), findsOneWidget);
  });
}
