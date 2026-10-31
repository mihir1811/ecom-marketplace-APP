import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_checkout_repository_impl.dart';
import '../domain/models/marketplace_invoice.dart';
import '../domain/models/marketplace_order.dart';

/// The buyer's jewellery orders, newest first (up to 50).
final jewelryOrdersProvider =
    FutureProvider.autoDispose<List<MarketplaceOrder>>((ref) async {
      final result = await ref.read(jewelryCheckoutRepositoryProvider).orders();
      return switch (result) {
        Success(value: final orders) => orders,
        ResultFailure(failure: final failure) => throw failure,
      };
    });

/// One order, read fresh (it also settles pending payments and refunds).
final jewelryOrderProvider = FutureProvider.autoDispose
    .family<MarketplaceOrder, String>((ref, orderId) async {
      final result = await ref
          .read(jewelryCheckoutRepositoryProvider)
          .order(orderId);
      return switch (result) {
        Success(value: final order) => order,
        ResultFailure(failure: final failure) => throw failure,
      };
    });

/// GemWorld's tax invoice for a paid order. It never changes once issued.
final jewelryInvoiceProvider = FutureProvider.autoDispose
    .family<MarketplaceInvoice, String>((ref, orderId) async {
      final result = await ref
          .read(jewelryCheckoutRepositoryProvider)
          .invoice(orderId);
      switch (result) {
        case Success(value: final invoice):
          ref.keepAlive();
          return invoice;
        case ResultFailure(failure: final failure):
          throw failure;
      }
    });

/// A level of the address picker: countries (`country` null), states of a
/// country, or cities of a state.
typedef JewelryLocationQuery = ({String? country, String? state});

/// Storefront location lists for checkout; empty when they can't be read,
/// so the form falls back to typed fields.
final jewelryLocationsProvider = FutureProvider.autoDispose
    .family<List<({String code, String name})>, JewelryLocationQuery>((
      ref,
      q,
    ) async {
      final result = await ref
          .read(jewelryCheckoutRepositoryProvider)
          .locations(country: q.country, state: q.state);
      switch (result) {
        case Success(value: final items):
          // The lists rarely change: keep them for the session.
          if (items.isNotEmpty) ref.keepAlive();
          return items;
        case ResultFailure():
          return const [];
      }
    });
