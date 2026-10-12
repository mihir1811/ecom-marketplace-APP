import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/core/widgets/luxe/product_card_anchor.dart';
import 'package:gemstone/features/product_detail/domain/models/product_detail.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_frame_shape.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_gem_dock.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_sheet_launch.dart';
import 'package:gemstone/features/product_detail/presentation/transition/product_sheet_screen.dart';

const _shapes = ['Round', 'Heart', 'Pear', 'Oval', 'Emerald', 'Marquise'];

ProductDetail _product(int i, {bool watch = false}) => ProductDetail(
  id: 'p$i',
  segment: watch ? ProductSegment.watch : ProductSegment.naturalDiamond,
  apiProductType: watch ? 'watch' : 'diamond',
  title: 'Product $i',
  subtitle: 'Steel · 40 mm · a rather long subtitle line',
  referenceLabel: 'SKU',
  referenceValue: 'SKU-$i',
  shapeKey: _shapes[i % _shapes.length],
  badges: const [
    ProductBadge('Natural Diamond', tone: ProductBadgeTone.accent),
    ProductBadge('GIA certified', tone: ProductBadgeTone.positive),
    ProductBadge('12% below list', tone: ProductBadgeTone.caution),
  ],
  media: const ProductMedia(
    fallbackIcon: Icons.diamond_outlined,
    fallbackTint: Colors.brown,
    certificateUrl: 'https://example.com/cert.pdf',
    certificateLabel: 'GIA certificate',
  ),
  price: const ProductPrice(
    currencySymbol: 'Rs ',
    amountLabel: '1,20,000',
    priceUsd: 1400,
    priceInr: 120000,
    displayAmount: 120000,
    unitLabel: 'per carat',
    unitAmountLabel: '40,000',
    discountPercent: 12,
  ),
  highlights: const [
    ProductHighlight('Colour', 'D'),
    ProductHighlight('Clarity', 'VVS1'),
    ProductHighlight('Cut', 'Excellent'),
    ProductHighlight('Carat', '1.20'),
  ],
  certification: const ProductCertification(
    authority: 'GIA',
    referenceLabel: 'Report',
    referenceValue: '2141438171',
  ),
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
                        ProductSheetScreen(detail: _product(2), launch: launch),
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

ProductSwitchSet _set({bool watch = false}) {
  final items = List.generate(6, (i) => _product(i, watch: watch));
  return ProductSwitchSet.of(items, items[2], (d) => d, items[2])!;
}

ProductSheetLaunch _launch({bool watch = false}) => ProductSheetLaunch(
  origin: ProductSheetOrigin(rect: const Rect.fromLTWH(20, 300, 170, 220)),
  switchSet: _set(watch: watch),
);

Rect _card(WidgetTester tester, int i) =>
    tester.getRect(find.byKey(ValueKey('card-$i')));

/// Whether a card is mounted but kept out of sight (or not mounted at all).
bool _hidden(WidgetTester tester, int i) {
  final card = find.byKey(ValueKey('card-$i'));
  if (card.evaluate().isEmpty) return true;
  final off = find.descendant(
    of: card,
    matching: find.byType(Offstage),
    skipOffstage: false,
  );
  return tester.widget<Offstage>(off.first).offstage;
}

/// A sheet test; lets the pages' staggered entrance timers run out at the end.
void sheetTest(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 3));
  });
}

