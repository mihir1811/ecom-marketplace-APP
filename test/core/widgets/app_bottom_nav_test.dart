import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/widgets/luxe/luxe_spring.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/app_bottom_nav_bar.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/app_bottom_nav_destinations.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);

  group('AppBottomNav.tabFor', () {
    test('maps the four tab roots', () {
      expect(AppBottomNav.tabFor(AppRouteNames.home), AppBottomNavTab.home);
      expect(
        AppBottomNav.tabFor(AppRouteNames.buyerWishlist),
        AppBottomNavTab.wishlist,
      );
      expect(AppBottomNav.tabFor(AppRouteNames.cart), AppBottomNavTab.cart);
      expect(
        AppBottomNav.tabFor(AppRouteNames.buyerProfile),
        AppBottomNavTab.profile,
      );
    });

    test('visible on catalog product listing screens', () {
      for (final path in [
        AppRouteNames.diamondResults,
        AppRouteNames.labGrownDiamondResults,
        AppRouteNames.gemstoneResults,
        AppRouteNames.jewelryListing,
        AppRouteNames.watches,
        AppRouteNames.bullions,
        '/watches/brand/Rolex',
      ]) {
        expect(AppBottomNav.isVisibleOn(path), isTrue, reason: path);
        expect(AppBottomNav.tabFor(path), isNull, reason: path);
      }
    });

    test('hidden off tab and listing screens', () {
      for (final path in [
        AppRouteNames.diamonds,
        AppRouteNames.gemstones,
        AppRouteNames.jewelry,
        AppRouteNames.auctions,
        AppRouteNames.buyerWallet,
        AppRouteNames.productDetailPath('diamond', '42'),
        AppRouteNames.comparison,
        AppRouteNames.paymentConfirmationPath('7'),
        AppRouteNames.watchesFilters,
        AppRouteNames.bullionsFilters,
        AppRouteNames.brandWatchFiltersPath('Rolex'),
        AppRouteNames.login,
        AppRouteNames.sellerDashboard,
        AppRouteNames.buyerOrders,
        AppRouteNames.auctionDetailPath('a1'),
      ]) {
        expect(AppBottomNav.isVisibleOn(path), isFalse, reason: path);
      }
    });
  });

  test('LuxeSpring settles on its target and oval has soft shoulders', () {
    var x = 0.0, v = 0.0;
    for (var i = 0; i < 240 * 3; i++) {
      LuxeSpring.step(x, v, 1, 260, 0.5, 1 / 240, (nx, nv) {
        x = nx;
        v = nv;
      });
    }
    expect(x, closeTo(1, 1e-3));
    expect(LuxeSpring.oval(0), 1);
    expect(LuxeSpring.oval(1), 0);
    expect(LuxeSpring.oval(-1.5), 0);
  });

  group('AppBottomNavBar', () {
    Future<List<AppBottomNavTab>> pumpBar(
      WidgetTester tester, {
      required ValueNotifier<AppBottomNavTab?> selected,
    }) async {
      final taps = <AppBottomNavTab>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder<AppBottomNavTab?>(
                valueListenable: selected,
                builder: (context, tab, _) => AppBottomNavBar(
                  selected: tab,
                  badges: const {AppBottomNavTab.cart: 3},
                  onSelect: (d) => taps.add(d.tab),
                ),
              ),
            ),
          ),
        ),
      );
      return taps;
    }

    testWidgets('tapping a tab reports its destination', (tester) async {
      final selected = ValueNotifier<AppBottomNavTab?>(AppBottomNavTab.home);
      final taps = await pumpBar(tester, selected: selected);

      await tester.tap(find.bySemanticsLabel('Cart, 3'));
      expect(taps, [AppBottomNavTab.cart]);
    });

    testWidgets('switching tabs animates and comes to rest', (tester) async {
      final selected = ValueNotifier<AppBottomNavTab?>(AppBottomNavTab.home);
      await pumpBar(tester, selected: selected);

      for (final tab in [
        AppBottomNavTab.wishlist,
        AppBottomNavTab.cart,
        AppBottomNavTab.profile,
        AppBottomNavTab.home,
      ]) {
        selected.value = tab;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(tester.hasRunningAnimations, isTrue);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact dock expands on tap instead of switching', (
      tester,
    ) async {
      final taps = <AppBottomNavTab>[];
      final compact = ValueNotifier(false);
      var expands = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder<bool>(
                valueListenable: compact,
                builder: (context, folded, _) => AppBottomNavBar(
                  selected: AppBottomNavTab.home,
                  compact: folded,
                  badges: const {AppBottomNavTab.cart: 3},
                  onExpand: () {
                    expands++;
                    compact.value = false;
                  },
                  onSelect: (d) => taps.add(d.tab),
                ),
              ),
            ),
          ),
        ),
      );

      compact.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Cart, 3'));
      expect(expands, 1);
      expect(taps, isEmpty);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Cart, 3'));
      expect(taps, [AppBottomNavTab.cart]);
      expect(tester.takeException(), isNull);
    });
  });
}
