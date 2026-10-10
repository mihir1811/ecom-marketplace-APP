import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/haptics/app_haptics.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/app_bottom_nav_bar.dart';
import 'package:gemstone/core/widgets/navigation/bottom_nav/app_bottom_nav_host.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);

  GoRouter buildRouter() {
    Widget page(String name) => Scaffold(body: Center(child: Text(name)));
    return GoRouter(
      initialLocation: AppRouteNames.home,
      observers: [appPopupRouteObserver],
      routes: [
        for (final path in [
          AppRouteNames.home,
          AppRouteNames.buyerWishlist,
          AppRouteNames.cart,
          AppRouteNames.buyerProfile,
          AppRouteNames.comparison,
        ])
          GoRoute(path: path, builder: (_, _) => page(path)),
      ],
    );
  }

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              AppBottomNavHost(router: router, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  double pageHeight(WidgetTester tester) =>
      tester.getSize(find.byType(Scaffold).last).height;

  testWidgets('pages are laid out above the bar; hidden routes reclaim it', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(pageHeight(tester), closeTo(screen - AppBottomNavBar.height, 0.5));

    router.push(AppRouteNames.comparison);
    await tester.pumpAndSettle();
    expect(pageHeight(tester), closeTo(screen, 0.5));

    router.pop();
    await tester.pumpAndSettle();
    expect(pageHeight(tester), closeTo(screen - AppBottomNavBar.height, 0.5));
  });

  testWidgets('tapping a tab navigates there', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('Cart'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRouteNames.cart,
    );
  });

  testWidgets('a dialog blocks the bar and a bar tap dismisses it', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final context = tester.element(find.text(AppRouteNames.home));
    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    await tester.tap(find.byType(AppBottomNavBar), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
    // The tap closed the dialog instead of switching tabs.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRouteNames.home,
    );
  });

  group('diamond transition', () {
    final overlay = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_DiamondPainter',
    );

    String path(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.path;

    /// Distinct locations the router passes through.
    List<String> track(GoRouter router) {
      final seen = <String>[];
      router.routerDelegate.addListener(() {
        final now = path(router);
        if (seen.isEmpty || seen.last != now) seen.add(now);
      });
      return seen;
    }

    Offset tabCentre(WidgetTester tester, int index) {
      final bar = tester.getRect(find.byType(AppBottomNavBar));
      final slot = bar.width / 4;
      return Offset(bar.left + slot * (index + 0.5), bar.top + 33);
    }

    Future<void> slide(
      WidgetTester tester,
      TestGesture gesture,
      Offset from,
      Offset to,
    ) async {
      const steps = 12;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    testWidgets('a tap wraps the page into the gem and reveals the tab', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      final seen = track(router);

      await tester.tapAt(tabCentre(tester, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(overlay, findsOneWidget);

      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
      expect(path(router), AppRouteNames.cart);
      expect(seen, [AppRouteNames.cart]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('holding and dragging previews; release navigates once', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      final seen = track(router);

      final start = tabCentre(tester, 1);
      final gesture = await tester.startGesture(start);
      await tester.pump(AppBottomNavBar.scrubHold);
      await tester.pump(const Duration(milliseconds: 300));
      // Holding another tab starts the wrap but never reveals it.
      expect(overlay, findsOneWidget);
      expect(path(router), AppRouteNames.home);

      await slide(tester, gesture, start, tabCentre(tester, 2));
      await slide(tester, gesture, tabCentre(tester, 2), tabCentre(tester, 3));
      await tester.pump(const Duration(milliseconds: 500));
      expect(path(router), AppRouteNames.home);
      expect(seen, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
      expect(path(router), AppRouteNames.buyerProfile);
      expect(seen, [AppRouteNames.buyerProfile]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dragging back to the original tab cancels', (tester) async {
      final router = await pumpApp(tester);
      final seen = track(router);

      final home = tabCentre(tester, 0);
      final gesture = await tester.startGesture(home);
      await tester.pump(const Duration(milliseconds: 16));
      await slide(tester, gesture, home, tabCentre(tester, 2));
      await tester.pump(const Duration(milliseconds: 200));
      expect(overlay, findsOneWidget);
      await slide(tester, gesture, tabCentre(tester, 2), home);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(overlay, findsNothing);
      expect(path(router), AppRouteNames.home);
      expect(seen, isEmpty);
    });

    testWidgets('an external navigation mid-switch drops the overlay', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      await tester.tapAt(tabCentre(tester, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(overlay, findsOneWidget);

      router.go(AppRouteNames.comparison);
      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
      expect(path(router), AppRouteNames.comparison);
    });
  });
}
