import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/widgets/gem3d/gem_field.dart';
import 'package:gemstone/core/widgets/gem3d/gem_mesh.dart';
import 'package:gemstone/core/widgets/gem3d/gem_view.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  testWidgets('gem field animates and reacts to drag and tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 390, height: 460, child: GemField()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));

    final centre = tester.getCenter(find.byType(GemField));
    await tester.dragFrom(centre, const Offset(140, 40));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);

    // Unmounting stops the ticker cleanly.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('touching the stones does not scroll the page', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: const [
              SizedBox(height: 300),
              SizedBox(height: 600, child: GemField(touchTopInset: 120)),
            ],
          ),
        ),
      ),
    );
    controller.jumpTo(200);
    await tester.pump(const Duration(milliseconds: 16));

    // Drag inside the interactive area: page stays put.
    final field = tester.getRect(find.byType(GemField));
    await tester.dragFrom(field.center, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.offset, 200);

    // Drag in the copy band above the inset: page scrolls.
    await tester.dragFrom(
      field.topCenter + const Offset(0, 40),
      const Offset(0, 150),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.offset, lessThan(200));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every cut renders in a gem view and spins on drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final cut in GemCut.values)
                GemView(cut: cut, size: 60, interactive: true),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.byType(GemView).first, const Offset(80, 0));
    await tester.tap(find.byType(GemView).last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
