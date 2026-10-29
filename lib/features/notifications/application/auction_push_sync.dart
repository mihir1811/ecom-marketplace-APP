import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auction/application/auction_providers.dart';
import '../../cart/application/cart_provider.dart';
import '../domain/models/app_notification.dart';

/// Pushes that move an auction win into or out of the winner's cart, or
/// hand it back to the seller.
const _auctionWinEvents = {
  'AUCTION_WON',
  'AUCTION_WIN_UNPAID',
  'AUCTION_WINNER_UNPAID_SELLER',
};

/// Reloads the cart badge and the auction views a win push affects.
void syncAuctionViewsFromPush(Ref ref, AppNotification notification) {
  final type = notification.type.toUpperCase();
  if (!_auctionWinEvents.contains(type)) return;
  final auctionId = notification.data['auctionId'] ?? '';
  if (auctionId.isNotEmpty) ref.invalidate(auctionDetailProvider(auctionId));
  ref.invalidate(auctionFeedProvider);
  if (type == 'AUCTION_WINNER_UNPAID_SELLER') return;
  if (type == 'AUCTION_WIN_UNPAID') ref.invalidate(auctionPenaltyProvider);
  ref
      .read(cartProvider.notifier)
      .refresh(mode: CartLoadMode.light, force: true);
}
