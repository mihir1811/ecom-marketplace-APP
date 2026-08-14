import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/account_access.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/mappers/cart_mapper.dart';
import '../data/repositories/cart_repository_impl.dart';
import '../data/repositories/delivery_repository_impl.dart';
import '../domain/models/cart_item.dart';
import '../domain/models/cart_summary.dart';
import '../domain/models/delivery_address.dart';
import '../domain/repositories/cart_repository.dart';
import '../domain/repositories/delivery_repository.dart';

/// Display totals derived from cart summary + optional FX rate.
class CartTotals {
  const CartTotals({
    required this.subtotalUsd,
    required this.discountedSubtotalUsd,
    required this.totalDiscountUsd,
    required this.promoDiscountUsd,
    required this.automaticDiscountUsd,
    this.estimatedTotalInr,
    this.exchangeRate,
  });

  final double subtotalUsd;
  final double discountedSubtotalUsd;
  final double totalDiscountUsd;
  final double promoDiscountUsd;
  final double automaticDiscountUsd;
  final double? estimatedTotalInr;
  final double? exchangeRate;

  static const empty = CartTotals(
    subtotalUsd: 0,
    discountedSubtotalUsd: 0,
    totalDiscountUsd: 0,
    promoDiscountUsd: 0,
    automaticDiscountUsd: 0,
  );

  factory CartTotals.fromSummary(CartSummary summary, {double? rate}) {
    final usd = summary.discountedSubtotal;
    return CartTotals(
      subtotalUsd: summary.subtotal,
      discountedSubtotalUsd: usd,
      totalDiscountUsd: summary.totalDiscount,
      promoDiscountUsd: summary.promoDiscountTotal,
      automaticDiscountUsd: summary.automaticDiscountTotal,
      exchangeRate: rate,
      estimatedTotalInr: rate == null ? null : usd * rate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CartTotals &&
        other.subtotalUsd == subtotalUsd &&
        other.discountedSubtotalUsd == discountedSubtotalUsd &&
        other.totalDiscountUsd == totalDiscountUsd &&
        other.promoDiscountUsd == promoDiscountUsd &&
        other.automaticDiscountUsd == automaticDiscountUsd &&
        other.estimatedTotalInr == estimatedTotalInr &&
        other.exchangeRate == exchangeRate;
  }

  @override
  int get hashCode => Object.hash(
        subtotalUsd,
        discountedSubtotalUsd,
        totalDiscountUsd,
        promoDiscountUsd,
        automaticDiscountUsd,
        estimatedTotalInr,
        exchangeRate,
      );
}

/// Cart screen state backed by live cart/delivery APIs.
class CartState {
  const CartState({
    this.items = const [],
    this.summary = CartSummary.empty,
    this.address,
    this.addresses = const [],
    this.canCheckout = false,
    this.isLoading = false,
    this.isMutating = false,
    this.errorMessage,
    this.exchangeRate,
  });

  final List<CartItem> items;
  final CartSummary summary;
  final DeliveryAddress? address;
  final List<DeliveryAddress> addresses;
  final bool canCheckout;
  final bool isLoading;
  final bool isMutating;
  final String? errorMessage;
  final double? exchangeRate;

  int get count => items.length;
  bool get isEmpty => items.isEmpty;
  bool get hasAddress => address != null;

  CartTotals get totals =>
      CartTotals.fromSummary(summary, rate: exchangeRate);

  ({String? code, bool applied}) get promo {
    final codes = summary.appliedPromoCodes;
    if (codes.isEmpty) return (code: null, applied: false);
    return (code: codes.first.code, applied: true);
  }

  CartState copyWith({
    List<CartItem>? items,
    CartSummary? summary,
    DeliveryAddress? address,
    List<DeliveryAddress>? addresses,
    bool? canCheckout,
    bool? isLoading,
    bool? isMutating,
    String? errorMessage,
    double? exchangeRate,
    bool clearAddress = false,
    bool clearError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      address: clearAddress ? null : (address ?? this.address),
      addresses: addresses ?? this.addresses,
      canCheckout: canCheckout ?? this.canCheckout,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }
}

/// How much cart data to fetch in one load.
enum CartLoadMode {
  /// Badge / home: `GET /cart/summary` only.
  light,

  /// After add/remove/qty: cart rows + pricing (no delivery).
  merchandise,

  /// Cart screen: merchandise + delivery selection/addresses.
  full,
}

class CartNotifier extends Notifier<CartState> {
  CancelToken? _loadToken;
  Future<void>? _inFlight;
  CartLoadMode? _inFlightMode;

