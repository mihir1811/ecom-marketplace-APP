import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/widgets/luxe/luxe_shape_dial.dart';
import 'package:gemstone/core/widgets/luxe/luxe_shape_picker.dart';
import 'package:gemstone/core/widgets/luxe/luxe_wheel.dart';
import 'package:google_fonts/google_fonts.dart';

const _shapes = [
  LuxeShapeOption(value: 'Round', label: 'Round'),
  LuxeShapeOption(value: 'Oval', label: 'Oval'),
  LuxeShapeOption(value: 'Pear', label: 'Pear'),
  LuxeShapeOption(value: 'Heart', label: 'Heart'),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  test('wheel sinks and leans neighbours outward', () {
    final centre = LuxeWheel.transform(0, 140);
    expect(centre.getTranslation().y, 0);

    final right = LuxeWheel.transform(1, 140);
    final left = LuxeWheel.transform(-1, 140);
    // Both neighbours sink by the same amount…
    expect(right.getTranslation().y, greaterThan(5));
    expect(left.getTranslation().y, closeTo(right.getTranslation().y, 1e-9));
    // …and lean away from the centre: clockwise on the right.
    expect(math.atan2(right.entry(1, 0), right.entry(0, 0)), LuxeWheel.step);
    expect(math.atan2(left.entry(1, 0), left.entry(0, 0)), -LuxeWheel.step);
  });

  testWidgets('swiping turns the dial to the next shape', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: LuxeShapeDial(
                shapes: _shapes,
                onCentreTap: (_) {},
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(LuxeShapeDial), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(changes.last, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finder picker toggles the centred shape', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LuxeShapeDialPicker(
              shapes: _shapes,
              selected: List.of(selected),
              onToggle: (v) => setState(
                () =>
                    selected.contains(v) ? selected.remove(v) : selected.add(v),
              ),
              selectLabel: (s) => 'Select $s',
              selectedLabel: (s) => '$s selected',
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select Round'));
    await tester.pumpAndSettle();
    expect(selected, ['Round']);
    expect(find.text('Round selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('view all swaps the dial for a grid of shape cards', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => LuxeShapeDialPicker(
                shapes: _shapes,
                selected: List.of(selected),
                onToggle: (v) => setState(
                  () => selected.contains(v)
                      ? selected.remove(v)
                      : selected.add(v),
                ),
                selectLabel: (s) => 'Select $s',
                selectedLabel: (s) => '$s selected',
                expandLabel: 'All shapes',
                collapseLabel: 'Fewer shapes',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('All shapes'));
    await tester.pumpAndSettle();
    expect(find.byType(LuxeShapeGrid), findsOneWidget);
    expect(find.text('Fewer shapes'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Heart').last);
    await tester.pumpAndSettle();
    expect(selected, ['Heart']);

    await tester.tap(find.text('Fewer shapes'));
    await tester.pumpAndSettle();
    expect(find.text('All shapes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
