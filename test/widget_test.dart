import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegetable_shop/app/app.dart';

void main() {
  testWidgets('Vegora app boots up cleanly to Splash / Welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: VegoraApp()));

    // Initial pump
    await tester.pumpAndSettle();

    // Verify brand title and CTA are present on splash screen
    expect(find.text('Vegora'), findsOneWidget);
    expect(find.text('Freshness at Your Doorstep.'), findsOneWidget);
    expect(find.text('Start Shopping Fresh'), findsOneWidget);
  });
}
