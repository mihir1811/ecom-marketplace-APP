import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/account_access.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/catalog/catalog_purchase_policy.dart';
import '../../../core/error/result.dart';
import '../../../core/router/route_names.dart';
import '../../cart/application/cart_provider.dart';
import '../../product_offer/application/product_offer_providers.dart';
import '../../product_offer/domain/models/product_offer.dart';
import '../domain/models/product_detail.dart';
import 'melee_qty_draft_provider.dart';

/// Outcome tone for purchase feedback.
enum PurchaseTone { success, warning, error }

/// Callback used by [ProductPurchaseActions] to surface feedback.
typedef PurchaseNotify = void Function(String message, PurchaseTone tone);

/// Messages shown by purchase flows; each UI supplies its own (localized)
/// wording while the rules stay in one place.
class PurchaseCopy {
  const PurchaseCopy({
    required this.signInToBuy,
    required this.selectJewelryOptions,
    required this.enterMeleeQty,
    required this.onlyCaratAvailable,
    required this.onlyPiecesAvailable,
    required this.addedToCart,
    required this.signInToOffer,
    required this.ownListingOffer,
    required this.offerSent,
    this.offerAddedToBag = 'Added to cart at your offer price',
  });

  final String signInToBuy;
  final String selectJewelryOptions;
  final String enterMeleeQty;
  final String Function(String carat) onlyCaratAvailable;
  final String Function(int pieces) onlyPiecesAvailable;
  final String addedToCart;
  final String signInToOffer;
  final String ownListingOffer;
  final String offerSent;
  final String offerAddedToBag;

  /// Original English copy of the shared detail action bar.
  static final english = PurchaseCopy(
    signInToBuy: 'Please sign in to add items to your cart',
    selectJewelryOptions: 'Select jewelry options before adding to cart',
    enterMeleeQty: 'Enter how many pieces or carats to add',
    onlyCaratAvailable: (ct) => 'Only $ct ct available',
    onlyPiecesAvailable: (pcs) => 'Only $pcs pcs available',
    addedToCart: 'Added to cart',
    signInToOffer: 'Please sign in to make an offer',
    ownListingOffer: 'You cannot make an offer on your own listing',
    offerSent: 'Offer submitted',
  );
}

/// What the primary purchase control should say.
enum CartButtonKind { add, viewInCart, ownListing, onHoldMemo, unavailable }

/// What the offer control should say, from the buyer's own offers on the
/// stone (same rules as the website).
enum OfferButtonKind {
  /// Make an offer is open.
  makeOffer,

  /// A pending offer is waiting for the seller.
  pending,

  /// Every attempt on the stone is used, any status.
  limitReached,

  /// An accepted offer is unpaid and inside its 24-hour window.
  payNow,

  /// The accepted offer was paid.
  paid,
}

/// Snapshot of everything the purchase controls need to render.
class PurchaseState {
  const PurchaseState({
    required this.kind,
    required this.enabled,
    required this.busy,
    required this.showOffer,
    required this.offerBusy,
    this.offerKind = OfferButtonKind.makeOffer,
    this.offerEligibility = ProductOfferEligibility.empty,
  });

  final CartButtonKind kind;
  final bool enabled;
  final bool busy;
  final bool showOffer;
  final bool offerBusy;
  final OfferButtonKind offerKind;
  final ProductOfferEligibility offerEligibility;

  /// Offer control is tappable (make an offer or pay now).
  bool get offerEnabled =>
      offerKind == OfferButtonKind.makeOffer ||
      offerKind == OfferButtonKind.payNow;
}

