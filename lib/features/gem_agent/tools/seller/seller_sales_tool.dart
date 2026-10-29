import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../seller/application/seller_insights_provider.dart';
import '../../../seller/data/repositories/seller_insights_repository_impl.dart';
import '../../../seller/domain/models/seller_insights.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';
import '../account/agent_period.dart';

/// Seller sales analytics for any window: revenue, units, orders, the
/// change against the previous equal window, and a bar chart — answered in
/// the sheet. Uses the dashboard's own `/seller/stats` aggregation.
class SellerSalesTool extends AccountTool {
  const SellerSalesTool();

  static const _metrics = {
    'sales': DashboardMetric.totalSales,
    'units': DashboardMetric.productsSold,
    'orders': DashboardMetric.orders,
  };

  @override
  String get name => 'seller_sales_report';

  @override
  AgentToolAccess get access => AgentToolAccess.seller;

  @override
  String get description =>
      'Seller only: sales analytics — revenue, units sold, order count, '
      'trend vs the previous period and a chart. Use for any sales, '
      'revenue, performance or "how is my business" question.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      ...AgentPeriod.schema(
        hint: 'Window to report. Default this_month when none was said.',
      ),
      'metric': {
        'type': 'string',
        'enum': _metrics.keys.toList(),
        'description': 'What to chart; default sales.',
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
"sales this month", "how much did I sell last week", "revenue this year", "compare with last month" → seller_sales_report with the period; "units"/"pieces sold" → metric "units". Answer from the returned numbers only; never compute figures the tool did not return.''';

  @override
  String progressLabel(Map<String, Object?> args) => 'Crunching your sales…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    var (period, range) = AgentPeriod.read(
      args,
      context.now,
      fallback: AgentPeriod.thisMonth,
    );
    if (range == null) {
      // "All time": the yearly view covers the last seven years.
      period = AgentPeriod.thisYear;
      range = period.range(context.now)!;
    }
    final metric =
        _metrics[args['metric']?.toString()] ?? DashboardMetric.totalSales;
    final repo = context.ref.read(sellerInsightsRepositoryProvider);
    SellerDashboardParams params(DateRangeDays r) => SellerDashboardParams(
      range: SalesRange.custom,
      customStart: r.from,
      customEnd: r.to,
    );

    final (current, earlier) = await (
      repo.getDashboard(
        params: params(range),
        cancelToken: context.cancelToken,
      ),
      repo.getDashboard(
        params: params(range.previous),
        cancelToken: context.cancelToken,
      ),
    ).wait;
    final SellerDashboardSnapshot now;
    switch (current) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        now = value;
    }
    // The comparison is optional; a failed previous window just drops it.
    final before = switch (earlier) {
      Success(:final value) => value,
      ResultFailure() => null,
    };

    final totals = _Totals.of(now);
    final previous = before == null ? null : _Totals.of(before);
    double? trend(double a, double? b) =>
        b == null || b <= 0 ? null : ((a - b) / b) * 100;

    final salesTrend = trend(totals.sales, previous?.sales);
    final when = period.label;
    final change = salesTrend == null
        ? ''
        : ' (${salesTrend >= 0 ? 'up' : 'down'} '
              '${salesTrend.abs().toStringAsFixed(0)}% vs the previous period)';
    final summary = totals.orders == 0
        ? 'No paid sales $when.'
        : 'Sales $when: ${AppCurrency.usd(totals.sales, decimals: 0)} from '
              '${AccountTool.plural(totals.orders.round(), 'order')}, '
              '${AccountTool.plural(totals.units.round(), 'unit')} sold$change.';

    final series = now.chartFor(metric);
    final format = metric == DashboardMetric.totalSales
        ? AgentValueFormat.usd
        : AgentValueFormat.count;
    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;

    return ToolSuccess(
      summary: summary,
      completesTurn: true,
      effects: open ? [_OpenDashboard(params(range))] : const [],
      cards: [
        AgentStatsCard(
          stats: [
            AgentStat(
              'Sales',
              AppCurrency.usd(totals.sales, decimals: 0),
              trend: salesTrend,
            ),
            AgentStat(
              'Orders',
              '${totals.orders.round()}',
              trend: trend(totals.orders, previous?.orders),
            ),
            AgentStat(
              'Units sold',
              '${totals.units.round()}',
              trend: trend(totals.units, previous?.units),
            ),
            AgentStat(
              'Avg order',
              totals.orders > 0
                  ? AppCurrency.usd(totals.sales / totals.orders, decimals: 0)
                  : '—',
            ),
          ],
        ),
        if (series.values.length > 1)
          AgentChartCard(
            title: switch (metric) {
              DashboardMetric.productsSold => 'Units sold',
              DashboardMetric.orders => 'Orders',
              _ => 'Sales',
            },
            labels: series.labels,
            values: series.values,
            format: format,
            caption: when,
            action: const AgentCardAction(
              'Open dashboard',
              AppRouteNames.sellerDashboard,
            ),
          ),
      ],
      data: {
        'period': period.apiName,
        'from': range.isoFrom,
        'to': range.isoTo,
        'sales_usd': totals.sales.round(),
        'orders': totals.orders.round(),
        'units_sold': totals.units.round(),
        if (previous != null) ...{
          'previous_sales_usd': previous.sales.round(),
          'previous_orders': previous.orders.round(),
        },
        'sales_change_pct': ?salesTrend?.round(),
        'buckets': {
          for (var i = 0; i < series.labels.length; i++)
            series.labels[i]: series.values[i].round(),
        },
      },
    );
  }
}

class _Totals {
  const _Totals(this.sales, this.units, this.orders);

  factory _Totals.of(SellerDashboardSnapshot s) {
    var sales = 0.0, units = 0.0, orders = 0.0;
    for (final b in s.chartBuckets) {
      sales += b.totalSales;
      units += b.productsSold;
      orders += b.orders;
    }
    return _Totals(sales, units, orders);
  }

  final double sales;
  final double units;
  final double orders;
}

/// Puts the dashboard on the asked window, then opens it.
class _OpenDashboard extends AgentEffect {
  const _OpenDashboard(this.params);

  final SellerDashboardParams params;

  @override
  Future<void> apply(Ref ref) async {
    await const OpenPageEffect(AppRouteNames.sellerDashboard).apply(ref);
    await ref.read(sellerDashboardProvider.notifier).setParams(params);
  }
}
