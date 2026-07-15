import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/app.dart';

void main() {
  testWidgets('GemWorld App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GemWorldApp(),
      ),
    );

    // Verify that GemWorld brand title is displayed.
    expect(find.text('GemWorld'), findsAtLeastNWidgets(1));
  });
}
