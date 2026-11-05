import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/l10n/app_localizations.dart';
import 'package:gemworld/core/theme/luxe_scope.dart';
import 'package:gemworld/features/product_detail/domain/models/product_detail.dart';
import 'package:gemworld/features/product_detail/domain/models/product_price_labels.dart';
import 'package:gemworld/features/product_detail/presentation/widgets/luxe/luxe_purchase_bar.dart';

ProductDetail _melee({bool offers = false}) => ProductDetail(
  id: 'melee-1',
  segment: ProductSegment.naturalDiamond,
  apiProductType: 'melee',
  title: 'Melee parcel',
  subtitle: 'Round · 1.2 mm',
  referenceLabel: 'Stock ID',
  referenceValue: 'M-1',
  media: const ProductMedia(
    fallbackIcon: Icons.diamond_outlined,
    fallbackTint: Colors.brown,
  ),
  price: const ProductPrice(
    currencySymbol: r'$',
    amountLabel: '100',
    priceUsd: 100,
    priceInr: 8400,
    displayAmount: 100,
  ),
  highlights: const [],
  specSections: const [],
  isMakeAnOfferAllowed: offers,
  naturalSpecTabs: const ProductTabbedSpecs(
    tabs: [],
    meleeQty: ProductMeleeQty(totalPcs: 100, totalCarat: 2),
  ),
);

Future<void> _pump(WidgetTester tester, ProductDetail detail, double width) {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LuxeScope(
          child: Scaffold(
            bottomNavigationBar: LuxePurchaseBar(
              detail: detail,
              priceLabels: ProductPriceLabels.resolve(
                detail.price,
                grouped: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('melee quantity sits in the bar and drives the cart price', (
    tester,
  ) async {
    await _pump(tester, _melee(), 320);
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    // Seeded with the whole lot.
    expect(find.text(r'$100'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '25');
    await tester.pump();
    expect(find.text(r'$25'), findsOneWidget);

    await tester.tap(find.text('CT'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1');
    await tester.pump();
    expect(find.text(r'$50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quantity, offer and cart fit a small phone', (tester) async {
    for (final width in [320.0, 390.0, 480.0]) {
      await _pump(tester, _melee(offers: true), width);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}
