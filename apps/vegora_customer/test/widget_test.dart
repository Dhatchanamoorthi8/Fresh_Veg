import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegora_customer/app/customer_app.dart';

void main() {
  testWidgets('Vegora Customer App boots up cleanly to Splash / Welcome screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VegoraCustomerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Vegora'), findsWidgets);
    expect(find.text('Freshness at Your Doorstep.'), findsOneWidget);
    expect(find.text('Start Shopping Fresh'), findsOneWidget);
  });
}
