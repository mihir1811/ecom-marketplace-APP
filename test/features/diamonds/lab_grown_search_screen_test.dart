import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/widgets/search_action_bottom_bar.dart';
import 'package:gemstone/features/diamonds/presentation/screens/lab_grown_diamond_search_screen.dart';
import 'package:gemstone/features/diamonds/presentation/widgets/lab_grown_diamond_scope.dart';

void main() {
  testWidgets('lab grown search screen shows SHOW and CLEAR ALL buttons',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LabGrownDiamondScope(child: LabGrownDiamondSearchScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SearchActionBottomBar), findsOneWidget);
    expect(find.textContaining('SHOW'), findsOneWidget);
    expect(find.text('CLEAR ALL FILTERS'), findsOneWidget);
    expect(find.text('Diamond Category'), findsOneWidget);
    expect(find.text('Growth Method (CVD / HPHT)'), findsOneWidget);

    // Unmount to cancel carousel timers before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
