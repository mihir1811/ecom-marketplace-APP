import '../../../../core/router/route_names.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../domain/agent_card.dart';
import '../../domain/agent_tool.dart';
import '../../domain/tool_result.dart';
import '../account/account_tool.dart';

/// Saved items. Goes through the wishlist notifier so on-device jewelry
/// favourites and server favourites are merged exactly like the screen.
class MyWishlistTool extends AccountTool {
  const MyWishlistTool();

  @override
  String get name => 'my_wishlist';

  @override
  String get description =>
      'Items the user saved to their wishlist / favourites.';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {},
    'additionalProperties': false,
  };

  @override
  String progressLabel(Map<String, Object?> args) => 'Checking your wishlist…';

  @override
  Future<ToolResult> execute(
    Map<String, Object?> args,
    AgentToolContext context,
  ) async {
    await context.ref.read(wishlistProvider.notifier).refresh();
    final state = context.ref.read(wishlistProvider);
    final error = state.errorMessage;
    if (error != null && state.items.isEmpty) return ToolFailure(error);
    final items = state.items;
    return ToolSuccess(
      summary: items.isEmpty
          ? 'Your wishlist is empty.'
          : 'You have ${AccountTool.plural(items.length, 'item')} in your wishlist.',
      completesTurn: true,
      cards: [
        if (items.isNotEmpty)
          AgentListCard(
            rows: [
              for (final i in items.take(AccountTool.maxRows))
                AgentListRow(
                  title: i.title,
                  subtitle: i.subtitle,
                  trailing: i.priceLabel,
                  imageUrl: i.imageUrl,
                  route: AppRouteNames.buyerWishlist,
                ),
            ],
            moreCount: items.length - AccountTool.maxRows,
            action: const AgentCardAction(
              'Open wishlist',
              AppRouteNames.buyerWishlist,
            ),
          ),
      ],
      data: {
        'total': items.length,
        'items': [
          for (final i in items.take(AccountTool.maxModelRows))
            {'title': i.title, 'type': i.category.name, 'price': i.priceLabel},
        ],
      },
    );
  }
}
