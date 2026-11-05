import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/app.dart';

void main() {
  testWidgets('GemWorld App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GemWorldApp()));

    // The app carries the GemWorld brand as its window / task title.
    expect(
      find.byWidgetPredicate((w) => w is Title && w.title.contains('GemWorld')),
      findsOneWidget,
    );

    // Unmount and let the entrance animations' one-shot timers drain.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
