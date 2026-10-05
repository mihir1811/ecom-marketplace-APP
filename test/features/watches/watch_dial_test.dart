import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/watches/presentation/widgets/brand_dials/watch_dial.dart';
import 'package:gemstone/features/watches/presentation/widgets/watch_brand_assets.dart';

void main() {
  test('every featured brand has a flagship dial', () {
    for (final brand in WatchBrandAssets.featuredBrands) {
      expect(WatchFlagship.of(brand), isNotNull, reason: brand);
    }
  });

  testWidgets('all flagship dials paint', (tester) async {
    final clock = ValueNotifier<double>(0);
    addTearDown(clock.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF070709),
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: const Color(0xFF070709),
              child: Wrap(
                children: [
                  for (final brand in WatchBrandAssets.featuredBrands)
                    WatchDial(
                      style: WatchFlagship.of(brand)!.style,
                      clock: clock,
                      size: 200,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 1; i <= 5; i++) {
      clock.value = i * 0.4;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);

    // Optional visual check: DIAL_SNAPSHOT=<path.png> flutter test ...
    final out = Platform.environment['DIAL_SNAPSHOT'];
    if (out != null) {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