void main() {
  sheetTest('opens as a pop-up with its neighbours peeking in', (tester) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    // Neighbours are not there yet while the pop-up is still opening.
    expect(_hidden(tester, 1), isTrue);

    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(ProductGemDock), findsOneWidget);
    final centre = _card(tester, 2);
    final left = _card(tester, 1);
    final right = _card(tester, 3);

    // The middle card is inset from the screen edges, not full screen.
    expect(centre.left, greaterThan(30));
    expect(centre.width, lessThan(340));
    // A strip of each neighbour shows: roughly a fifth of its width.
    final leftShown = left.right.clamp(0, 390);
    final rightShown = 390 - right.left.clamp(0, 390);
    expect(leftShown, inInclusiveRange(20, 80));
    expect(rightShown, inInclusiveRange(20, 80));
    expect(left.left, lessThan(0));
    expect(right.right, greaterThan(390));
    expect(tester.takeException(), isNull);
  });

  sheetTest('scrolling widens the centre card to the full screen', (
    tester,
  ) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));
    final popup = _card(tester, 2);

    await tester.drag(
      find.byType(CustomScrollView).hitTestable().first,
      const Offset(0, -380),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final grown = _card(tester, 2);
    expect(grown.width, greaterThan(popup.width));
    expect(grown.width, closeTo(390, 1));
    // The neighbours have slipped away.
    expect(find.byKey(const ValueKey('card-1')).hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  sheetTest('a full-screen page stays so at the top until pulled further', (
    tester,
  ) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));
    final scroll = find.byType(CustomScrollView).hitTestable().first;

    await tester.drag(scroll, const Offset(0, -380));
    await tester.pump(const Duration(milliseconds: 700));
    // Back to the very top: the picture stays full screen.
    await tester.drag(scroll, const Offset(0, 380));
    await tester.pump(const Duration(milliseconds: 700));
    expect(_card(tester, 2).width, closeTo(390, 1));

    // A further deliberate pull gives way to the pop-up.
    await tester.drag(scroll, const Offset(0, 160));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(_card(tester, 2).width, lessThan(340));
    expect(tester.takeException(), isNull);
  });

  sheetTest('swiping the cards moves to the next product', (tester) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));

    await tester.fling(
      find.byKey(const ValueKey('card-2')),
      const Offset(-260, 0),
      900,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1500));
    // Product 3 now sits in the middle.
    final middle = _card(tester, 3);
    expect(middle.center.dx, closeTo(195, 3));
    expect(find.text('Product 3'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  sheetTest('the dock shows five frames and drives the cards', (tester) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));

    final dock = tester.getRect(find.byType(ProductGemDock));
    // Tap the frame right of the centre.
    await tester.tapAt(Offset(dock.center.dx + dock.width / 4, dock.center.dy));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_card(tester, 3).center.dx, closeTo(195, 3));

    // Swiping the dock turns the cards too.
    await tester.drag(find.byType(ProductGemDock), Offset(dock.width / 4, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.takeException(), isNull);
    expect(_card(tester, 2).center.dx, closeTo(195, 3));
  });

  sheetTest('closing shrinks the pop-up and ends without errors', (
    tester,
  ) async {
    await _open(tester, launch: _launch());
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));
    Navigator.of(tester.element(find.byType(ProductSheetScreen))).pop();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(ProductSheetScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  sheetTest('works without a recorded tap or siblings', (tester) async {
    await _open(tester, launch: ProductSheetLaunch.none);
    await tester.pump(const Duration(milliseconds: 1400));
    expect(find.byType(ProductGemDock), findsNothing);
    expect(find.text('Product 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  sheetTest('lays out on a small phone and a wide window', (tester) async {
    for (final size in const [Size(320, 568), Size(1280, 800)]) {
      await _open(tester, launch: _launch(), size: size);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.pumpWidget(const SizedBox());
    }
  });

  sheetTest('other segments keep the gem-cut octagon', (tester) async {
    expect(ProductFrameShape.of(_product(0, watch: true)).key, isNull);
    expect(ProductFrameShape.of(_product(2)).key, 'Pear');
    await _open(tester, launch: _launch(watch: true));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap tracker resolves the tapped card and its list', (
    tester,
  ) async {
    ProductTapTracker.attach();
    ProductSheetOrigin? got;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.all(8),
              child: ProductCardAnchor(
                index: i,
                child: GestureDetector(
                  onTap: () => got = ProductTapTracker.capture(),
                  child: Container(height: 150, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Container).at(2));
    expect(got, isNotNull);
    expect(got!.index, 2);
    expect(got!.scrollable, isNotNull);
    expect(got!.rect.height, closeTo(150, 1));
    expect(got!.rect.top, closeTo(2 * 166 + 8, 1));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    got!.dispose();
  });

  testWidgets('the registry scrolls a far card into view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 60,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProductCardAnchor(
                index: i,
                child: SizedBox(height: 150, child: Text('card $i')),
              ),
            ),
          ),
        ),
      ),
    );
    final scrollable = Scrollable.of(tester.element(find.text('card 0')));
    expect(ProductCardRegistry.find(40, scrollable), isNull);

    final done = ProductCardRegistry.reveal(40, scrollable);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await done;
    final card = ProductCardRegistry.find(40, scrollable);
    expect(card, isNotNull);
    expect(card!.rect.top, greaterThan(0));
    expect(card.rect.bottom, lessThan(600));
  });

  testWidgets('closing lands on the card of the product being viewed', (
    tester,
  ) async {
    ProductTapTracker.attach();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final items = List.generate(14, _product);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductCardAnchor(
                    index: i,
                    child: GestureDetector(
                      onTap: () {
                        final launch = ProductSheetLaunch(
                          origin: ProductTapTracker.capture(),
                          switchSet: ProductSwitchSet.of(
                            items,
                            items[i],
                            (d) => d,
                            items[i],
                          ),
                        );
                        Navigator.of(context).push(
                          PageRouteBuilder<void>(
                            opaque: false,
                            transitionDuration: const Duration(
                              milliseconds: 680,
                            ),
                            reverseTransitionDuration: const Duration(
                              milliseconds: 520,
                            ),
                            pageBuilder: (_, _, _) => ProductSheetScreen(
                              detail: items[i],
                              launch: launch,
                            ),
                          ),
                        );
                      },
                      child: SizedBox(height: 150, child: Text('row $i')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('row 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 800));

    // Step through the dock to product 6, well below the first screenful.
    final dock = tester.getRect(find.byType(ProductGemDock));
    for (var step = 0; step < 5; step++) {
      await tester.tapAt(
        Offset(dock.center.dx + dock.width / 4, dock.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 1000));
    }
    // Let the list scroll behind the pop-up.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final target = ProductCardRegistry.find(6, scrollable);
    expect(target, isNotNull, reason: 'card 6 was scrolled into view');
    expect(target!.rect.top, greaterThan(0));
    expect(target.rect.bottom, lessThan(844));

    // Closing: the pop-up heads for that card, not for the one tapped.
    Navigator.of(tester.element(find.byType(ProductSheetScreen))).pop();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 480));
    final shrinking = _card(tester, 6);
    expect((shrinking.center - target.rect.center).distance, lessThan(160));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(ProductSheetScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
