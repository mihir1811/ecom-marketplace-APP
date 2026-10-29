import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../seller/application/seller_products_provider.dart';
import '../../../seller/data/repositories/seller_product_repository_impl.dart';
import '../../../seller/domain/models/seller_product.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_effect.dart';
import '../../domain/agent_session.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// The seller's own listings: how many are live, expired, on auction, sold,
/// natural vs melee, and look-ups by stock number or text.
class SellerInventoryTool extends AccountTool {
  const SellerInventoryTool();

  @override
  String get name => 'seller_inventory';

  @override
  AgentToolAccess get access => AgentToolAccess.seller;

  @override
  String get description =>
      'Seller only: the user\'s own product listings (natural and melee '
      'diamonds) — counts by status, or find listings by stock number / '
      'shape / text. Opens Products when asked.';

  @override
  Map<String, Object?> get parameters => {
    'type': 'object',
    'properties': {
      'kind': {
        'type': 'string',
        'enum': ['natural', 'melee', 'any'],
      },
      'status': {
        'type': 'string',
        'enum': ['active', 'expired', 'on_auction', 'sold', 'any'],
      },
      'search': {
        'type': 'string',
        'description': 'Stock number or words the user gave ("oval", "GIA").',
      },
      'mode': AnswerMode.schema,
    },
    'additionalProperties': false,
  };

  @override
  String get promptGuidance => '''
"how many products do I have", "my listings", "expired stones", "is stock 1234 live" → seller_inventory. A stock number goes in search.''';

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your listings…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final auth = context.ref.read(authProvider);
    final sellerId = auth.sellerId ?? auth.user?.id;
    if (sellerId == null || sellerId.isEmpty) {
      return const ToolFailure(
        'Seller account not found. Please sign in again.',
      );
    }
    final result = await context.ref
        .read(sellerProductRepositoryProvider)
        .listProducts(sellerId: sellerId, cancelToken: context.cancelToken);
    final List<SellerProduct> products;
    switch (result) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        products = value.where((p) => !p.isDeleted).toList();
    }

    final kind = args['kind']?.toString();
    final status = args['status']?.toString();
    final search = (args['search'] as String?)?.trim() ?? '';
    bool kindOk(SellerProduct p) => switch (kind) {
      'natural' => p.isNatural,
      'melee' => !p.isNatural,
      _ => true,
    };
    bool statusOk(SellerProduct p) => switch (status) {
      'active' => !p.isExpired && !p.isSold,
      'expired' => p.isExpired,
      'on_auction' => p.isOnAuction,
      'sold' => p.isSold,
      _ => true,
    };
    final matches = [
      for (final p in products)
        if (kindOk(p) && statusOk(p) && p.matchesSearch(search)) p,
    ];

    int count(bool Function(SellerProduct) test) => products.where(test).length;
    final live = count((p) => !p.isExpired && !p.isSold);
    final filtered =
        kind != null && kind != 'any' ||
        status != null && status != 'any' ||
        search.isNotEmpty;
    final label = [
      if (status != null && status != 'any') status.replaceAll('_', ' '),
      if (kind != null && kind != 'any') kind,
      'listing',
    ].join(' ');
    final summary = filtered
        ? (matches.isEmpty
              ? 'No ${label}s${search.isEmpty ? '' : ' matching "$search"'}.'
              : '${AccountTool.plural(matches.length, label)}'
                    '${search.isEmpty ? '' : ' matching "$search"'}.')
        : 'You have ${AccountTool.plural(products.length, 'listing')}: '
              '$live live, ${count((p) => p.isExpired)} expired, '
              '${count((p) => p.isOnAuction)} on auction.';

    final open = AnswerMode.parse(args['mode']) == AnswerMode.open;
    return ToolSuccess(
      summary: summary,
      completesTurn: true,
      effects: open
          ? [
              _OpenProducts(
                melee: kind == 'melee',
                status: switch (status) {
                  'expired' => SellerProductStatusFilter.expired,
                  'active' => SellerProductStatusFilter.active,
                  _ => SellerProductStatusFilter.all,
                },
                search: search,
              ),
            ]
          : const [],
      cards: [
        if (!filtered)
          AgentStatsCard(
            stats: [
              AgentStat('Live', '$live'),
              AgentStat('Natural', '${count((p) => p.isNatural)}'),
              AgentStat('Melee', '${count((p) => !p.isNatural)}'),
              AgentStat('On auction', '${count((p) => p.isOnAuction)}'),
              AgentStat('Expired', '${count((p) => p.isExpired)}'),
              AgentStat('Sold', '${count((p) => p.isSold)}'),
            ],
            action: const AgentCardAction(
              'Open Products',
              AppRouteNames.sellerProducts,
            ),
          ),
        if (filtered && matches.isNotEmpty)
          AgentListCard(
            rows: [
              for (final p in matches.take(AccountTool.maxRows))
                AgentListRow(
                  title: _title(p),
                  subtitle: _state(p),
                  trailing: _price(p),
                  route: AppRouteNames.sellerProductEditPath(p.id),
                ),
            ],
            moreCount: matches.length - AccountTool.maxRows,
            action: const AgentCardAction(
              'Open Products',
              AppRouteNames.sellerProducts,
            ),
          ),
      ],
      data: {
        'total_listings': products.length,
        'live': live,
        'matches': matches.length,
        'items': [
          for (final p in matches.take(AccountTool.maxModelRows))
            {'stock': p.stockNumber, 'title': _title(p), 'state': _state(p)},
        ],
      },
    );
  }

  static String _title(SellerProduct p) {
    final parts = [
      p.field('carat_weight'),
      p.field('shape'),
      p.field('color'),
      p.field('clarity'),
    ].whereType<String>().where((s) => s.trim().isNotEmpty);
    final spec = parts.join(' ');
    return spec.isEmpty ? 'Stock ${p.stockNumber}' : '${p.stockNumber} · $spec';
  }

  static String _state(SellerProduct p) => p.isSold
      ? 'Sold'
      : p.isOnAuction
      ? 'On auction'
      : p.isExpired
      ? 'Expired'
      : (p.isNatural ? 'Live · natural' : 'Live · melee');

  static String? _price(SellerProduct p) {
    final total = p.field('total_price')?.trim();
    if (total == null || total.isEmpty) return null;
    return total.startsWith('\$') ? total : '\$$total';
  }
}

/// Sets the Products screen's tab, status and search, then opens it.
class _OpenProducts extends AgentEffect {
  const _OpenProducts({
    required this.melee,
    required this.status,
    required this.search,
  });

  final bool melee;
  final SellerProductStatusFilter status;
  final String search;

  @override
  Future<void> apply(Ref ref) async {
    ref.read(sellerProductsControllerProvider.notifier)
      ..setTab(
        melee ? SellerProductDiamondTab.melee : SellerProductDiamondTab.natural,
      )
      ..setStatusFilter(status)
      ..setSearchQuery(search);
    await const OpenPageEffect(AppRouteNames.sellerProducts).apply(ref);
  }
}
