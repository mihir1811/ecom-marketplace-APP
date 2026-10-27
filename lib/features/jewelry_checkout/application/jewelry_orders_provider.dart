import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_checkout_repository_impl.dart';
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
