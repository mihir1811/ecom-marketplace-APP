import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../cart/application/cart_provider.dart';
import '../../product_detail/application/catalog_product_detail_loader.dart';
import '../../product_detail/domain/models/product_detail.dart';
import '../data/repositories/product_offer_repository_impl.dart';
import '../domain/models/product_offer.dart';
import '../domain/repositories/product_offer_repository.dart';

class OfferListState {
  const OfferListState({
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.statusFilter,
  });

  final List<ProductOffer> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? statusFilter;

  OfferListState copyWith({
    List<ProductOffer>? items,
    int? total,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OfferListState(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: statusFilter,
    );
  }
}

/// Seller list kept under its old name for existing screens.
typedef SellerOfferListState = OfferListState;

/// Paged offer list with a server-side `status` filter.
abstract class _OfferListNotifier extends Notifier<OfferListState> {
  CancelToken? _cancelToken;

  ProductOfferRepository get _repo => ref.read(productOfferRepositoryProvider);

  Future<Result<ProductOfferListPage, Failure>> fetchPage({
    required int page,
    String? statusFilter,
    CancelToken? cancelToken,
  });

  /// Hook for filling in what the list endpoint leaves out.
  Future<void> hydrate(List<ProductOffer> items) async {}

  @override
  OfferListState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const OfferListState(isLoading: true);
  }

  Future<void> refresh({String? statusFilter}) async {
    _cancelToken?.cancel('refresh');
    final token = _cancelToken = CancelToken();
    state = OfferListState(
      items: state.statusFilter == statusFilter ? state.items : const [],
      isLoading: true,
      statusFilter: statusFilter,
    );

    final result = await fetchPage(
      page: 1,
      statusFilter: statusFilter,
      cancelToken: token,
    );
    switch (result) {
      case Success(value: final page):
        state = OfferListState(
          items: page.items,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          statusFilter: statusFilter,
        );
        await hydrate(page.items);
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = OfferListState(
          errorMessage: failure.message,
          statusFilter: statusFilter,
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final filter = state.statusFilter;
    final result = await fetchPage(
      page: state.currentPage + 1,
      statusFilter: filter,
    );
    if (state.statusFilter != filter) return;
    switch (result) {
      case Success(value: final page):
        final known = state.items.map((o) => o.id).toSet();
        final fresh = [
          for (final o in page.items)
            if (!known.contains(o.id)) o,
        ];
        state = state.copyWith(
          items: [...state.items, ...fresh],
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
        await hydrate(fresh);
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  void replace(ProductOffer offer) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == offer.id) offer else item,
      ],
    );
  }
}

/// Offers received (`GET /product-offer/seller`). Stones whose snapshot
/// lacks a title or `listedPrice` are fetched once by type and id.
class SellerOfferListNotifier extends _OfferListNotifier {
  final Map<String, ProductDetail?> _products = {};

  @override
  Future<Result<ProductOfferListPage, Failure>> fetchPage({
    required int page,
    String? statusFilter,
    CancelToken? cancelToken,
  }) => _repo.listSeller(
    page: page,
    statusFilter: statusFilter,
    cancelToken: cancelToken,
  );

  @override
  Future<void> hydrate(List<ProductOffer> items) async {
    final missing = {
      for (final o in items)
        if ((o.productLabel == null || o.listPrice == null) &&
            !_products.containsKey(o.productId))
          o.productId: o.productType,
    };
    await Future.wait([
      for (final entry in missing.entries)
        CatalogProductDetailLoader.load(
          ref.read,
          productType: entry.value,
          productId: entry.key,
        ).then((detail) => _products[entry.key] = detail),
    ]);
    if (missing.isEmpty && _products.isEmpty) return;
    state = state.copyWith(
      items: [for (final o in state.items) _withProduct(o)],
    );
  }

  ProductOffer _withProduct(ProductOffer offer) {
    final detail = _products[offer.productId];
    if (detail == null) return offer;
    final images = detail.media.images;
    final reference = detail.referenceValue.trim();
    return offer.withProduct(
      productLabel: detail.title,
      stockNumber: reference.isEmpty || reference == detail.id
          ? null
          : reference,
      listPrice: detail.price.priceUsd > 0 ? detail.price.priceUsd : null,
      imageUrl: images.isNotEmpty && !images.first.isAsset
          ? images.first.path
          : null,
      certificateLabel: _certificate(detail.certification),
    );
  }

  static String? _certificate(ProductCertification? c) {
    if (c == null || c.authority.trim().isEmpty) return null;
    final number = c.referenceValue?.trim();
    return number == null || number.isEmpty
        ? c.authority
        : '${c.authority} · $number';
  }

  /// Product page for an offer, when it could be loaded.
  ProductDetail? productFor(ProductOffer offer) => _products[offer.productId];

