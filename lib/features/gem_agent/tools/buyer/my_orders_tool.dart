import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../buyer/application/buyer_orders_provider.dart';
import '../../../buyer/domain/buyer_order_status.dart';
import '../../../buyer/domain/models/buyer_order.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../jewelry_checkout/data/repositories/jewelry_checkout_repository_impl.dart';
import '../../../jewelry_checkout/domain/models/marketplace_order.dart';
import '../../../payment/data/repositories/payment_repository_impl.dart';
import '../../../payment/domain/models/payment_models.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';
import '../account/agent_period.dart';

/// The user's own purchases: recent orders, what is in progress, refunded
/// or needs attention.
///
/// A buyer's orders live in two places: catalog purchases (diamonds,
/// gemstones, watches, bullion, live-show wins) under `/payment`, and
/// jewellery marketplace orders under `/marketplace` (the Jewelry orders
/// screen). Both are read and merged, newest first, so no purchase is
/// ever missed.
class MyOrdersTool extends AccountTool {
  const MyOrdersTool();

  static const _statuses = ['in_progress', 'refunded', 'needs_attention'];
  static const _kinds = ['jewelry', 'diamond', 'gemstone', 'watch', 'bullion'];

  @override
  String get name => 'my_orders';

  @override
  String get description =>
      'The user\'s own purchases (orders they placed as a buyer), including '
      'jewelry orders: status, delivery progress, amounts, dates. Not orders '
      'a seller received — use seller_orders for that.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      ...AgentPeriod.schema(),
      'status': {
        'type': 'string',
        'enum': [..._statuses, 'any'],
      },
      'kind': {
        'type': 'string',
        'enum': [..._kinds, 'any'],
        'description': 'Product type the user named ("my jewelry order").',
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
"status of my order / my recent jewelry order / where is my ring" → my_orders (kind "jewelry" when they said jewelry or a piece type). The first order in the result is the most recent.''';

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your orders…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final (period, range) = AgentPeriod.read(args, context.now);
    final status = _statuses.contains(args['status']) ? args['status'] : null;
    final kind = _kinds.contains(args['kind']) ? args['kind'] as String : null;

    // Both sources at once; a failure of one still shows the other. Catalog
    // orders are always read: jewellery can also be bought there.
    final catalogFuture = context.ref
        .read(paymentRepositoryProvider)
        .listOrders(page: 1, limit: 30, cancelToken: context.cancelToken);
    final jewelryFuture = kind == null || kind == 'jewelry'
        ? context.ref.read(jewelryCheckoutRepositoryProvider).orders()
        : null;
    final catalog = await catalogFuture;
    final jewelry = await jewelryFuture;
    if (context.cancelToken.isCancelled) return const ToolFailure('Cancelled.');

    final rows = <_OrderRow>[];
    Failure? failed;
    switch (catalog) {
      case Success(:final value):
        for (final o in value.orders) {
          if (kind != null && !_isKind(o, kind)) continue;
          rows.add(_OrderRow.catalog(o));
        }
      case ResultFailure(:final failure):
        failed = failure;
    }
    switch (jewelry) {
      case Success(:final value):
        rows.addAll(value.map(_OrderRow.jewelry));
      case ResultFailure(:final failure):
        failed ??= failure;
      case null:
        break;
    }
    // Nothing could be read at all: say so instead of "no orders".
    final readAny = catalog is Success || jewelry is Success;
    if (!readAny && failed != null) return AccountTool.failureOf(failed);

    final orders =
        [
          for (final r in rows)
            if ((status == null || r.matches(status)) &&
                (range == null || range.contains(r.createdAt)))
              r,
        ]..sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );

    final when = period == AgentPeriod.allTime ? '' : ' ${period.label}';
    final word = [if (status != null) _statusWord(status), ?kind].join(' ');
    final noun = word.isEmpty ? 'order' : '$word order';
    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;
    final allJewelry = orders.isNotEmpty && orders.every((r) => r.isJewelry);
    final listRoute = allJewelry || kind == 'jewelry'
        ? AppRouteNames.jewelryOrders
        : AppRouteNames.buyerOrders;
    final latest = orders.firstOrNull;
    return ToolSuccess(
      summary: latest == null
          ? 'No ${noun}s$when.'
          : 'You have ${AccountTool.plural(orders.length, noun)}$when. '
                'Latest: ${latest.title} — ${latest.status.toLowerCase()}'
                '${latest.delivery.isEmpty ? '' : ' (${latest.delivery})'}.',
      completesTurn: true,
      effects: open ? [OpenPageEffect(listRoute)] : const [],
      cards: [
        if (orders.isNotEmpty)
          AgentListCard(
            rows: [
              for (final o in orders.take(AccountTool.maxRows))
                AgentListRow(
                  title: o.title,
                  subtitle: [
                    o.status,
                    AccountTool.shortDate(o.createdAt),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  trailing: o.amount,
                  imageUrl: o.imageUrl,
                  route: o.route,
                ),
            ],
            moreCount: orders.length - AccountTool.maxRows,
            action: AgentCardAction('All orders', listRoute),
          ),
      ],
      data: {
        'total': orders.length,
        if (failed != null) 'note': 'Some orders could not be loaded.',
        'orders': [
          for (final o in orders.take(AccountTool.maxModelRows))
            {
              'product': o.title,
              'type': o.isJewelry ? 'jewelry' : o.typeLabel,
              if (o.number != null) 'order_number': o.number,
              'status': o.status,
              if (o.delivery.isNotEmpty) 'delivery': o.delivery,
              'amount': o.amount,
              'date': AccountTool.shortDate(o.createdAt),
            },
        ],
      },
    );
  }

  static String _statusWord(Object status) => switch (status) {
    'in_progress' => 'in-progress',
    'needs_attention' => 'needing-attention',
    _ => status.toString(),
  };

  static bool _isKind(PaymentOrder o, String kind) => o.items.any((i) {
    final type = i.productType.toLowerCase();
    return switch (kind) {
      'jewelry' =>
        type.startsWith('jewel') || type.contains('marketplacejewel'),
      'diamond' => type.contains('diamond'),
      _ => type == kind,
    };
  });
}

/// One purchase from either source, in the shape the agent shows.
class _OrderRow {
  const _OrderRow({
    required this.title,
    required this.status,
    required this.stage,
    required this.amount,
    required this.route,
    required this.isJewelry,
    this.typeLabel = '',
    this.number,
    this.createdAt,
    this.imageUrl,
    this.delivery = '',
  });

  factory _OrderRow.catalog(PaymentOrder order) {
    final BuyerOrder o = buyerOrderFromPayment(order);
    final type = order.items.firstOrNull?.productType ?? '';
    return _OrderRow(
      title: o.productLabel,
      status: o.displayStatus,
      stage: switch (buyerOrderStage(o)) {
        BuyerOrderStage.refunded => 'refunded',
        BuyerOrderStage.issue => 'needs_attention',
        final s when BuyerOrderFilter.active.matches(s) => 'in_progress',
        _ => '',
      },
      amount: o.amountInr > 0
          ? AppCurrency.inr(o.amountInr, decimals: 0)
          : AppCurrency.usd(o.amountUsd, decimals: 0),
      route: AppRouteNames.buyerOrderDetailPath(o.id),
      isJewelry: type.toLowerCase().startsWith('jewel'),
      typeLabel: type.isEmpty ? '' : CartProductType.label(type).toLowerCase(),
      createdAt: o.createdAt,
      imageUrl: o.imageUrl,
    );
  }

  factory _OrderRow.jewelry(MarketplaceOrder order) {
    final shipment = order.shipments.firstOrNull;
    final status = switch (order.status) {
      MarketplaceOrderStatus.pendingPayment => 'Awaiting payment',
      MarketplaceOrderStatus.cancelled => 'Cancelled',
      MarketplaceOrderStatus.failed => 'Payment failed',
      _ => shipment == null ? 'Order placed' : jewelryStepText(shipment.status),
    };
    final stage = switch (order.status) {
      MarketplaceOrderStatus.pendingPayment ||
      MarketplaceOrderStatus.failed => 'needs_attention',
      MarketplaceOrderStatus.cancelled =>
        order.refundedTotal > 0 ? 'refunded' : '',
      _ when order.refundedTotal > 0 && order.refundedTotal >= order.total =>
        'refunded',
      _ when shipment?.status == MarketplaceStepStatus.delivered => '',
      _ => 'in_progress',
    };
    final pieces = order.items
        .map((i) => i.title.trim())
        .where((t) => t.isNotEmpty);
    final title = pieces.isEmpty
        ? 'Jewelry order ${order.orderNumber}'
        : pieces.length == 1
        ? pieces.first
        : '${pieces.first} +${pieces.length - 1} more';
    return _OrderRow(
      title: title,
      status: status,
      stage: stage,
      amount: AppCurrency.inr(order.total, decimals: 0),
      route: AppRouteNames.jewelryOrderDetailPath(order.id),
      isJewelry: true,
      number: order.orderNumber,
      createdAt: order.createdAt ?? order.paidAt,
      imageUrl: order.coverImageUrl,
      delivery: shipment == null
          ? ''
          : [
              if (shipment.courierName?.trim().isNotEmpty ?? false)
                'via ${shipment.courierName!.trim()}',
              if (shipment.expectedDeliveryAt?.trim().isNotEmpty ?? false)
                'expected ${shipment.expectedDeliveryAt!.trim()}',
            ].join(', '),
    );
  }

  final String title;
  final String status;

  /// `in_progress`, `refunded`, `needs_attention` or '' (done / other).
  final String stage;
  final String amount;
  final String route;
  final bool isJewelry;
  final String typeLabel;
  final String? number;
  final DateTime? createdAt;
  final String? imageUrl;
  final String delivery;

  bool matches(Object status) => stage == status;
}

/// English wording of a jewellery piece / shipment step (the agent's
/// summaries are English; the model translates for the user).
String jewelryStepText(String status) => switch (status) {
  MarketplaceStepStatus.accepted => 'Order confirmed',
  MarketplaceStepStatus.inProduction => 'Being made',
  MarketplaceStepStatus.qualityCheck => 'Quality check',
  MarketplaceStepStatus.readyToShip => 'Packed',
  MarketplaceStepStatus.shipped => 'Shipped',
  MarketplaceStepStatus.outForDelivery => 'Out for delivery',
  MarketplaceStepStatus.delivered => 'Delivered',
  MarketplaceStepStatus.cancelled => 'Cancelled',
  _ => 'Order placed',
};
