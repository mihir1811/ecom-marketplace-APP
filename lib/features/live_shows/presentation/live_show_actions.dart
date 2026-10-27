import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/router/app_navigation.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/luxe/luxe_feedback.dart';
import '../../cart/data/repositories/delivery_repository_impl.dart';
import '../../cart/domain/models/delivery_address.dart';
import '../../cart/presentation/widgets/delivery_address_sheet.dart';
import '../../product_detail/application/catalog_product_detail_loader.dart';
import '../../product_detail/product_detail_navigation.dart';
import '../../wallet/application/wallet_top_up_provider.dart';
import '../../wallet/presentation/widgets/wallet/wallet_top_up_sheet.dart';
import '../application/live_show_room.dart';
import '../domain/models/live_show_models.dart';
import 'widgets/live_address_sheet.dart';

/// Where wins ship: the checkout-selected address, else default, else newest.
final liveShipToProvider = FutureProvider.autoDispose<DeliveryAddress?>((
  ref,
) async {
  final result = await ref.read(deliveryRepositoryProvider).getCartDelivery();
  if (result is! Success<CartDeliveryState, Failure>) return null;
  final state = result.value;
  if (state.selectedAddress != null) return state.selectedAddress;
  final all = state.addresses;
  if (all.isEmpty) return null;
  return all.firstWhere((a) => a.isDefault, orElse: () => all.last);
});

/// Wallet top-up over the video, prefilled with [shortfall] rounded up.
Future<void> openLiveTopUp(
  BuildContext context,
  WidgetRef ref,
  String showId, {
  double? shortfall,
}) async {
  const max = WalletTopUpNotifier.maxAmountInr;
  final amount = shortfall == null || shortfall <= 0
      ? null
      : shortfall.ceilToDouble().clamp(WalletTopUpNotifier.minAmountInr, max);
  if (shortfall != null && shortfall > max) {
    showLuxeToast(
      context,
      'You need ${shortfall.ceil()} more. Top-ups go up to 1,00,000 at a '
      'time, so add it in two steps.',
      tone: LuxeTone.info,
      duration: const Duration(seconds: 4),
    );
  }
  await WalletTopUpSheet.show(context, initialAmount: amount);
  await ref.read(liveShowRoomProvider(showId).notifier).refreshMe();
}

/// Pick or add the address wins ship to, without leaving the show.
Future<void> openLiveAddress(
  BuildContext context,
  WidgetRef ref,
  String showId,
) async {
  final repo = ref.read(deliveryRepositoryProvider);
  final cart = await repo.getCartDelivery();
  if (!context.mounted) return;
  final addresses = switch (cart) {
    Success(:final value) => value.addresses,
    ResultFailure() => const <DeliveryAddress>[],
  };
  final selectedId = switch (cart) {
    Success(:final value) => value.selectedAddress?.id,
    ResultFailure() => null,
  };

  DeliveryAddress? chosen;
  if (addresses.isEmpty) {
    chosen = await _addAddress(context, ref);
  } else {
    final pick = await showLiveAddressPicker(
      context,
      addresses: addresses,
      selectedId: selectedId,
    );
    if (!context.mounted || pick == null) return;
    chosen = pick.addNew ? await _addAddress(context, ref) : pick.address;
  }
  if (chosen?.id == null || !context.mounted) return;
  final selected = await repo.selectAddress(addressId: chosen!.id!);
  if (!context.mounted) return;
  if (selected case ResultFailure(:final failure)) {
    showLuxeToast(context, failure.message, tone: LuxeTone.error);
    return;
  }
  showLuxeToast(context, 'Wins will ship to ${chosen.city}.');
  ref.invalidate(liveShipToProvider);
  await ref.read(liveShowRoomProvider(showId).notifier).refreshMe();
}

Future<DeliveryAddress?> _addAddress(
  BuildContext context,
  WidgetRef ref,
) async {
  final draft = await showDeliveryAddressSheet(context);
  if (draft == null || !context.mounted) return null;
  final created = await ref
      .read(deliveryRepositoryProvider)
      .createAddress(draft);
  if (!context.mounted) return null;
  switch (created) {
    case Success(:final value):
      return value;
    case ResultFailure(:final failure):
      showLuxeToast(context, failure.message, tone: LuxeTone.error);
      return null;
  }
}

/// Opens the app's own product screen for a lot.
Future<void> openLiveLot(
  BuildContext context,
  WidgetRef ref,
  LiveAuctionLot lot,
) async {
  if (lot.productId.isEmpty) return;
  if (openRememberedProductDetail(context, lot.productId)) return;
  final detail = await CatalogProductDetailLoader.load(
    ref.read,
    productType: lot.productType,
    productId: lot.productId,
  );
  if (!context.mounted) return;
  if (detail == null) {
    showLuxeToast(context, 'This item could not be opened right now.');
    return;
  }
  openProductDetail(context, detail);
}

void openLiveOrder(BuildContext context, String orderId) {
  if (orderId.isEmpty) return;
  context.openRoute(AppRouteNames.buyerOrderDetailPath(orderId));
}

void openLiveSignIn(BuildContext context) =>
    context.openRoute(AppRouteNames.login);
