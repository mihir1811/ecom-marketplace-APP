import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/haptics/app_haptics.dart';
import 'package:gemworld/core/router/route_names.dart';
import 'package:gemworld/core/widgets/navigation/bottom_nav/app_bottom_nav_bar.dart';
import 'package:gemworld/core/widgets/navigation/bottom_nav/app_bottom_nav_host.dart';
import 'package:gemworld/core/widgets/navigation/bottom_nav/tab_reveal_transition.dart';
import 'package:gemworld/features/comparison/presentation/widgets/compare_dock_button.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() => AppHaptics.debugDisable = true);

  GoRouter buildRouter() {
    Widget page(String name) => Scaffold(
      drawer: const Drawer(child: Text('drawer')),
      onDrawerChanged: AppBottomNavHost.reportDrawer,
      body: name == AppRouteNames.buyerWishlist
          ? ListView(
              children: [
                for (var i = 0; i < 80; i++)
                  SizedBox(height: 60, child: Text('$name $i')),
              ],
            )
          : Center(child: Text(name)),
    );
    return GoRouter(
      initialLocation: AppRouteNames.home,
      observers: [appPopupRouteObserver],
      routes: [
        for (final path in [
          AppRouteNames.home,
          AppRouteNames.buyerWishlist,
          AppRouteNames.auctions,
          AppRouteNames.buyerProfile,
          AppRouteNames.comparison,
          AppRouteNames.gemstones,
          AppRouteNames.gemstoneResults,
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

  double pagePadding(WidgetTester tester) =>
      MediaQuery.paddingOf(tester.element(find.byType(Scaffold).last)).bottom;

  /// Hit area of the tab labelled [label].
  Finder tabArea(String label) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == label,
  );

  bool compact(WidgetTester tester) =>
      tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar)).compact;

  testWidgets('pages run behind the floating dock, padded clear of it', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(pageHeight(tester), closeTo(screen, 0.5));
    expect(pagePadding(tester), closeTo(AppBottomNavBar.clearance(0), 0.5));

    router.push(AppRouteNames.comparison);
    await tester.pumpAndSettle();
    expect(pageHeight(tester), closeTo(screen, 0.5));
    expect(pagePadding(tester), 0);

    router.pop();
    await tester.pumpAndSettle();
    expect(pagePadding(tester), closeTo(AppBottomNavBar.clearance(0), 0.5));
  });

  testWidgets('listings put the compare button after Profile, in line', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final button = find.byType(CompareDockButton);
    expect(tester.getSize(button).width, 0);

    router.push(AppRouteNames.gemstoneResults);
    await tester.pumpAndSettle();
    final profile = tester.getRect(tabArea('Profile'));
    final rect = tester.getRect(button);
    final screen =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(rect.width, closeTo(AppBottomNavBar.trailingSize, 0.5));
    expect(rect.left, greaterThan(profile.right));
    // Dock and button are centred as one group.
    // The tab hit row spans the whole pill.
    final dockLeft = tester.getRect(tabArea('Home')).left;
    expect(screen - rect.right, closeTo(dockLeft, 1));
    // Hit areas reach 8px above the pill, so its centre sits 4px lower.
    expect(rect.center.dy, closeTo(profile.center.dy + 4, 1));

    router.pop();
    await tester.pumpAndSettle();
    expect(tester.getSize(button).width, 0);
  });

  testWidgets('the compare button waits for the dock to settle first', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final button = find.byType(CompareDockButton);
    router.push(AppRouteNames.comparison);
    await tester.pumpAndSettle();

    // The dock slides back in; the button has no room yet.
    router.go(AppRouteNames.gemstoneResults);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(button).width, 0);

    await tester.pumpAndSettle();
    expect(
      tester.getSize(button).width,
      closeTo(AppBottomNavBar.trailingSize, 0.5),
    );
  });

  testWidgets('taps beside the floating dock reach the page', (tester) async {
    await pumpApp(tester);
    final box = tester.getRect(find.byType(AppBottomNavBar));
    final bar = tester.renderObject(find.byType(AppBottomNavBar));
    bool inBar(Object target) {
      if (target is! RenderObject) return false;
      for (RenderObject? r = target; r != null; r = r.parent) {
        if (r == bar) return true;
      }
      return false;
    }

    final hit = tester.hitTestOnBinding(Offset(box.left + 4, box.bottom - 30));
    expect(hit.path.any((e) => inBar(e.target)), isFalse);
  });

  testWidgets('scrolling down folds the dock; scrolling back unfolds it', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    router.go(AppRouteNames.buyerWishlist);
    await tester.pumpAndSettle();
    expect(compact(tester), isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(compact(tester), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(compact(tester), isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(compact(tester), isTrue);

    // A tap on the folded dock only unfolds it.
    await tester.tap(tabArea('Profile'));
    await tester.pumpAndSettle();
    expect(compact(tester), isFalse);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRouteNames.buyerWishlist,
    );
  });

  testWidgets('the dock steps aside while a drawer is open', (tester) async {
    await pumpApp(tester);
    final dock = find.byType(AppBottomNavBar);
    expect(dock, findsOneWidget);

    tester.state<ScaffoldState>(find.byType(Scaffold).last).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsOneWidget);
    expect(dock.hitTestable(), findsNothing);

    tester.state<ScaffoldState>(find.byType(Scaffold).last).closeDrawer();
    await tester.pumpAndSettle();
    expect(dock.hitTestable(), findsOneWidget);
  });

  testWidgets('tapping a tab navigates there', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRouteNames.buyerProfile,
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

  /// Category images shimmer while loading, so the menu never settles.
  Future<void> openMenu(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Categories pops a menu above the bar; a pick opens it', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('Categories'));
    await openMenu(tester);
    expect(find.bySemanticsLabel('Gemstones'), findsOneWidget);
    // A popup, not a page: the bar stays on screen.
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Gemstones'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Gemstones'), findsNothing);
    // Opened like the home screen's collection tiles do.
    expect(find.text(AppRouteNames.gemstones), findsOneWidget);
  });

  testWidgets(
    'a tab tap with the category menu up closes it and opens that tab',
    (tester) async {
      final router = await pumpApp(tester);

      await tester.tap(find.bySemanticsLabel('Categories'));
      await openMenu(tester);
      await tester.tapAt(tester.getCenter(tabArea('Profile')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Gemstones'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        AppRouteNames.buyerProfile,
      );
    },
  );

  testWidgets('the category menu sits above the dock, not under it', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('Categories'));
    await openMenu(tester);
    final dockTop = tester.getRect(find.byType(AppBottomNavBar)).top;
    final lowest = tester.getRect(find.bySemanticsLabel('Gemstones').last);
    expect(lowest.bottom, lessThan(dockTop));

    await tester.tap(find.byType(AppBottomNavBar), warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('tapping the bar again closes the category menu', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.bySemanticsLabel('Categories'));
    await openMenu(tester);
    await tester.tap(find.byType(AppBottomNavBar), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Gemstones'), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRouteNames.home,
    );
  });

  group('tab reveal transition', () {
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

    Offset tabCentre(WidgetTester tester, int index) =>
        tester.getCenter(tabArea(const ['Home', 'Wishlist', 'Profile'][index]));

    ClipPath reveal(WidgetTester tester) => tester.widget<ClipPath>(
      find
          .descendant(
            of: find.byType(TabRevealTransition),
            matching: find.byType(ClipPath),
          )
          .first,
    );

    testWidgets('a tap grows the tab out of the touch point once', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      final seen = track(router);

      await tester.tapAt(tabCentre(tester, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(path(router), AppRouteNames.buyerProfile);
      final clip = reveal(tester).clipper!.getClip(tester.view.physicalSize);
      // Still a small blob hugging the bar.
      expect(clip.getBounds().top, greaterThan(200));

      await tester.pumpAndSettle();
      expect(reveal(tester).clipper, isNull);
      expect(seen, [AppRouteNames.buyerProfile]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an external navigation mid-switch drops the reveal', (
      tester,
    ) async {
      final router = await pumpApp(tester);
      await tester.tapAt(tabCentre(tester, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(reveal(tester).clipper, isNotNull);

      router.go(AppRouteNames.comparison);
      await tester.pumpAndSettle();
      expect(reveal(tester).clipper, isNull);
      expect(path(router), AppRouteNames.comparison);
    });
  });
}
