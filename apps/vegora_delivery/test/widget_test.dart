import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegora_delivery/app/delivery_app.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

void main() {
  testWidgets('Vegora Delivery Partner app boots up cleanly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          orderRepositoryProvider.overrideWithValue(MockOrderRepository()),
        ],
        child: const VegoraDeliveryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery Partner App'), findsOneWidget);
  });
}
