import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/cart_item.dart';
import '../domain/models/delivery_address.dart';

/// Cart totals derived from line items + fixed fee schedule (mock).
class CartTotals {
  const CartTotals({
    required this.subtotalInr,
    required this.subtotalUsd,
    required this.gstInr,
    required this.transactionFeeInr,
    required this.platformFeeInr,
    required this.totalInr,
  });

  final double subtotalInr;
  final double subtotalUsd;
  final double gstInr;
  final double transactionFeeInr;
  final double platformFeeInr;
  final double totalInr;

  @override
  bool operator ==(Object other) {
    return other is CartTotals &&
        other.subtotalInr == subtotalInr &&
        other.subtotalUsd == subtotalUsd &&
        other.gstInr == gstInr &&
        other.transactionFeeInr == transactionFeeInr &&
        other.platformFeeInr == platformFeeInr &&
        other.totalInr == totalInr;
  }

  @override
  int get hashCode => Object.hash(
        subtotalInr,
        subtotalUsd,
        gstInr,
        transactionFeeInr,
        platformFeeInr,
        totalInr,
      );
}

class CartState {
  const CartState({
    this.items = const [],
    this.address,
    this.promoCode,
    this.promoApplied = false,
  });

  final List<CartItem> items;
  final DeliveryAddress? address;
  final String? promoCode;
  final bool promoApplied;

  int get count => items.length;
  bool get isEmpty => items.isEmpty;
  bool get hasAddress => address != null;

  CartTotals get totals {
    final subInr = items.fold<double>(0, (s, i) => s + i.priceInr);
    final subUsd = items.fold<double>(0, (s, i) => s + i.priceUsd);
    final gst = subInr * 0.03;
    final txn = subInr * 0.02245;
    const platform = 100.0;
    var total = subInr + gst + txn + platform;
    if (promoApplied) total = (total * 0.95).clamp(0, double.infinity);
    return CartTotals(
      subtotalInr: subInr,
      subtotalUsd: subUsd,
      gstInr: gst,
      transactionFeeInr: txn,
      platformFeeInr: platform,
      totalInr: total,
    );
  }

  CartState copyWith({
    List<CartItem>? items,
    DeliveryAddress? address,
    String? promoCode,
    bool? promoApplied,
    bool clearAddress = false,
    bool clearPromo = false,
  }) {
    return CartState(
      items: items ?? this.items,
      address: clearAddress ? null : (address ?? this.address),
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      promoApplied: promoApplied ?? this.promoApplied,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState(
      items: [
        CartItem(
          id: 'cart-dm-1',
          title: '0.25ct pear',
          category: 'Diamond',
          priceUsd: 27.50,
          priceInr: 2648,
          shape: 'Pear',
        ),
        CartItem(
          id: 'cart-dm-2',
          title: '0.23ct marquise',
          category: 'Diamond',
          priceUsd: 25.30,
          priceInr: 2433,
          shape: 'Marquise',
        ),
      ],
    );
  }

  bool contains(String id) => state.items.any((e) => e.id == id);

  /// Adds [item] unless the same product is already in the cart.
  /// Returns `true` when the cart changed.
  bool addItem(CartItem item) {
    if (contains(item.id)) return false;
    state = state.copyWith(items: [...state.items, item]);
    return true;
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
    );
  }

  void setAddress(DeliveryAddress address) {
    state = state.copyWith(address: address);
  }

  void clearAddress() {
    state = state.copyWith(clearAddress: true);
  }

  /// Returns true when the mock promo is accepted.
  bool applyPromo(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      state = state.copyWith(promoApplied: false, clearPromo: true);
      return false;
    }
    final ok = normalized == 'GEM5' || normalized == 'SAVE5';
    state = state.copyWith(
      promoCode: normalized,
      promoApplied: ok,
    );
    return ok;
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((s) => s.count));
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.isEmpty));
});

final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartProvider.select((s) => s.items));
});

final cartAddressProvider = Provider<DeliveryAddress?>((ref) {
  return ref.watch(cartProvider.select((s) => s.address));
});

final cartHasAddressProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.hasAddress));
});

final cartPromoProvider = Provider<({String? code, bool applied})>((ref) {
  return ref.watch(
    cartProvider.select((s) => (code: s.promoCode, applied: s.promoApplied)),
  );
});

final cartTotalsProvider = Provider<CartTotals>((ref) {
  return ref.watch(cartProvider.select((s) => s.totals));
});
