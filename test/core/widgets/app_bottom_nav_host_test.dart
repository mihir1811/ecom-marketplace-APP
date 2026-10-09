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
          AppRouteNames.cart,
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
}