  /// Accept, reject or counter a buyer's offer. A counter needs [amount]
  /// (decimal string) and returns the new counter-offer.
  Future<Result<ProductOffer, Failure>> respond({
    required String id,
    required ProductOfferStatus status,
    String? amount,
    String? message,
  }) async {
    final result = await _repo.respond(
      id: id,
      status: status,
      amount: amount,
      message: message,
    );
    switch (result) {
      case Success(value: final updated):
        replace(_withProduct(updated));
        // Accepting closes every other open offer on the stone; a counter
        // turns the row into a new move with its own id.
        if (status != ProductOfferStatus.rejected) {
          await refresh(statusFilter: state.statusFilter);
        }
      case ResultFailure():
        // Most errors mean the offer changed since the list loaded.
        await refresh(statusFilter: state.statusFilter);
    }
    return result;
  }
}

final sellerOfferListProvider =
    NotifierProvider<SellerOfferListNotifier, OfferListState>(
      SellerOfferListNotifier.new,
    );

/// The signed-in buyer's offers (`GET /product-offer/mine`), with the
/// product snapshot for list cards.
class BuyerOfferListNotifier extends _OfferListNotifier {
  @override
  Future<Result<ProductOfferListPage, Failure>> fetchPage({
    required int page,
    String? statusFilter,
    CancelToken? cancelToken,
  }) => _repo.listMineAll(
    page: page,
    statusFilter: statusFilter,
    cancelToken: cancelToken,
  );
}

final buyerOfferListProvider =
    NotifierProvider<BuyerOfferListNotifier, OfferListState>(
      BuyerOfferListNotifier.new,
    );

/// Identifies one stone for [productOfferEligibilityProvider].
typedef OfferProductKey = ({
  String productType,
  String productId,
  int maxAttempts,
});

/// The buyer's own offers on one stone, folded into what the product page
/// may show (make an offer, waiting, no attempts left, pay now).
final productOfferEligibilityProvider = FutureProvider.autoDispose
    .family<ProductOfferEligibility, OfferProductKey>((ref, key) async {
      final signedIn = ref.watch(
        authProvider.select((s) => s.isAuthenticated),
      );
      if (!signedIn || !OfferProductType.supports(key.productType)) {
        return ProductOfferEligibility(
          offers: const [],
          maxAttempts: key.maxAttempts,
        );
      }
      // Back in the foreground: the offer may have been answered, expired
      // or auto-declined meanwhile.
      final lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
      ref.onDispose(lifecycle.dispose);
      final token = CancelToken();
      ref.onDispose(token.cancel);
      final result = await ref
          .read(productOfferRepositoryProvider)
          .listMine(
            productType: key.productType,
            productId: key.productId,
            cancelToken: token,
          );
      return switch (result) {
        Success(value: final offers) => ProductOfferEligibility(
          offers: offers,
          maxAttempts: key.maxAttempts,
        ),
        // The backend still enforces every rule; fall back to the button.
        ResultFailure() => ProductOfferEligibility(
          offers: const [],
          maxAttempts: key.maxAttempts,
        ),
      };
    });

class ProductOfferMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  ProductOfferRepository get _repo => ref.read(productOfferRepositoryProvider);

  Future<Result<ProductOffer, Failure>> create({
    required String productId,
    required String productType,
    required String amount,
    String? message,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.create(
      productId: productId,
      productType: productType,
      amount: amount,
      message: message,
    );
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    _invalidate();
    return result;
  }

  /// Buyer answers the seller's counter-offer: accept, decline, or counter
  /// back with [amount] (decimal string, below the seller's price). For a
  /// counter the result is the buyer's new pending offer.
  Future<Result<ProductOffer, Failure>> answerCounter({
    required String counterOfferId,
    required ProductOfferStatus answer,
    String? amount,
    String? message,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repo.respond(
      id: counterOfferId,
      status: answer,
      amount: amount,
      message: message,
    );
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    _invalidate();
    return result;
  }

  /// Puts an accepted offer in the bag at the offered price. Re-fetches the
  /// offer first rather than trusting a cached copy; checkout then runs as
  /// for any order.
  Future<Result<ProductOffer, Failure>> addAcceptedOfferToBag(
    ProductOffer offer,
  ) async {
    state = const AsyncValue.loading();
    final fresh = await _repo.listMine(
      productType: offer.productType,
      productId: offer.productId,
    );
    final Result<ProductOffer, Failure> result;
    switch (fresh) {
      case ResultFailure(:final failure):
        result = Result.failure(failure);
      case Success(value: final offers):
        final current = offers.where((o) => o.id == offer.id).firstOrNull;
        if (current != null && current.isWithGemworld) {
          result = Result.failure(
            const ValidationFailure(
              'GemWorld is already arranging the payment for your accepted '
              'offer on this product.',
            ),
          );
        } else if (current == null || !current.isPayable) {
          result = Result.failure(
            const ValidationFailure(
              'This offer is no longer available to purchase. It may have '
              'expired after 24 hours.',
            ),
          );
        } else {
          final added = await ref
              .read(cartProvider.notifier)
              .addProduct(
                productId: current.productId,
                productType: current.productType,
                specifications: {'offerId': current.id},
              );
          result = switch (added) {
            Success() => Result.success(current),
            ResultFailure(:final failure) => Result.failure(failure),
          };
        }
    }
    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    if (result is ResultFailure) _invalidate();
    return result;
  }

  /// Offer state changed: reload the product page rules and the buyer list.
  void _invalidate() {
    ref.invalidate(productOfferEligibilityProvider);
    if (ref.exists(buyerOfferListProvider)) {
      ref.read(buyerOfferListProvider.notifier).refresh(
        statusFilter: ref.read(buyerOfferListProvider).statusFilter,
      );
    }
  }
}

final productOfferMutationProvider =
    NotifierProvider<ProductOfferMutationNotifier, AsyncValue<void>>(
      ProductOfferMutationNotifier.new,
    );
