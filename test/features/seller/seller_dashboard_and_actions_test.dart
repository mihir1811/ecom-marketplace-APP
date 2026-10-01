import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_controller.dart';
import 'package:gemstone/core/auth/auth_providers.dart';
import 'package:gemstone/core/auth/auth_state.dart';
import 'package:gemstone/core/auth/auth_user.dart';
import 'package:gemstone/core/error/failure.dart';
import 'package:gemstone/core/error/result.dart';
import 'package:gemstone/features/seller/application/seller_insights_provider.dart';
import 'package:gemstone/features/seller/data/repositories/seller_insights_repository_impl.dart';
import 'package:gemstone/features/seller/domain/models/seller_insights.dart';
import 'package:gemstone/features/seller/domain/repositories/seller_insights_repository.dart';
import 'package:gemstone/features/seller/presentation/widgets/seller_order_decision.dart';

class _SignedInAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
    user: AuthUser(
      id: 'u1',
      fullName: 'Seller',
      username: 'seller',
      email: 's@example.com',
      role: 'seller',
    ),
  );
}

/// Each request waits until the test completes it.
class _ManualInsightsRepo implements SellerInsightsRepository {
  final pending =
      <SalesRange, Completer<Result<SellerDashboardSnapshot, Failure>>>{};

  @override
  Future<Result<SellerDashboardSnapshot, Failure>> getDashboard({
    required SellerDashboardParams params,
    CancelToken? cancelToken,
  }) {
    final c = Completer<Result<SellerDashboardSnapshot, Failure>>();
    pending[params.range] = c;
    return c.future;
  }

  void succeed(SalesRange range) {
    pending.remove(range)!.complete(
      Result.success(
        SellerDashboardSnapshot(
          metrics: const [],
          chartBuckets: [
            InsightsChartBucket(
              label: range.name,
              totalSales: 1,
              productsSold: 0,
              orders: 0,
            ),
          ],
          recentOrders: const [],
          fetchedAt: DateTime(2026, 10, 1),
          params: SellerDashboardParams(range: range),
        ),
      ),
    );
  }

  void fail(SalesRange range) {
    pending.remove(range)!.complete(
      Result.failure(const NetworkFailure('offline')),
    );
  }

  @override
  Future<Result<SellerAnalyticsSnapshot, Failure>> getAnalytics({
    required AnalyticsRange range,
    CancelToken? cancelToken,
  }) => throw UnimplementedError();

  @override
  void invalidateCache() {}
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('SellerDashboardNotifier', () {
    late _ManualInsightsRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _ManualInsightsRepo();
      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_SignedInAuth.new),
          sellerInsightsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('a slow monthly response never lands under "Daily"', () async {
      container.listen(sellerDashboardProvider, (_, _) {});
      await _settle();
      expect(repo.pending.keys, [SalesRange.monthly]);

      final switching = container
          .read(sellerDashboardProvider.notifier)
          .setParams(const SellerDashboardParams(range: SalesRange.daily));
      repo.succeed(SalesRange.daily);
      await switching;
      repo.succeed(SalesRange.monthly); // late, stale response
      await _settle();

      final state = container.read(sellerDashboardProvider);
      expect(state.params.range, SalesRange.daily);
      expect(state.snapshot?.params.range, SalesRange.daily);
      expect(state.snapshot?.chartBuckets.single.label, 'daily');
    });

    test('a failed switch keeps the old snapshot marked as stale', () async {
      container.listen(sellerDashboardProvider, (_, _) {});
      await _settle();
      repo.succeed(SalesRange.monthly);
      await _settle();

      final switching = container
          .read(sellerDashboardProvider.notifier)
          .setParams(const SellerDashboardParams(range: SalesRange.quarterly));
      repo.fail(SalesRange.quarterly);
      await switching;

      final state = container.read(sellerDashboardProvider);
      expect(state.params.range, SalesRange.quarterly);
      expect(state.errorMessage, 'offline');
      // The screen hides this chart because its range differs.
      expect(state.snapshot?.params.range, SalesRange.monthly);
    });
  });

  group('SellerActionConfirmDialog', () {
    Future<void> open(
      WidgetTester tester,
      Future<Failure?> Function(WidgetRef ref) onConfirm,
      List<bool?> results,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  results.add(
                    await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => SellerActionConfirmDialog(
                        title: 'Confirm Order',
                        message: 'Are you sure you want to accept this order?',
                        confirmLabel: 'Confirm',
                        onConfirm: onConfirm,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Cancel closes without running the action', (tester) async {
      var calls = 0;
      final results = <bool?>[];
      await open(tester, (_) async {
        calls++;
        return null;
      }, results);
      expect(
        find.text('Are you sure you want to accept this order?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(results, [false]);
    });

    testWidgets('Confirm runs once, shows progress, closes on success', (
      tester,
    ) async {
      var calls = 0;
      final gate = Completer<Failure?>();
      final results = <bool?>[];
      await open(tester, (_) {
        calls++;
        return gate.future;
      }, results);

      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Both buttons are disabled while the request runs.
      await tester.tap(find.text('Cancel'));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls, 1);

      gate.complete(null);
      await tester.pumpAndSettle();
      expect(results, [true]);
      expect(find.byType(SellerActionConfirmDialog), findsNothing);
    });

    testWidgets('a failure keeps the dialog open with the error', (
      tester,
    ) async {
      final results = <bool?>[];
      await open(
        tester,
        (_) async => const ValidationFailure('Order already processed.'),
        results,
      );
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Order already processed.'), findsOneWidget);
      expect(find.byType(SellerActionConfirmDialog), findsOneWidget);
      expect(results, isEmpty);
    });
  });
}
