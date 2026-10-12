import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/features/product_detail/domain/models/product_detail.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_gem_dock.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_sheet_launch.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_sheet_screen.dart';

ProductDetail _watch(int i) => ProductDetail(
  id: 'w$i',
  segment: ProductSegment.watch,
  apiProductType: 'watch',
  title: 'Chronograph $i',
  subtitle: 'Steel · 40 mm',
  referenceLabel: 'SKU',
  referenceValue: 'SKU-$i',
  media: const ProductMedia(
    fallbackIcon: Icons.watch_outlined,
    fallbackTint: Colors.brown,
  ),
  price: const ProductPrice(
    currencySymbol: '₹',
    amountLabel: '1,20,000',
    priceUsd: 1400,
    priceInr: 120000,
    displayAmount: 120000,
  ),
  highlights: const [],
  specSections: const [],
);

Future<void> _open(
  WidgetTester tester, {
  required ProductSheetLaunch launch,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    opaque: false,
                    transitionDuration: const Duration(milliseconds: 680),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 520,
                    ),
                    pageBuilder: (_, _, _) =>
                        ProductSheetScreen(detail: _watch(2), launch: launch),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
}

ProductSwitchSet _set() {
  final items = List.generate(6, _watch);
  return ProductSwitchSet.of(items, items[2], (d) => d, items[2])!;
}

void main() {
  testWidgets('opens as a pop-up from its card, grows on scroll', (
    tester,
  ) async {
    final origin = ProductSheetOrigin(
      rect: const Rect.fromLTWH(20, 300, 170, 220),
    );
    await _open(
      tester,
      launch: ProductSheetLaunch(origin: origin, switchSet: _set()),
    );

    // Mid-flight: still growing, no layout errors.
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Chronograph 2'), findsWidgets);
    expect(find.byType(ProductGemDock), findsOneWidget);

    // A pop-up first: inset from the screen edges, not full screen.
    final clip = find.descendant(
      of: find.byType(ProductSheetScreen),
      matching: find.byType(ClipRRect),
    );
    final popup = tester.getRect(clip.first);
    expect(popup.left, greaterThan(1));
    expect(popup.width, lessThan(390));

    // Scrolling widens it to the full screen.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -360),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final grown = tester.getRect(clip.first);
    expect(grown.width, greaterThan(popup.width));
    expect(grown.width, closeTo(390, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock switches product with a transition', (tester) async {
    await _open(
      tester,
      launch: ProductSheetLaunch(
        origin: ProductSheetOrigin(
          rect: const Rect.fromLTWH(20, 300, 170, 220),
        ),
        switchSet: _set(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    // Tap the gem to the right of the centre.
    final dock = tester.getRect(find.byType(ProductGemDock));
    await tester.tapAt(Offset(dock.center.dx + 80, dock.top + 47));
    await tester.pump(const Duration(milliseconds: 250));
    // Both pages alive mid-transition.
    expect(find.text('Chronograph 2'), findsWidgets);
    expect(find.text('Chronograph 3'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.takeException(), isNull);
  });

  testWidgets('works without a recorded tap or siblings', (tester) async {
    await _open(tester, launch: ProductSheetLaunch.none);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byType(ProductGemDock), findsNothing);
    expect(find.text('Chronograph 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out on a small phone and a wide window', (tester) async {
    for (final size in const [Size(320, 568), Size(1280, 800)]) {
      await _open(
        tester,
        launch: ProductSheetLaunch(
          origin: ProductSheetOrigin(
            rect: const Rect.fromLTWH(20, 200, 150, 200),
          ),
          switchSet: _set(),
        ),
        size: size,
      );
      await tester.pump(const Duration(milliseconds: 1300));
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('tap tracker resolves the tapped card', (tester) async {
    ProductTapTracker.attach();
    ProductSheetOrigin? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => got = ProductTapTracker.capture(),
                child: Container(height: 150, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Container).at(2));
    expect(got, isNotNull);
    expect(got!.rect.height, closeTo(166, 1));
    expect(got!.rect.top, closeTo(2 * 166, 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    got!.dispose();
  });
}
