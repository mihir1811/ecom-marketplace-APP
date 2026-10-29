import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../refunds/data/repositories/refund_repository_impl.dart';
import '../../../refunds/domain/models/refund_request.dart';
import '../../../seller/data/repositories/seller_order_repository_impl.dart';
import '../../../seller/domain/models/seller_order.dart';
import '../../../seller/domain/seller_order_board.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';
import '../account/agent_period.dart';

/// Incoming orders and refund requests for the signed-in seller.
///
/// Counts come from the same [SellerOrderBoard] the Orders screen uses, so
/// the agent and the screen never disagree. With results it opens Orders
/// already on the right tab and date range; with none it just says so.
class SellerOrdersTool extends AccountTool {
  const SellerOrdersTool();

  static const _statuses = {
    'pending': SellerOrderCategory.pending,
    'confirmed': SellerOrderCategory.confirmed,
    'cancelled': SellerOrderCategory.cancelled,
    'refund_requested': SellerOrderCategory.refundRequested,
    'refund_approved': SellerOrderCategory.refundApproved,
    'refund_rejected': SellerOrderCategory.refundRejected,
  };

  static const _sorts = {
    'newest': SellerOrderSort.newest,
    'oldest': SellerOrderSort.oldest,
    'highest_value': SellerOrderSort.highestValue,
    'lowest_value': SellerOrderSort.lowestValue,
  };

  /// Orders are read newest first in pages of [_pageSize] until the window
  /// starts; [_maxPages] bounds a very old "all time" scan.
  static const _pageSize = 50;
  static const _maxPages = 6;

  @override
  String get name => 'seller_orders';

  @override
  AgentToolAccess get access => AgentToolAccess.seller;

