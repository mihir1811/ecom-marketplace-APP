import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/features/watches/application/watch_filter_provider.dart';
import 'package:gemstone/features/watches/presentation/widgets/brand_dials/watch_dial.dart';
import 'package:gemstone/features/watches/presentation/widgets/watch_brand_carousel.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);
  tearDown(AppHaptics.debugReset);

  testWidgets('centre watch toggles its brand; side watch comes to centre', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ListView(children: const [WatchBrandCarousel()]),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WatchDial), findsWidgets);

    // Tap the centred watch: Rolex is first in the featured list.
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(watchFilterProvider).brands, contains('Rolex'));

    // Tap the right-hand neighbour: it slides to the centre.
    final page = tester.getRect(find.byType(PageView));
    await tester.tapAt(page.center + Offset(page.width * 0.34, 0));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Patek Philippe'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
