import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/l10n/app_localizations.dart';
import 'package:gemworld/core/theme/app_palette.dart';
import 'package:gemworld/core/theme/app_theme.dart';
import 'package:gemworld/core/widgets/luxe/luxe_listing.dart';
import 'package:gemworld/core/widgets/luxe/luxe_product_card.dart';
import 'package:gemworld/features/jewelry_reviews/presentation/widgets/jewelry_review_stars.dart';
import 'package:gemworld/features/spotlight/presentation/widgets/spotlight_tag.dart';

/// The grid cell ([LuxeListingMetrics.gridExtent]) must fit every grid card
/// variant without overflowing, and without leaving a visible empty band
/// under the price.
void main() {
  Future<({double natural, double extent})> measure(
    WidgetTester tester,
    Widget card,
    double textScale,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    late double extent;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(AppPalette.ivory),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) {
              extent = LuxeListingMetrics.gridExtent(context);
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: LuxeListingMetrics.gridCell(context),
                  child: UnconstrainedBox(
                    constrainedAxis: Axis.horizontal,
                    child: KeyedSubtree(key: key, child: card),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    return (natural: tester.getSize(find.byKey(key)).height, extent: extent);
  }

  Widget card({Widget? metaLeading, Widget? price}) => LuxeProductGridCard(
    media: const ColoredBox(color: Colors.grey),
    title: 'Round 1.01 ct',
    subtitle: 'G · VS1 · Excellent',
    meta: 'GIA · 2.01ct',
    metaLeading: metaLeading,
    price: price ?? const LuxePriceRow(price: 12345),
    onTap: () {},
  );

  final variants = <String, Widget Function()>{
    'plain': card,
    'discount': () => card(
      price: const LuxePriceRow(
        price: 9000,
        listPrice: 12000,
        discountPercent: 25,
        showList: true,
      ),
    ),
    'price range': () =>
        card(price: const LuxePriceRow(price: 9000, prefix: 'from')),
    'sponsored': () => card(metaLeading: const SpotlightTag(pill: true)),
    'rating': () =>
        card(metaLeading: const JewelryRatingChip(average: 4.7, count: 12)),
  };

  for (final scale in [1.0, 1.3, 2.0]) {
    for (final entry in variants.entries) {
      testWidgets('${entry.key} card fits its cell at text scale $scale', (
        tester,
      ) async {
        final m = await measure(tester, entry.value(), scale);
        final slack = m.extent - m.natural;
        expect(
          slack,
          greaterThanOrEqualTo(0),
          reason: 'overflows by ${-slack}',
        );
        expect(slack, lessThan(8), reason: 'empty band of $slack px');
      });
    }
  }
}
