import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/features/ai_chat/presentation/widgets/gem_ai_fab.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  Future<({bool right, double fraction})?> dragAndRelease(
    WidgetTester tester,
    Offset by,
  ) async {
    ({bool right, double fraction})? docked;
    var right = true;
    var fraction = 1.0;
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Stack(
            children: [
              Positioned.fill(
                child: GemAiDock(
                  hidden: false,
                  right: right,
                  fraction: fraction,
                  semanticLabel: 'Open Gem AI',
                  onPressed: () {},
                  onDocked: (r, f) => setState(() {
                    right = r;
                    fraction = f;
                    docked = (right: r, fraction: f);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final orb = tester.getCenter(find.byType(GemAiFab));
    final gesture = await tester.startGesture(orb);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(orb + by * (i / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    return docked;
  }

  testWidgets('dragging to the left half docks on the left edge', (
    tester,
  ) async {
    final docked = await dragAndRelease(tester, const Offset(-230, -300));
    expect(docked, isNotNull);
    expect(docked!.right, isFalse);
    final orb = tester.getTopLeft(find.byType(GemAiFab));
    expect(orb.dx, closeTo(GemAiDockGeometry.edge, 1));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a release near the middle never rests mid-screen', (
    tester,
  ) async {
    final docked = await dragAndRelease(tester, const Offset(-120, -260));
    expect(docked, isNotNull);
    final x = tester.getTopLeft(find.byType(GemAiFab)).dx;
    final atEdge =
        (x - GemAiDockGeometry.edge).abs() < 1 ||
        (x - (390 - GemAiDockGeometry.size - GemAiDockGeometry.edge)).abs() <
            1;
    expect(atEdge, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
