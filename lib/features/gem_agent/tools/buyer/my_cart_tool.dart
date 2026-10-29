import '../../../../core/error/result.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../cart/data/mappers/cart_mapper.dart';
import '../../../cart/data/repositories/cart_repository_impl.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../../jewelry_checkout/application/jewelry_bag_provider.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// What is in the user's cart (stones, watches, bullion) and jewelry bag.
/// Answers in the sheet with item cards and a link; never navigates on its
/// own — "is anything in my cart?" is not worth leaving the page for.
class MyCartTool extends AccountTool {
  const MyCartTool();

  @override
  String get name => 'my_cart';

  @override
  String get description =>
      'What is in the user\'s cart and jewelry bag: items, prices, total. '
      'Read-only; cannot add, remove or check out.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {},
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your cart…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    final result = await context.ref
        .read(cartRepositoryProvider)
        .getSummary(cancelToken: context.cancelToken);
    final List<CartItem> items;
    switch (result) {
      case ResultFailure(:final failure):
        return AccountTool.failureOf(failure);
      case Success(:final value):
        items = CartMapper.itemsFromSummary(value);
    }
    // The jewelry bag lives on the device; wait for it to load from disk.
    await context.ref.read(jewelryBagProvider.notifier).ready;
    final bag = context.ref.read(jewelryBagProvider);

    final available = items.where((i) => i.isAvailable).toList();
    final cartTotal = available.fold<double>(
      0,
      (sum, i) => sum + i.displayPriceUsd,
    );
    final bagTotal = bag.fold<double>(
      0,
      (sum, l) => sum + (l.unitPrice ?? 0) * l.quantity,
    );
    final bagCount = bag.fold<int>(0, (sum, l) => sum + l.quantity);

    final parts = [
      if (items.isNotEmpty)
        '${AccountTool.plural(items.length, 'item')} in your cart '
            '(${AppCurrency.usd(cartTotal, decimals: 0)})',
      if (bag.isNotEmpty)
        '${AccountTool.plural(bagCount, 'piece')} in your jewelry bag'
            '${bagTotal > 0 ? ' (${AppCurrency.inr(bagTotal, decimals: 0)})' : ''}',
    ];
    final unavailable = items.length - available.length;
    final summary = parts.isEmpty
        ? 'Your cart and jewelry bag are empty.'
        : '${parts.join(' and ')}.'
              '${unavailable > 0 ? ' $unavailable no longer available.' : ''}';

    return ToolSuccess(
      summary: summary,
      completesTurn: true,
      cards: [
        if (items.isNotEmpty)
          AgentListCard(
            title: 'Cart',
            rows: [
              for (final i in items.take(AccountTool.maxRows))
                AgentListRow(
                  title: i.title,
                  subtitle: [
                    i.category,
                    if (i.quantity > 1) '× ${i.quantity}',
                    if (!i.isAvailable) i.availabilityLabel ?? 'Unavailable',
                  ].join(' · '),
                  trailing: AppCurrency.usd(i.displayPriceUsd, decimals: 0),
                  imageUrl: i.imageUrl,
                  route: AppRouteNames.cart,
                ),
            ],
            moreCount: items.length - AccountTool.maxRows,
            action: const AgentCardAction('Go to cart', AppRouteNames.cart),
          ),
        if (bag.isNotEmpty)
          AgentListCard(
            title: 'Jewelry bag',
            rows: [
              for (final l in bag.take(AccountTool.maxRows))
                AgentListRow(
                  title: l.title,
                  subtitle: [
                    ?l.shopName,
                    if (l.quantity > 1) '× ${l.quantity}',
                  ].join(' · '),
                  trailing: l.unitPrice == null
                      ? null
                      : AppCurrency.inr(l.unitPrice! * l.quantity, decimals: 0),
                  imageUrl: l.imageUrl,
                  route: AppRouteNames.jewelryBag,
                ),
            ],
            moreCount: bag.length - AccountTool.maxRows,
            action: const AgentCardAction(
              'Go to jewelry bag',
              AppRouteNames.jewelryBag,
            ),
          ),
      ],
      data: {
        'cart_items': items.length,
        'cart_total_usd': cartTotal.round(),
        'jewelry_bag_pieces': bagCount,
        'jewelry_bag_total_inr': bagTotal.round(),
        'items': [
          for (final i in items.take(AccountTool.maxModelRows))
            {
              'title': i.title,
              'price_usd': i.displayPriceUsd.round(),
              'available': i.isAvailable,
            },
          for (final l in bag.take(AccountTool.maxModelRows))
            {'title': l.title, 'price_inr': ?l.unitPrice?.round()},
        ],
      },
    );
  }
}
