import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../buyer/domain/buyer_order_status.dart';
import '../../../buyer/domain/models/buyer_order.dart';
import '../../../payment/data/repositories/payment_repository_impl.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';
import '../account/agent_period.dart';

/// The user's own purchases: recent orders, what is in progress, refunded
/// or needs attention.
class MyOrdersTool extends AccountTool {
  const MyOrdersTool();

  static const _filters = {
    'in_progress': BuyerOrderFilter.active,
    'refunded': BuyerOrderFilter.refunded,
    'needs_attention': BuyerOrderFilter.issues,
  };

  @override
  String get name => 'my_orders';

  @override
  String get description =>
      'The user\'s own purchases (orders they placed): status, amounts, '
      'dates. Not orders a seller received — use seller_orders for that.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      ...AgentPeriod.schema(),
      'status': {
        'type': 'string',
        'enum': [..._filters.keys, 'any'],
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your orders…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final (period, range) = AgentPeriod.read(args, context.now);
    final filter = _filters[args['status']?.toString()] ?? BuyerOrderFilter.all;
    final result = await context.ref
        .read(paymentRepositoryProvider)
        .listOrders(page: 1, limit: 30, cancelToken: context.cancelToken);
    final List<BuyerOrder> orders;
    switch (result) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        orders = [
          for (final o in value.orders.map(buyerOrderFromPayment))
            if (filter.matches(buyerOrderStage(o)) &&
                (range == null || range.contains(o.createdAt)))
              o,
        ];
    }

    final when = period == AgentPeriod.allTime ? '' : ' ${period.label}';
    final word = filter == BuyerOrderFilter.all
        ? ''
        : '${filter.label.toLowerCase()} ';
    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;
    return ToolSuccess(
      summary: orders.isEmpty
          ? 'No ${word}orders$when.'
          : 'You have ${AccountTool.plural(orders.length, '${word}order')}'
                '$when. Latest: ${orders.first.productLabel} — '
                '${orders.first.displayStatus.toLowerCase()}.',
      completesTurn: true,
      effects: open
          ? const [OpenPageEffect(AppRouteNames.buyerOrders)]
          : const [],
      cards: [
        if (orders.isNotEmpty)
          AgentListCard(
            rows: [
              for (final o in orders.take(AccountTool.maxRows))
                AgentListRow(
                  title: o.productLabel,
                  subtitle: [
                    o.displayStatus,
                    AccountTool.shortDate(o.createdAt),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  trailing: _amount(o),
                  imageUrl: o.imageUrl,
                  route: AppRouteNames.buyerOrderDetailPath(o.id),
                ),
            ],
            moreCount: orders.length - AccountTool.maxRows,
            action: const AgentCardAction(
              'All orders',
              AppRouteNames.buyerOrders,
            ),
          ),
      ],
      data: {
        'total': orders.length,
        'orders': [
          for (final o in orders.take(AccountTool.maxModelRows))
            {
              'product': o.productLabel,
              'status': o.displayStatus,
              'amount': _amount(o),
              'date': AccountTool.shortDate(o.createdAt),
            },
        ],
      },
    );
  }

  static String _amount(BuyerOrder o) => o.amountInr > 0
      ? AppCurrency.inr(o.amountInr, decimals: 0)
      : AppCurrency.usd(o.amountUsd, decimals: 0);
}
