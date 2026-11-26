import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../interested_buyers/application/interested_buyers_providers.dart';
import '../../product_offer/application/product_offer_providers.dart';
import '../domain/models/app_notification.dart';

/// True for `OFFER_RECEIVED`, `OFFER_ACCEPTED`, `OFFER_REJECTED`, the
/// `PRIVATE_OFFER_*` pushes and any other push about an offer
/// (`entityType: "OFFER"`).
bool isOfferEvent(AppNotification notification) {
  final type = notification.type.toUpperCase();
  return type.startsWith('OFFER_') ||
      type.startsWith('PRIVATE_OFFER_') ||
      notification.data['entityType'] == 'OFFER';
}

/// Reloads the offer views a push affects: the buyer's offers and the
/// product page rules for buyers, offers received for sellers.
void syncOfferViewsFromPush(Ref ref, AppNotification notification) {
  if (!isOfferEvent(notification)) return;
  ref.invalidate(productOfferEligibilityProvider);
  if (ref.exists(buyerOfferListProvider)) {
    ref
        .read(buyerOfferListProvider.notifier)
        .refresh(statusFilter: ref.read(buyerOfferListProvider).statusFilter);
  }
  if (ref.exists(sellerOfferListProvider)) {
    ref
        .read(sellerOfferListProvider.notifier)
        .refresh(statusFilter: ref.read(sellerOfferListProvider).statusFilter);
  }
  // An accepted or declined private offer changes the row's open offer.
  if (ref.exists(interestedBuyersProvider)) {
    ref.read(interestedBuyersProvider.notifier).refresh();
  }
}
