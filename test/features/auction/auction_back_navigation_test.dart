import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/router/route_names.dart';
import 'package:gemstone/core/widgets/app_system_back_scope.dart';
import 'package:go_router/go_router.dart';

/// Mirrors the auction route shape: list + detail wrapped in
/// [AppSystemBackScope], reached by `go` (drawer / notification) or `push`.
GoRouter _router() {
  Widget page(String label) => Scaffold(
    body: Builder(
      builder: (context) => Column(
        children: [
          Text(label),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(content: Text('popup')),
            ),
            child: const Text('open popup'),
          ),
        ],
      ),
    ),
  );

  return GoRouter(
    initialLocation: AppRouteNames.home,
    routes: [
      GoRoute(
        path: AppRouteNames.home,
        builder: (_, _) => AppSystemBackScope(child: page('home')),
      ),
      GoRoute(
        path: AppRouteNames.auctions,
        builder: (_, _) => AppSystemBackScope(child: page('auctions')),
      ),
      GoRoute(
        path: AppRouteNames.auctionDetail,
        builder: (_, state) => AppSystemBackScope(
          child: page('auction ${state.pathParameters['auctionId']}'),
        ),
      ),
    ],
  );
}

void main() {
  late List<String> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call.method);
          return null;
        });
  });

  Future<GoRouter> pumpRouter(WidgetTester tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  bool exited() => platformCalls.contains('SystemNavigator.pop');

  testWidgets('auctions opened from the drawer: back goes home, no exit', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    router.go(AppRouteNames.auctions);
    await tester.pumpAndSettle();

    await back(tester);
    expect(find.text('home'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('auction → bid screen → back returns to the list', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    router.go(AppRouteNames.auctions);
    await tester.pumpAndSettle();
    router.push(AppRouteNames.auctionDetailPath('a1'));
    await tester.pumpAndSettle();

    await back(tester);
    expect(find.text('auctions'), findsOneWidget);
    await back(tester);
    expect(find.text('home'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('auction → bid → auction → back unwinds one screen at a time', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    router.push(AppRouteNames.auctions);
    await tester.pumpAndSettle();
    router.push(AppRouteNames.auctionDetailPath('a1'));
    await tester.pumpAndSettle();
    router.push(AppRouteNames.auctionDetailPath('a2'));
    await tester.pumpAndSettle();

    await back(tester);
    expect(find.text('auction a1'), findsOneWidget);
    await back(tester);
    expect(find.text('auctions'), findsOneWidget);
    await back(tester);
    expect(find.text('home'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('auction opened from a notification: back goes home', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    router.go(AppRouteNames.auctionDetailPath('a1'));
    await tester.pumpAndSettle();

    await back(tester);
    expect(find.text('home'), findsOneWidget);
    expect(exited(), isFalse);
  });

  testWidgets('back closes an open popup before the auction screen', (
    tester,
  ) async {
    final router = await pumpRouter(tester);
    router.go(AppRouteNames.auctionDetailPath('a1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open popup'));
    await tester.pumpAndSettle();
    expect(find.text('popup'), findsOneWidget);

    await back(tester);
    expect(find.text('popup'), findsNothing);
    expect(find.text('auction a1'), findsOneWidget);
    expect(exited(), isFalse);
  });
}
