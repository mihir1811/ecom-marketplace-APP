import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/features/seller/data/mappers/seller_insights_aggregator.dart';
import 'package:gemstone/features/seller/data/mappers/seller_stats_mapper.dart';
import 'package:gemstone/features/seller/domain/models/seller_insights.dart';
import 'package:gemstone/features/seller/domain/models/seller_stats.dart';

SellerStatsChart chart(List<String> labels, List<double> values) =>
    SellerStatsChart(labels: labels, values: values);

void main() {
  // Thursday 1 October 2026, mid-afternoon local time.
  final now = DateTime(2026, 10, 1, 15, 30);

  group('dashboardPlan', () {
    SellerStatsQuery plan(SalesRange range, {DateTime? start, DateTime? end}) {
      return SellerInsightsAggregator.dashboardPlan(
        SellerDashboardParams(range: range, customStart: start, customEnd: end),
        now: now,
      ).query;
    }

    test('every preset ends today and starts at a calendar boundary', () {
      expect(plan(SalesRange.daily).toQueryParameters(), {
        'period': 'daily',
        'fromDate': '2026-09-25',
        'toDate': '2026-10-01',
      });
      // Weekly starts on the Monday six weeks before this week's Monday.
      expect(plan(SalesRange.weekly).toQueryParameters(), {
        'period': 'weekly',
        'fromDate': '2026-08-17',
        'toDate': '2026-10-01',
      });
      expect(plan(SalesRange.monthly).toQueryParameters(), {
        'period': 'monthly',
        'fromDate': '2026-04-01',
        'toDate': '2026-10-01',
      });
      expect(plan(SalesRange.yearly).toQueryParameters(), {
        'period': 'yearly',
        'fromDate': '2020-01-01',
        'toDate': '2026-10-01',
      });
    });

    test('quarterly asks for 21 months aligned to a quarter start', () {
      final p = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.quarterly),
        now: now,
      );
      expect(p.regroups, isTrue);
      expect(p.buckets.map((b) => b.label), [
        'Q2\n2025',
        'Q3\n2025',
        'Q4\n2025',
        'Q1\n2026',
        'Q2\n2026',
        'Q3\n2026',
        'Q4\n2026',
      ]);
      expect(p.query.toQueryParameters(), {
        'period': 'monthly',
        'fromDate': '2025-04-01', // Q2 2025 … Q4 2026 → 7 quarters
        'toDate': '2026-10-01',
      });
    });

    test('custom ranges pick a readable bucket size and fix swapped dates', () {
      final short = plan(
        SalesRange.custom,
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 20),
      );
      expect(short.period, SellerStatsPeriod.daily);

      final swapped = plan(
        SalesRange.custom,
        start: DateTime(2026, 9, 20, 18),
        end: DateTime(2026, 6, 1, 9),
      );
      expect(swapped.toQueryParameters(), {
        'period': 'weekly',
        'fromDate': '2026-06-01',
        'toDate': '2026-09-20',
      });

      expect(
        plan(
          SalesRange.custom,
          start: DateTime(2025, 1, 1),
          end: DateTime(2026, 6, 30),
        ).period,
        SellerStatsPeriod.monthly,
      );
      expect(
        plan(
          SalesRange.custom,
          start: DateTime(2019, 1, 1),
          end: DateTime(2026, 6, 30),
        ).period,
        SellerStatsPeriod.yearly,
      );
    });
  });

  group('dashboard', () {
    final monthlyPlan = SellerInsightsAggregator.dashboardPlan(
      const SellerDashboardParams(range: SalesRange.monthly),
      now: now,
    );
    const months = [
      'Apr 26',
      'May 26',
      'Jun 26',
      'Jul 26',
      'Aug 26',
      'Sep 26',
      'Oct 26',
    ];

    test(
      'seller created in June: earlier months stay 0, each month is its own',
      () {
        final stats = SellerStats(
          salesChart: chart(months, [0, 0, 500, 0, 1200, 300, 80]),
          productsSoldChart: chart(months, [0, 0, 1, 0, 3, 1, 1]),
          ordersChart: chart(months, [0, 0, 1, 1, 2, 1, 1]),
          inventoryValue: 500,
          liveProducts: 4,
        );

        final snapshot = SellerInsightsAggregator.dashboard(
          stats: stats,
          plan: monthlyPlan,
          now: now,
        );

        final sales = snapshot.chartFor(DashboardMetric.totalSales);
        expect(sales.labels, [
          'Apr\n2026',
          'May\n2026',
          'Jun\n2026',
          'Jul\n2026',
          'Aug\n2026',
          'Sep\n2026',
          'Oct\n2026',
        ]);
        expect(sales.details.last, 'Oct 2026 (Oct 1, 2026)');
        expect(sales.values, [0, 0, 500, 0, 1200, 300, 80]);
        expect(snapshot.chartFor(DashboardMetric.orders).values, [
          0,
          0,
          1,
          1,
          2,
          1,
          1,
        ]);
        expect(snapshot.chartFor(DashboardMetric.productsSold).values, [
          0,
          0,
          1,
          0,
          3,
          1,
          1,
        ]);
        // Today's inventory is not copied into past months.
        expect(snapshot.chartFor(DashboardMetric.inventoryValue).values, [
          0,
          0,
          0,
          0,
          0,
          0,
          500,
        ]);
        // KPI cards add up the same buckets the chart shows.
        expect(snapshot.metrics[0].value, r'$2080.00');
        expect(snapshot.metrics[1].value, '6');
        expect(snapshot.metrics[2].value, '6');
        expect(snapshot.chartEndDate, DateTime(2026, 10, 1));
      },
    );

    test('new seller with no history shows zeros, not repeated values', () {
      final stats = SellerStats(
        salesChart: chart(months, List.filled(7, 0)),
        productsSoldChart: chart(months, List.filled(7, 0)),
        ordersChart: chart(months, List.filled(7, 0)),
      );
      final snapshot = SellerInsightsAggregator.dashboard(
        stats: stats,
        plan: monthlyPlan,
        now: now,
      );
      for (final metric in DashboardMetric.values) {
        expect(snapshot.chartFor(metric).values, List.filled(7, 0.0));
      }
      expect(snapshot.metrics[0].value, r'$0.00');
    });

    test('a past custom range never shows today\'s inventory', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        SellerDashboardParams(
          range: SalesRange.custom,
          customStart: DateTime(2026, 3, 1),
          customEnd: DateTime(2026, 3, 7),
        ),
        now: now,
      );
      final days = [
        'Mar 1',
        'Mar 2',
        'Mar 3',
        'Mar 4',
        'Mar 5',
        'Mar 6',
        'Mar 7',
      ];
      final snapshot = SellerInsightsAggregator.dashboard(
        stats: SellerStats(
          salesChart: chart(days, [0, 10, 0, 0, 0, 0, 0]),
          inventoryValue: 900,
        ),
        plan: plan,
        now: now,
      );
      expect(
        snapshot.chartFor(DashboardMetric.inventoryValue).values,
        List.filled(7, 0.0),
      );
      expect(snapshot.chartFor(DashboardMetric.totalSales).values[1], 10);
    });

    test('quarterly view sums each calendar quarter, current one to date', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.quarterly),
        now: now,
      );
      // The server returns one bucket per month from Apr 2025 to Oct 2026:
      // 19 months, because the current quarter has only started.
      expect(plan.sourceBuckets, hasLength(19));
      final labels = [for (var i = 0; i < 19; i++) 'm$i'];
      final values = [for (var i = 0; i < 19; i++) (i + 1).toDouble()];
      final snapshot = SellerInsightsAggregator.dashboard(
        stats: SellerStats(salesChart: chart(labels, values)),
        plan: plan,
        now: now,
      );
      final sales = snapshot.chartFor(DashboardMetric.totalSales);
      expect(sales.labels.first, 'Q2\n2025');
      expect(sales.labels.last, 'Q4\n2026');
      expect(sales.values, [6, 15, 24, 33, 42, 51, 19]);
      // Total equals the sum of all months: nothing dropped or repeated.
      expect(snapshot.metrics[0].value, r'$190.00');
    });

    test('daily shows each day on its own, never a monthly total', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.daily),
        now: now,
      );
      final days = [
        'Sep 25',
        'Sep 26',
        'Sep 27',
        'Sep 28',
        'Sep 29',
        'Sep 30',
        'Oct 1',
      ];
      const stats = SellerStats(
        salesChart: SellerStatsChart(
          labels: [
            'Sep 25',
            'Sep 26',
            'Sep 27',
            'Sep 28',
            'Sep 29',
            'Sep 30',
            'Oct 1',
          ],
          values: [0, 10, 0, 0, 25, 0, 5],
          period: 'daily',
        ),
      );
      expect(
        SellerInsightsAggregator.periodMismatch(stats, plan.query),
        isNull,
      );
      final snapshot = SellerInsightsAggregator.dashboard(
        stats: stats,
        plan: plan,
        now: now,
      );
      final sales = snapshot.chartFor(DashboardMetric.totalSales);
      expect(sales.labels, days);
      expect(sales.values, [0, 10, 0, 0, 25, 0, 5]);
    });

    test('monthly figures returned for a daily request are rejected', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.daily),
        now: now,
      );
      // The period field says monthly.
      expect(
        SellerInsightsAggregator.periodMismatch(
          const SellerStats(
            salesChart: SellerStatsChart(
              labels: ['Sep 26', 'Oct 26'],
              values: [900, 40],
              period: 'monthly',
            ),
          ),
          plan.query,
        ),
        contains('monthly'),
      );
      // No period field, but the buckets cannot be daily ones.
      expect(
        SellerInsightsAggregator.periodMismatch(
          SellerStats(salesChart: chart(['Sep 26', 'Oct 26'], [900, 40])),
          plan.query,
        ),
        isNotNull,
      );
    });

    test('weekly buckets are whole Monday weeks, last one to date', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.weekly),
        now: now,
      );
      expect(plan.buckets, hasLength(7));
      expect(plan.buckets.first.start, DateTime(2026, 8, 17));
      expect(plan.buckets.first.end, DateTime(2026, 8, 23));
      expect(plan.buckets.last.start, DateTime(2026, 9, 28));
      expect(plan.buckets.last.end, DateTime(2026, 10, 1));
      expect(plan.buckets.last.serverLabel, 'Wk Sep 28');
    });

    test('fewer server buckets are matched by label, gaps stay 0', () {
      final plan = SellerInsightsAggregator.dashboardPlan(
        const SellerDashboardParams(range: SalesRange.monthly),
        now: now,
      );
      final snapshot = SellerInsightsAggregator.dashboard(
        stats: SellerStats(salesChart: chart(['Jun 26', 'Sep 26'], [70, 30])),
        plan: plan,
        now: now,
      );
      expect(snapshot.chartFor(DashboardMetric.totalSales).values, [
        0,
        0,
        70,
        0,
        0,
        30,
        0,
      ]);
    });

    test('every preset has 7 contiguous buckets ending today', () {
      for (final range in [
        SalesRange.daily,
        SalesRange.weekly,
        SalesRange.monthly,
        SalesRange.quarterly,
        SalesRange.yearly,
      ]) {
        final buckets = SellerInsightsAggregator.dashboardPlan(
          SellerDashboardParams(range: range),
          now: now,
        ).buckets;
        expect(buckets, hasLength(7), reason: range.name);
        expect(buckets.last.contains(now), isTrue, reason: range.name);
        expect(buckets.last.end, DateTime(2026, 10, 1), reason: range.name);
        for (var i = 1; i < buckets.length; i++) {
          final prevEnd = buckets[i - 1].end;
          expect(
            buckets[i].start,
            DateTime(prevEnd.year, prevEnd.month, prevEnd.day + 1),
            reason: '${range.name} bucket $i',
          );
        }
      }
    });
  });

  group('analytics', () {
    test('30 days are charted per day and 90 days per week', () {
      final last30 = SellerInsightsAggregator.analyticsQueries(
        AnalyticsRange.last30,
        now: now,
      ).current;
      expect(last30.period, SellerStatsPeriod.daily);
      final last90 = SellerInsightsAggregator.analyticsQueries(
        AnalyticsRange.last90,
        now: now,
      ).current;
      expect(last90.period, SellerStatsPeriod.weekly);
    });

    test('compares against the window right before, without overlap', () {
      final q = SellerInsightsAggregator.analyticsQueries(
        AnalyticsRange.last30,
        now: now,
      );
      expect(q.current.toQueryParameters()['fromDate'], '2026-09-02');
      expect(q.current.toQueryParameters()['toDate'], '2026-10-01');
      expect(q.previous.toQueryParameters()['fromDate'], '2026-08-03');
      expect(q.previous.toQueryParameters()['toDate'], '2026-09-01');
    });

    test(
      'year to date compares with the same days last year (leap day safe)',
      () {
        final q = SellerInsightsAggregator.analyticsQueries(
          AnalyticsRange.year,
          now: DateTime(2028, 2, 29),
        );
        expect(q.current.toQueryParameters()['fromDate'], '2028-01-01');
        expect(q.previous.toQueryParameters()['fromDate'], '2027-01-01');
        expect(q.previous.toQueryParameters()['toDate'], '2027-02-28');
      },
    );

    test('KPIs and the revenue series come from the seller stats', () {
      final q = SellerInsightsAggregator.analyticsQueries(
        AnalyticsRange.last7,
        now: now,
      );
      List<String> l(int n) => [for (var i = 0; i < n; i++) 'd$i'];
      final snapshot = SellerInsightsAggregator.analytics(
        current: SellerStats(
          salesChart: chart(l(7), [300, 0, 0, 0, 0, 0, 100]),
          ordersChart: chart(l(7), [2, 0, 0, 0, 0, 0, 2]),
          productsSoldChart: chart(l(7), [3, 0, 0, 0, 0, 0, 1]),
        ),
        previous: SellerStats(
          salesChart: chart(l(7), [100, 0, 0, 0, 0, 0, 100]),
          ordersChart: chart(l(7), [1, 0, 0, 0, 0, 0, 1]),
        ),
        currentQuery: q.current,
        refunds: const [],
        now: now,
      );
      expect(snapshot.kpis[0].value, r'$400.00');
      expect(snapshot.kpis[0].delta, '+100.0%');
      expect(snapshot.kpis[1].value, '4');
      expect(snapshot.kpis[2].value, r'$100.00');
      expect(snapshot.kpis[3].value, '4');
      expect(snapshot.revenueSeries.values, [300, 0, 0, 0, 0, 0, 100]);
      expect(snapshot.revenueSeries.labels.first, 'Sep 25');
      expect(snapshot.revenueSeries.labels.last, 'Oct 1');
      expect(snapshot.categorySlices, isEmpty);
    });
  });

  group('SellerStatsMapper', () {
    test('missing or bad values become 0 for that bucket only', () {
      final stats = SellerStatsMapper.fromEnvelope({
        'success': true,
        'data': {
          'salesChart': {
            'labels': ['Jan', 'Feb', 'Mar', 'Apr'],
            'values': [null, 'x', 500, '250.5'],
          },
          'ordersChart': {
            'labels': ['Jan', 'Feb'],
            'values': [1],
          },
          'orders': {'delivered': 3, 'pending': '2'},
          'inventoryValue': '1200.5',
          'liveProducts': 7,
        },
      });
      expect(stats.salesChart.values, [0, 0, 500, 250.5]);
      expect(stats.ordersChart.values, [1, 0]);
      expect(stats.productsSoldChart.values, isEmpty);
      expect(stats.deliveredOrders, 3);
      expect(stats.pendingOrders, 2);
      expect(stats.inventoryValue, 1200.5);
      expect(stats.liveProducts, 7);
    });
  });
}