  CartRepository get _cart => ref.read(cartRepositoryProvider);
  DeliveryRepository get _delivery => ref.read(deliveryRepositoryProvider);

  @override
  CartState build() {
    ref.onDispose(() {
      _loadToken?.cancel();
      _loadToken = null;
      _inFlight = null;
      _inFlightMode = null;
    });

    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated) {
        // Prefer light only when coming from signed-out; avoid stacking a
        // second fetch if a full/merchandise load is already running.
        refresh(mode: CartLoadMode.light);
      } else if (prev?.isAuthenticated == true && !next.isAuthenticated) {
        state = const CartState();
      }
    });

    // Defer light bootstrap one event-loop turn so CartScreen's full refresh
    // microtask (scheduled in initState) can claim in-flight first.
    Future(() {
      if (ref.read(authProvider).isAuthenticated) {
        refresh(mode: CartLoadMode.light);
      }
    });

    return const CartState(isLoading: true);
  }

  /// Loads cart data. Concurrent identical/weaker loads join the in-flight one.
  /// A stronger mode cancels a weaker in-flight load and replaces it.
  Future<void> refresh({
    CartLoadMode mode = CartLoadMode.full,
    bool force = false,
  }) async {
    if (!ref.read(authProvider).isAuthenticated) {
      state = const CartState();
      return;
    }

    if (_inFlight != null && _inFlightMode != null) {
      final inFlight = _inFlight!;
      final inFlightMode = _inFlightMode!;

      // Same or weaker → share the existing request (no second network round).
      if (!force && !_isStrongerMode(mode, inFlightMode)) {
        return inFlight;
      }

      // Stronger (or forced) → cancel weaker work and start fresh below.
      if (_isStrongerMode(mode, inFlightMode) || force) {
        _loadToken?.cancel('cart-load-upgrade');
      }
    }

    final token = CancelToken();
    _loadToken = token;

    final run = _load(mode: mode, token: token);
    _inFlight = run;
    _inFlightMode = mode;
    try {
      await run;
    } finally {
      if (identical(_inFlight, run)) {
        _inFlight = null;
        _inFlightMode = null;
      }
    }
  }

  bool _isStrongerMode(CartLoadMode requested, CartLoadMode inFlight) {
    return requested.index > inFlight.index;
  }

  Future<void> _load({
    required CartLoadMode mode,
    required CancelToken token,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    Failure? firstFailure;
    var items = state.items;
    var summary = state.summary;
    var address = state.address;
    var addresses = state.addresses;
    var canCheckout = state.canCheckout;

    if (mode == CartLoadMode.light) {
      final summaryResult = await _cart.getSummary(cancelToken: token);
      if (token.isCancelled) return;
      switch (summaryResult) {
        case Success(:final value):
          summary = value;
          items = CartMapper.itemsFromSummary(value);
        case ResultFailure(:final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          firstFailure = failure;
      }
    } else {
      final cartFuture = _cart.getCart(cancelToken: token);
      final summaryFuture = _cart.getSummary(cancelToken: token);
      final deliveryFuture = mode == CartLoadMode.full
          ? _delivery.getCartDelivery(cancelToken: token)
          : null;

      final cartResult = await cartFuture;
      final summaryResult = await summaryFuture;
      if (token.isCancelled) return;

      switch (cartResult) {
        case Success(:final value):
          items = value;
        case ResultFailure(:final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          firstFailure = failure;
      }

      switch (summaryResult) {
        case Success(:final value):
          summary = value;
        case ResultFailure(:final failure):
          if (failure is NetworkFailure && failure.isCancelled) return;
          firstFailure ??= failure;
      }

      if (deliveryFuture != null) {
        final deliveryResult = await deliveryFuture;
        if (token.isCancelled) return;
        switch (deliveryResult) {
          case Success(:final value):
            address = value.selectedAddress;
            addresses = value.addresses;
            canCheckout = value.canCheckout;
          case ResultFailure(:final failure):
            if (failure is NetworkFailure && failure.isCancelled) return;
            firstFailure ??= failure;
        }

        // Address book is already on delivery-options/cart; fetch list only
        // when that payload omitted saved addresses.
        if (addresses.isEmpty) {
          final listed = await _delivery.listAddresses(cancelToken: token);
          if (token.isCancelled) return;
          if (listed case Success(:final value)) {
            if (value.isNotEmpty) {
              addresses = _mergeAddresses(value, addresses);
            }
          }
        }
      }

      items = CartMapper.mergeCartAndSummary(items, summary);
    }

    if (firstFailure != null && items.isEmpty && summary.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: firstFailure.message,
      );
      return;
    }

    state = CartState(
      items: items,
      summary: summary,
      address: address,
      addresses: addresses,
      canCheckout: canCheckout || address != null,
      isLoading: false,
      exchangeRate: state.exchangeRate,
    );
  }

  List<DeliveryAddress> _mergeAddresses(
    List<DeliveryAddress> primary,
    List<DeliveryAddress> secondary,
  ) {
    final byId = <String, DeliveryAddress>{};
    for (final a in [...secondary, ...primary]) {
      final id = a.id;
      if (id == null || id.isEmpty) continue;
      byId[id] = a;
    }
    return byId.values.toList(growable: false);
  }

  Future<Result<void, Failure>> addProduct({
    required String productId,
    required String productType,
    int quantity = 1,
    Map<String, dynamic>? specifications,
  }) async {
    final blocked = AccountAccess.blockReason(ref.read(authProvider));
    if (blocked != null) {
      return Result.failure(AuthFailure(blocked));
    }
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _cart.addItem(
      productId: productId,
      productType: productType,
      quantity: quantity,
      specifications: specifications,
    );
    switch (result) {
      case Success():
        await refresh(mode: CartLoadMode.merchandise, force: true);
        state = state.copyWith(isMutating: false);
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  Future<Result<void, Failure>> removeItem(String cartId) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _cart.removeItem(cartId: cartId);
    switch (result) {
      case Success():
        await refresh(mode: CartLoadMode.merchandise, force: true);
        state = state.copyWith(isMutating: false);
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  Future<Result<void, Failure>> updateQuantity({
    required String cartId,
    required int quantity,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _cart.updateQuantity(
      cartId: cartId,
      quantity: quantity,
    );
    switch (result) {
      case Success():
        await refresh(mode: CartLoadMode.merchandise, force: true);
        state = state.copyWith(isMutating: false);
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  Future<Result<void, Failure>> applyPromo(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) {
      return Result.failure(const ValidationFailure('Enter a promo code.'));
    }
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _cart.applyPromo(code: normalized);
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          summary: value,
          items: CartMapper.mergeSummaryPrices(state.items, value),
          isMutating: false,
        );
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  Future<Result<void, Failure>> removePromo(String code) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _cart.removePromo(code: code);
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          summary: value,
          items: CartMapper.mergeSummaryPrices(state.items, value),
          isMutating: false,
        );
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  Future<Result<DeliveryAddress, Failure>> saveAndSelectAddress(
    DeliveryAddress draft,
  ) async {
    state = state.copyWith(isMutating: true, clearError: true);

    final String addressId;
    if (draft.id != null && draft.id!.isNotEmpty) {
      final updated = await _delivery.updateAddress(draft);
      switch (updated) {
        case Success(:final value):
          addressId = value.id ?? draft.id!;
        case ResultFailure(:final failure):
          state =
              state.copyWith(isMutating: false, errorMessage: failure.message);
          return Result.failure(failure);
      }
    } else {
      final created = await _delivery.createAddress(draft);
      switch (created) {
        case Success(:final value):
          addressId = value.id ?? '';
          if (addressId.isEmpty) {
            state = state.copyWith(isMutating: false);
            return Result.failure(
              const NetworkFailure('Could not save the delivery address.'),
            );
          }
        case ResultFailure(:final failure):
          state =
              state.copyWith(isMutating: false, errorMessage: failure.message);
          return Result.failure(failure);
      }
    }

    final selected = await _delivery.selectAddress(addressId: addressId);
    switch (selected) {
      case Success(:final value):
        final merged = _mergeAddresses(
          [...state.addresses, value],
          state.addresses,
        );
        state = state.copyWith(
          address: value,
          addresses: merged,
          canCheckout: true,
          isMutating: false,
        );
        unawaitedRefreshDelivery();
        return Result.success(value);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  /// Local selection only — no network. Sync to the server at checkout.
  Result<void, Failure> selectExistingAddress(String addressId) {
    if (addressId.isEmpty) {
      return Result.failure(
        const NetworkFailure('Could not select the delivery address.'),
      );
    }
    DeliveryAddress? match;
    for (final a in state.addresses) {
      if (a.id == addressId) {
        match = a;
        break;
      }
    }
    match ??= state.address?.id == addressId ? state.address : null;
    if (match == null) {
      return Result.failure(
        const NetworkFailure('Could not select the delivery address.'),
      );
    }
    state = state.copyWith(
      address: match,
      canCheckout: true,
      clearError: true,
    );
    return Result.success(null);
  }

  /// Persists the locally selected address before create-order.
  Future<Result<void, Failure>> syncSelectedAddressForCheckout() async {
    final id = state.address?.id;
    if (id == null || id.isEmpty) {
      return Result.failure(
        const ValidationFailure(
          'Please add and select a delivery address before payment.',
        ),
      );
    }
    final selected = await _delivery.selectAddress(addressId: id);
    switch (selected) {
      case Success(:final value):
        state = state.copyWith(
          address: value,
          canCheckout: true,
        );
        return Result.success(null);
      case ResultFailure(:final failure):
        return Result.failure(failure);
    }
  }

  Future<Result<void, Failure>> deleteAddress(String addressId) async {
    if (addressId.isEmpty) {
      return Result.failure(
        const NetworkFailure('Could not delete the delivery address.'),
      );
    }
    state = state.copyWith(isMutating: true, clearError: true);
    final result = await _delivery.deleteAddress(addressId);
    switch (result) {
      case Success():
        final remaining =
            state.addresses.where((a) => a.id != addressId).toList();
        final wasSelected = state.address?.id == addressId;
        state = state.copyWith(
          addresses: remaining,
          address: wasSelected ? null : state.address,
          canCheckout: wasSelected ? false : state.canCheckout,
          isMutating: false,
          clearAddress: wasSelected,
        );
        unawaitedRefreshDelivery();
        return Result.success(null);
      case ResultFailure(:final failure):
        state = state.copyWith(isMutating: false, errorMessage: failure.message);
        return Result.failure(failure);
    }
  }

  void setExchangeRate(double? rate) {
    if (rate == state.exchangeRate) return;
    state = state.copyWith(exchangeRate: rate);
  }

  void unawaitedRefreshDelivery() {
    Future(() async {
      final delivery = await _delivery.getCartDelivery();

      var addresses = state.addresses;
      DeliveryAddress? selected = state.address;
      var canCheckout = state.canCheckout;

      if (delivery case Success(:final value)) {
        selected = value.selectedAddress ?? selected;
        if (value.addresses.isNotEmpty) {
          addresses = _mergeAddresses(value.addresses, addresses);
        }
        canCheckout = value.canCheckout || selected != null;
      }

      if (addresses.isEmpty) {
        final listed = await _delivery.listAddresses();
        if (listed case Success(:final value)) {
          if (value.isNotEmpty) {
            addresses = _mergeAddresses(value, addresses);
          }
        }
      }

      state = state.copyWith(
        address: selected,
        addresses: addresses,
        canCheckout: canCheckout,
      );
    });
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.select((s) => s.count));
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.isEmpty));
});

final cartIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.isLoading));
});

final cartIsMutatingProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.isMutating));
});

final cartErrorProvider = Provider<String?>((ref) {
  return ref.watch(cartProvider.select((s) => s.errorMessage));
});

final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartProvider.select((s) => s.items));
});

final cartAddressProvider = Provider<DeliveryAddress?>((ref) {
  return ref.watch(cartProvider.select((s) => s.address));
});

final cartAddressesProvider = Provider<List<DeliveryAddress>>((ref) {
  return ref.watch(cartProvider.select((s) => s.addresses));
});

final cartHasAddressProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider.select((s) => s.hasAddress));
});

final cartCanCheckoutProvider = Provider<bool>((ref) {
  return ref.watch(
    cartProvider.select(
      (s) =>
          s.canCheckout &&
          s.items.any((e) => e.isAvailable) &&
          s.items.every((e) => e.isAvailable),
    ),
  );
});

/// Merchandise USD for purchasable lines only (unavailable items excluded).
final cartAvailableMerchandiseUsdProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider);
  final totals = ref.watch(cartTotalsProvider);
  final unavailableUsd = items
      .where((e) => !e.isAvailable)
      .fold<double>(0, (sum, e) => sum + e.displayPriceUsd);
  final adjusted = totals.discountedSubtotalUsd - unavailableUsd;
  if (adjusted > 0) return adjusted;
  return items
      .where((e) => e.isAvailable)
      .fold<double>(0, (sum, e) => sum + e.displayPriceUsd);
});

final cartHasUnavailableItemsProvider = Provider<bool>((ref) {
  return ref.watch(
    cartProvider.select((s) => s.items.any((e) => !e.isAvailable)),
  );
});

final cartPromoProvider = Provider<({String? code, bool applied})>((ref) {
  return ref.watch(cartProvider.select((s) => s.promo));
});

final cartTotalsProvider = Provider<CartTotals>((ref) {
  return ref.watch(cartProvider.select((s) => s.totals));
});

final cartSummaryProvider = Provider<CartSummary>((ref) {
  return ref.watch(cartProvider.select((s) => s.summary));
});

final isProductInCartProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(
    cartProvider.select(
      (s) => s.items.any((e) => e.productId == productId),
    ),
  );
});