/// Add-to-cart and make-offer rules shared by every detail action bar:
/// sign-in, account access, own-listing and availability guards and
/// partial-melee quantities. Marketplace jewelry uses the jewellery bag
/// instead (see `LuxeJewelryPurchaseBar`).
abstract final class ProductPurchaseActions {
  static PurchaseState watchState(WidgetRef ref, ProductDetail detail) {
    final mutating = ref.watch(cartIsMutatingProvider);
    final inCart = ref.watch(isProductInCartProvider(detail.id));
    final offerBusy = ref.watch(productOfferMutationProvider).isLoading;
    final auth = ref.watch(authProvider);
    final own = detail.isOwnedByCurrentAccount(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    final block = detail.addToCartBlockMessage(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    final kind = own
        ? CartButtonKind.ownListing
        : block != null
        ? (CatalogPurchasePolicy.isOnHoldOrMemo(detail.availabilityStatus) ||
                  CatalogPurchasePolicy.isOnHoldOrMemo(
                    detail.availability?.label,
                  )
              ? CartButtonKind.onHoldMemo
              : CartButtonKind.unavailable)
        : inCart
        ? CartButtonKind.viewInCart
        : CartButtonKind.add;
    final showOffer = detail.canMakeAnOffer && !own;
    final eligibility = showOffer && auth.isAuthenticated
        ? ref
              .watch(productOfferEligibilityProvider(offerKey(detail)))
              .valueOrNull
        : null;
    final offers = eligibility ?? ProductOfferEligibility.empty;
    return PurchaseState(
      kind: kind,
      enabled: !own && detail.isPurchasable && !mutating,
      busy: mutating,
      showOffer: showOffer,
      offerBusy: offerBusy,
      offerKind: offers.payable != null
          ? OfferButtonKind.payNow
          : offers.paid != null
          ? OfferButtonKind.paid
          : offers.hasPending
          ? OfferButtonKind.pending
          : offers.limitReached
          ? OfferButtonKind.limitReached
          : OfferButtonKind.makeOffer,
      offerEligibility: offers,
    );
  }

  static OfferProductKey offerKey(ProductDetail detail) => (
    productType: detail.apiProductType,
    productId: detail.id,
    maxAttempts: detail.maxOfferAttemptsPerUser,
  );

  /// Offer control tap: pay for an accepted offer, or make a new one.
  static Future<void> offerAction(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail, {
    required PurchaseState state,
    required Future<({String amount, String? message})?> Function() ask,
    required PurchaseCopy copy,
    required PurchaseNotify notify,
  }) async {
    final payable = state.offerEligibility.payable;
    if (state.offerKind == OfferButtonKind.payNow && payable != null) {
      await payAcceptedOffer(context, ref, payable, copy: copy, notify: notify);
      return;
    }
    if (state.offerKind != OfferButtonKind.makeOffer) return;
    await makeOffer(context, ref, detail, ask: ask, copy: copy, notify: notify);
  }

  /// Adds the stone to the bag at the accepted offer price, then opens the
  /// bag for the usual delivery address and Razorpay checkout.
  static Future<void> payAcceptedOffer(
    BuildContext context,
    WidgetRef ref,
    ProductOffer offer, {
    required PurchaseCopy copy,
    required PurchaseNotify notify,
  }) async {
    if (!AccountAccess.guard(context, ref)) return;
    final result = await ref
        .read(productOfferMutationProvider.notifier)
        .addAcceptedOfferToBag(offer);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        notify(copy.offerAddedToBag, PurchaseTone.success);
        context.push(AppRouteNames.cart);
      case ResultFailure(:final failure):
        notify(failure.message, PurchaseTone.error);
    }
  }

  /// Primary action: opens the cart when already added, otherwise adds.
  static Future<void> primary(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail, {
    required PurchaseCopy copy,
    required PurchaseNotify notify,
  }) async {
    if (ref.read(isProductInCartProvider(detail.id))) {
      context.push(AppRouteNames.cart);
      return;
    }
    await addToCart(context, ref, detail, copy: copy, notify: notify);
  }

  static Future<void> addToCart(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail, {
    required PurchaseCopy copy,
    required PurchaseNotify notify,
  }) async {
    if (!ref.read(authProvider).isAuthenticated) {
      notify(copy.signInToBuy, PurchaseTone.warning);
      context.push(AppRouteNames.login);
      return;
    }
    if (!AccountAccess.guard(context, ref)) return;
    final auth = ref.read(authProvider);
    final blockMessage = detail.addToCartBlockMessage(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    );
    if (blockMessage != null) {
      notify(blockMessage, PurchaseTone.warning);
      return;
    }

    var quantity = 1;
    Map<String, dynamic>? specifications;
    final meleeQty = detail.naturalSpecTabs?.meleeQty;
    if (meleeQty != null) {
      ref
          .read(meleeQtyDraftProvider(detail.id).notifier)
          .ensureSeeded(meleeQty);
      final draft = ref.read(meleeQtyDraftProvider(detail.id));
      if (draft == null || (draft.pieces < 1 && draft.carat <= 0)) {
        notify(copy.enterMeleeQty, PurchaseTone.error);
        return;
      }
      if (draft.inCarat) {
        final maxCt = meleeQty.totalCarat;
        if (maxCt != null && draft.carat > maxCt + 1e-9) {
          notify(
            copy.onlyCaratAvailable(maxCt.toStringAsFixed(2)),
            PurchaseTone.warning,
          );
          return;
        }
      } else {
        final maxPcs = meleeQty.totalPcs;
        if (maxPcs != null && draft.pieces > maxPcs) {
          notify(copy.onlyPiecesAvailable(maxPcs), PurchaseTone.warning);
          return;
        }
      }
      // Partial melee amount lives in specifications; quantity is the line.
      quantity = 1;
      final calculated = draft.proportionalPrice(
        detail.price.displayAmount,
        meleeQty,
      );
      specifications = draft.toSpecifications(calculatedPrice: calculated);
    }

    final result = await ref
        .read(cartProvider.notifier)
        .addProduct(
          productId: detail.id,
          productType: detail.apiProductType,
          quantity: quantity,
          specifications: specifications,
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        notify(copy.addedToCart, PurchaseTone.success);
      case ResultFailure(:final failure):
        notify(failure.message, PurchaseTone.error);
    }
  }

  /// Validates access, asks for the offer via [ask], then submits it.
  static Future<void> makeOffer(
    BuildContext context,
    WidgetRef ref,
    ProductDetail detail, {
    required Future<({String amount, String? message})?> Function() ask,
    required PurchaseCopy copy,
    required PurchaseNotify notify,
  }) async {
    if (!ref.read(authProvider).isAuthenticated) {
      notify(copy.signInToOffer, PurchaseTone.warning);
      context.push(AppRouteNames.login);
      return;
    }
    if (!AccountAccess.guard(context, ref)) return;
    final auth = ref.read(authProvider);
    if (detail.isOwnedByCurrentAccount(
      userId: auth.user?.id,
      sellerId: auth.sellerId,
    )) {
      notify(copy.ownListingOffer, PurchaseTone.warning);
      return;
    }

    final offer = await ask();
    if (offer == null || !context.mounted) return;
    // The API takes a decimal string with up to two places, never a number.
    final parsed = double.tryParse(offer.amount.trim());
    if (parsed == null || parsed <= 0) return;
    final amount = parsed.toStringAsFixed(2);

    final result = await ref
        .read(productOfferMutationProvider.notifier)
        .create(
          productId: detail.id,
          productType: detail.apiProductType,
          amount: amount,
          message: offer.message,
        );
    if (!context.mounted) return;
    switch (result) {
      case Success():
        notify(copy.offerSent, PurchaseTone.success);
      case ResultFailure(:final failure):
        notify(failure.message, PurchaseTone.error);
    }
  }
}
