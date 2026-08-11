import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/product_offer_repository_impl.dart';
import '../domain/models/product_offer.dart';
import '../domain/repositories/product_offer_repository.dart';

class SellerOfferListState {
  const SellerOfferListState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.statusFilter,
  });

  final List<ProductOffer> items;
  final bool isLoading;
  final String? errorMessage;
  final String? statusFilter;

  SellerOfferListState copyWith({
    List<ProductOffer>? items,
    bool? isLoading,
    String? errorMessage,
    String? statusFilter,
    bool clearError = false,
    bool clearFilter = false,
  }) {
    return SellerOfferListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class SellerOfferListNotifier extends Notifier<SellerOfferListState> {
  CancelToken? _cancelToken;

  ProductOfferRepository get _repo => ref.read(productOfferRepositoryProvider);

  @override
  SellerOfferListState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const SellerOfferListState(isLoading: true);
  }

  Future<void> refresh({String? statusFilter}) async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = SellerOfferListState(
      isLoading: true,
      statusFilter: statusFilter,
    );

    final result = await _repo.listSeller(
      page: 1,
      statusFilter: statusFilter,
      cancelToken: _cancelToken,
    );
    switch (result) {
      case Success(value: final page):
        state = SellerOfferListState(
          items: page.items,
          statusFilter: statusFilter,
        );
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = SellerOfferListState(
          errorMessage: failure.message,
          statusFilter: statusFilter,
        );
    }
  }

  Future<Result<ProductOffer, Failure>> respond({
    required String id,
    required ProductOfferStatus status,
  }) async {
    final result = await _repo.respond(id: id, status: status);
    if (result case Success(value: final updated)) {
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == updated.id) updated else item,
        ],
      );
    }
    return result;
  }
}

final sellerOfferListProvider =
    NotifierProvider<SellerOfferListNotifier, SellerOfferListState>(
  SellerOfferListNotifier.new,
);

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
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };
    return result;
  }
}

final productOfferMutationProvider =
    NotifierProvider<ProductOfferMutationNotifier, AsyncValue<void>>(
  ProductOfferMutationNotifier.new,
);
