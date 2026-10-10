import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/widgets/app_drawer_button.dart';
import 'package:gemstone/core/widgets/navigation/app_drawer_stage.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);

  Future<void> pumpStage(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppDrawerStage(
          drawer: const AppDrawerReveal(index: 0, child: Text('menu')),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => openAppDrawer(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppDrawerStageState stage(WidgetTester tester) =>
      tester.state<AppDrawerStageState>(find.byType(AppDrawerStage));

  testWidgets('opens behind the page and the page recedes', (tester) async {
    await pumpStage(tester);
    expect(find.text('menu'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final midway = AppDrawerStage.progress.value;
    expect(midway, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();

    expect(AppDrawerStage.progress.value, 1);
    expect(find.text('menu'), findsOneWidget);
    // The page shrinks and slides right of the menu.
    final page = tester.getRect(find.byType(Scaffold));
    final screen = tester.getRect(find.byType(AppDrawerStage));
    expect(page.left, closeTo(AppDrawerStage.drawerWidth(screen.width), 1));
    expect(page.height, lessThan(screen.height));
    // The receded page no longer takes taps.
    expect(find.text('open').hitTestable(), findsNothing);
  });

  testWidgets('tapping the page closes it', (tester) async {
    await pumpStage(tester);
    stage(tester).open();
    await tester.pumpAndSettle();

    final page = tester.getRect(find.byType(Scaffold));
    await tester.tapAt(Offset(page.left + 40, page.center.dy));
    await tester.pumpAndSettle();

    expect(stage(tester).isOpen, isFalse);
    expect(AppDrawerStage.progress.value, 0);
    expect(find.text('menu'), findsNothing);
    expect(find.text('open').hitTestable(), findsOneWidget);
  });

  testWidgets('back closes the drawer before leaving the page', (tester) async {
    await pumpStage(tester);
    stage(tester).open();
    await tester.pumpAndSettle();

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(stage(tester).isOpen, isFalse);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('swiping from the left edge opens it', (tester) async {
    await pumpStage(tester);
    final screen = tester.getRect(find.byType(AppDrawerStage));

    await tester.dragFrom(Offset(4, screen.center.dy), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(stage(tester).isOpen, isTrue);

    final page = tester.getRect(find.byType(Scaffold));
    await tester.dragFrom(
      Offset(page.left + 40, page.center.dy),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    expect(stage(tester).isOpen, isFalse);
  });
}
