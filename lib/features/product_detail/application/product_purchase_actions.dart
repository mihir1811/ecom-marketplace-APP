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
import '../domain/models/product_detail.dart';
import 'jewelry_config_draft_provider.dart';
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

/// Snapshot of everything the purchase controls need to render.
class PurchaseState {
  const PurchaseState({
    required this.kind,
    required this.enabled,
    required this.busy,
    required this.showOffer,
    required this.offerBusy,
  });

  final CartButtonKind kind;
  final bool enabled;
  final bool busy;
  final bool showOffer;
  final bool offerBusy;
}

/// Add-to-cart and make-offer rules shared by every detail action bar:
/// sign-in, account access, own-listing and availability guards, jewelry
/// configuration and partial-melee quantities.
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
    return PurchaseState(
      kind: kind,
      enabled: !own && detail.isPurchasable && !mutating,
      busy: mutating,
      showOffer: detail.canMakeAnOffer && !own,
      offerBusy: offerBusy,
    );
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
    final jewelryDetail = detail.jewelryDetail;
    if (jewelryDetail != null) {
      ref
          .read(jewelryConfigDraftProvider(detail.id).notifier)
          .ensureSeeded(jewelryDetail);
      final draft = ref.read(jewelryConfigDraftProvider(detail.id));
      if (draft == null) {
        notify(copy.selectJewelryOptions, PurchaseTone.error);
        return;
      }
      quantity = draft.quantity;
      specifications = draft.toCartSpecifications();
    }
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
    final raw = offer.amount.trim();
    if (raw.isEmpty) return;
    final amount = raw.contains('.') ? raw : '$raw.00';

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
