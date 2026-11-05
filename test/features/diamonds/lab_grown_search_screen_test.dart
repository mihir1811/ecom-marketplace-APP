import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/diamonds/presentation/screens/lab_grown_diamond_search_screen.dart';
import 'package:gemworld/features/diamonds/presentation/widgets/lab_grown_diamond_scope.dart';

void main() {
  testWidgets('lab grown finder shows primary action, lab controls and reset',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LabGrownDiamondScope(child: LabGrownDiamondSearchScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('SHOW'), findsOneWidget);
    expect(find.text('Diamond Category'), findsOneWidget);
    expect(find.text('Growth Method (CVD / HPHT)'), findsOneWidget);
    // Reset only appears once a filter is active.
    expect(find.text('Reset'), findsNothing);

    await tester.tap(find.text('CVD'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Reset'), findsOneWidget);

    // Unmount to cancel animation timers before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
