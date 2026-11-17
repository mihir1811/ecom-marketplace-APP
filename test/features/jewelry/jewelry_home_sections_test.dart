import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/jewelry/application/jewellery_categories_provider.dart';
import 'package:gemworld/features/jewelry/application/jewelry_catalogue_providers.dart';
import 'package:gemworld/features/jewelry/application/jewelry_home_providers.dart';
import 'package:gemworld/features/jewelry/domain/models/jewelry.dart';
import 'package:gemworld/features/jewelry/domain/models/marketplace_listing.dart';
import 'package:gemworld/features/jewelry/presentation/widgets/jewelry_home_sections.dart';

const _long =
    'Maison Lumière Fine Jewels and Heirloom Creations Private Limited';

final _categories = [
  for (final name in ['Rings', 'Earrings', 'Necklaces', 'Bracelets', _long])
    MarketplaceCategory(id: name, name: name, slug: name.toLowerCase()),
];

final _shops = [
  for (var i = 0; i < 3; i++)
    MarketplaceShop(
      id: 's$i',
      name: i == 0 ? _long : 'House $i',
      slug: 'house-$i',
      listingCount: 136 * (i + 1),
      isVerified: i.isEven,
      ratingAverage: 4.6,
      ratingCount: i * 12,
      policies: const {'location': 'Jaipur, Rajasthan, India'},
    ),
];

Future<void> _pumpAt(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jewelleryCategoriesProvider.overrideWith((ref) async => _categories),
        jewelryShopsProvider.overrideWith((ref) async => _shops),
        jewelryHomeRailProvider.overrideWith((ref, _) async => <Jewelry>[]),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JewelryHeroCarousel(onOpen: (_) {}),
                const JewelryHomeHeading(
                  title: _long,
                  subtitle: _long,
                  actionLabel: 'View all',
                ),
                JewelryBudgetGrid(onOpen: (_) {}),
                JewelryTrendingRail(onViewAll: (_) {}),
                JewelryGemstoneRail(onOpen: (_) {}),
                JewelryHouseRail(onOpen: (_) {}, onShowAll: () {}),
                const JewelryTrustStrip(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  for (final width in [320.0, 412.0, 900.0]) {
    testWidgets('jewelry home sections lay out at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpAt(tester, width);
      expect(tester.takeException(), isNull);
      expect(find.text('Shop now'), findsWidgets);
      expect(find.text('Under ₹10K'), findsOneWidget);
      expect(find.text('₹50K & above'), findsOneWidget);
      expect(find.text('House 1'), findsOneWidget);
      // Empty rails hide the trending section.
      expect(find.text('Trending now'), findsNothing);
      // Stop the hero's timer.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