  @override
  String get description =>
      'Seller only: orders customers placed with the user (and refund '
      'requests). Counts, values, status, date window. Opens the seller '
      'Orders screen filtered when there are results.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      ...AgentPeriod.schema(),
      'status': {
        'type': 'string',
        'enum': [..._statuses.keys, 'any'],
        'description':
            'pending = awaiting the seller\'s approval. Leave out for all.',
      },
      'search': {
        'type': 'string',
        'description': 'Order id, product or stock number the user named.',
      },
      'sort': {'type': 'string', 'enum': _sorts.keys.toList()},
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
Seller's incoming orders. "any orders today / new orders / orders arrived" → seller_orders {"period":"today"}. "pending orders" / "orders to approve" → status "pending". "refund requests" → status "refund_requested". "biggest orders this month" → period "this_month", sort "highest_value".
Use mode "answer" for pure counting questions ("how many orders this week?"); otherwise leave mode out and the Orders screen opens filtered.''';

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your orders…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final (period, range) = AgentPeriod.read(args, context.now);
    final status = _statuses[args['status']?.toString()];
    final sort = _sorts[args['sort']?.toString()] ?? SellerOrderSort.newest;
    final search = (args['search'] as String?)?.trim() ?? '';
    final mode = AnswerMode.parse(args['mode']);
    final wantsRefunds = status?.isRefund ?? false;

    final orders = await _loadOrders(context, since: range?.from);
    if (orders case ResultFailure(:final failure)) {
      return AccountTool.failureOf(failure);
    }
    var refunds = const <RefundRequest>[];
    if (wantsRefunds) {
      final loaded = await _loadRefunds(context);
      switch (loaded) {
        case ResultFailure(:final failure):
          return AccountTool.failureOf(failure);
        case Success(:final value):
          refunds = value;
      }
    }

    final board = SellerOrderBoard(
      orders: (orders as Success<List<SellerOrder>, Failure>).value,
      refunds: refunds,
    );
    final filters = SellerOrderFilters(
      sort: sort,
      from: range?.from,
      to: range?.to,
      search: search,
    );
    final categories = status != null
        ? [status]
        : SellerOrderCategory.values.where((c) => !c.isRefund).toList();
    final byCategory = {
      for (final c in categories) c: board.entries(c, filters),
    };
    final all = [
      for (final rows in byCategory.values) ...rows,
    ]..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
    if (sort != SellerOrderSort.newest) {
      all.sort(
        (a, b) => switch (sort) {
          SellerOrderSort.oldest => (a.date ?? DateTime(0)).compareTo(
            b.date ?? DateTime(0),
          ),
          SellerOrderSort.highestValue => b.valueUsd.compareTo(a.valueUsd),
          SellerOrderSort.lowestValue => a.valueUsd.compareTo(b.valueUsd),
          _ => 0,
        },
      );
    }

    final total = all.length;
    final value = all.fold<double>(0, (sum, e) => sum + e.valueUsd);
    final when = period == AgentPeriod.allTime ? '' : ' ${period.label}';
    final noun = wantsRefunds ? 'refund request' : 'order';
    final counts = {
      for (final entry in byCategory.entries) entry.key: entry.value.length,
    };

    // The tab to land on: the asked status, else whatever needs action.
    final tab =
        status ??
        (counts[SellerOrderCategory.pending]! > 0
            ? SellerOrderCategory.pending
            : counts.entries
                  .firstWhere(
                    (e) => e.value > 0,
                    orElse: () =>
                        const MapEntry(SellerOrderCategory.pending, 0),
                  )
                  .key);
    final preset = SellerOrdersPreset(
      category: tab,
      from: range?.from,
      to: range?.to,
      search: search,
      sort: sort,
    );

    final breakdown = [
      for (final e in counts.entries)
        if (e.value > 0 && categories.length > 1)
          '${e.value} ${e.key.label.toLowerCase()}',
    ];
    final statusWord = status == null || wantsRefunds
        ? ''
        : '${status.label.toLowerCase()} ';
    final summary = total == 0
        ? 'No $statusWord${noun}s$when.'
        : '${AccountTool.plural(total, '$statusWord$noun')}$when'
              '${breakdown.isEmpty ? '' : ': ${breakdown.join(', ')}'}'
              ' · ${AppCurrency.usd(value, decimals: 0)}';

    final open = mode == AnswerMode.open || (mode == null && total > 0);
    final cards = <AgentCard>[
      if (total > 0 && categories.length > 1)
        AgentStatsCard(
          stats: [
            AgentStat('Orders', '$total'),
            for (final e in counts.entries)
              if (e.value > 0) AgentStat(e.key.label, '${e.value}'),
            AgentStat('Value', AppCurrency.usd(value, decimals: 0)),
          ],
        ),
      if (total > 0)
        AgentListCard(
          rows: [for (final e in all.take(AccountTool.maxRows)) _row(e)],
          moreCount: total - AccountTool.maxRows,
          action: AgentCardAction('Open in Orders', preset.location),
        ),
    ];

    return ToolSuccess(
      summary: summary,
      completesTurn: true,
      cards: open ? const [] : cards,
      effects: open ? [OpenPageEffect(preset.location)] : const [],
      data: {
        'period': period.apiName,
        if (range != null) 'from': range.isoFrom,
        if (range != null) 'to': range.isoTo,
        'total': total,
        'value_usd': value.round(),
        'by_status': {for (final e in counts.entries) e.key.name: e.value},
        // No customer names, emails or phones ever go to the model.
        'items': [
          for (final e in all.take(AccountTool.maxModelRows))
            {
              'id': e.order?.shortId ?? e.refund?.id,
              'product': e.order?.productSummary,
              'value_usd': e.valueUsd.round(),
              'date': AccountTool.shortDate(e.date),
            },
        ],
        'screen_opened': open,
      },
    );
  }

  static AgentListRow _row(SellerOrderBoardEntry e) {
    final order = e.order;
    final refund = e.refund;
    return AgentListRow(
      title: order == null
          ? 'Refund request'
          : '#${order.shortId} · ${order.productSummary}',
      subtitle: [
        e.customerName,
        AccountTool.shortDate(e.date),
        if (order != null) sellerOrderCategoryOf(order).label,
      ].where((s) => s.isNotEmpty).join(' · '),
      trailing: AppCurrency.usd(e.valueUsd, decimals: 0),
      imageUrl: order?.items.firstOrNull?.image,
      route: order != null
          ? AppRouteNames.sellerOrderDetailPath(order.id)
          : (refund != null ? AppRouteNames.sellerOrders : null),
    );
  }

  Future<Result<List<SellerOrder>, Failure>> _loadOrders(
    AgentToolContext context, {
    DateTime? since,
  }) async {
    final repo = context.ref.read(sellerOrderRepositoryProvider);
    final orders = <SellerOrder>[];
    final seen = <String>{};
    for (var page = 1; page <= _maxPages; page++) {
      final result = await repo.list(
        page: page,
        limit: _pageSize,
        cancelToken: context.cancelToken,
      );
      switch (result) {
        case ResultFailure(:final failure):
          if (orders.isEmpty) return ResultFailure(failure);
          return Success(orders);
        case Success(:final value):
          for (final order in value.orders) {
            if (seen.add(order.id)) orders.add(order);
          }
          final oldest = value.orders.lastOrNull?.createdAt;
          final pastWindow =
              since != null && oldest != null && oldest.isBefore(since);
          if (!value.hasMore || value.orders.isEmpty || pastWindow) {
            return Success(orders);
          }
      }
    }
    return Success(orders);
  }

  Future<Result<List<RefundRequest>, Failure>> _loadRefunds(
    AgentToolContext context,
  ) async {
    final result = await context.ref
        .read(refundRepositoryProvider)
        .listSeller(
          page: 1,
          limit: _pageSize,
          cancelToken: context.cancelToken,
        );
    return switch (result) {
      Success(:final value) => Success(value.items),
      ResultFailure(:final failure) => ResultFailure(failure),
    };
  }
}
