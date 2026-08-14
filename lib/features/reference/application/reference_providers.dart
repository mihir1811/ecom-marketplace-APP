import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/reference_repository_impl.dart';
import '../domain/models/reference_models.dart';
import '../domain/repositories/reference_repository.dart';

class ReferenceHubState {
  const ReferenceHubState({
    this.profile,
    this.inbound = const [],
    this.outbound = const [],
    this.purchases = const [],
    this.purchasesPage = 1,
    this.purchasesHasMore = false,
    this.isLoading = false,
    this.isLoadingMorePurchases = false,
    this.errorMessage,
  });

  final ReferenceProfile? profile;
  final List<ReferenceRequest> inbound;
  final List<ReferenceRequest> outbound;
  final List<ReferencePurchase> purchases;
  final int purchasesPage;
  final bool purchasesHasMore;
  final bool isLoading;
  final bool isLoadingMorePurchases;
  final String? errorMessage;

  ReferenceHubState copyWith({
    ReferenceProfile? profile,
    List<ReferenceRequest>? inbound,
    List<ReferenceRequest>? outbound,
    List<ReferencePurchase>? purchases,
    int? purchasesPage,
    bool? purchasesHasMore,
    bool? isLoading,
    bool? isLoadingMorePurchases,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReferenceHubState(
      profile: profile ?? this.profile,
      inbound: inbound ?? this.inbound,
      outbound: outbound ?? this.outbound,
      purchases: purchases ?? this.purchases,
      purchasesPage: purchasesPage ?? this.purchasesPage,
      purchasesHasMore: purchasesHasMore ?? this.purchasesHasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMorePurchases:
          isLoadingMorePurchases ?? this.isLoadingMorePurchases,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReferenceHubNotifier extends Notifier<ReferenceHubState> {
  CancelToken? _cancelToken;

  ReferenceRepository get _repo => ref.read(referenceRepositoryProvider);

  @override
  ReferenceHubState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const ReferenceHubState(isLoading: true);
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final me = await _repo.getMe(cancelToken: _cancelToken);
    final inbound = await _repo.listInbound(cancelToken: _cancelToken);
    final outbound = await _repo.listOutbound(cancelToken: _cancelToken);
    final purchases = await _repo.listPurchases(
      page: 1,
      cancelToken: _cancelToken,
    );

    Failure? firstFailure;
    for (final result in [me, inbound, outbound, purchases]) {
      if (result case ResultFailure(failure: final failure)) {
        if (failure is NetworkFailure && failure.isCancelled) return;
        firstFailure ??= failure;
      }
    }

    state = ReferenceHubState(
      profile: me is Success<ReferenceProfile, Failure> ? me.value : null,
      inbound: inbound is Success<List<ReferenceRequest>, Failure>
          ? inbound.value
          : const [],
      outbound: outbound is Success<List<ReferenceRequest>, Failure>
          ? outbound.value
          : const [],
      purchases: purchases is Success<ReferencePurchasePage, Failure>
          ? purchases.value.items
          : const [],
      purchasesPage: purchases is Success<ReferencePurchasePage, Failure>
          ? purchases.value.page
          : 1,
      purchasesHasMore: purchases is Success<ReferencePurchasePage, Failure>
          ? purchases.value.hasMore
          : false,
      isLoading: false,
      errorMessage: firstFailure?.message,
    );
  }

  Future<void> loadMorePurchases() async {
    if (state.isLoading ||
        state.isLoadingMorePurchases ||
        !state.purchasesHasMore) {
      return;
    }
    state = state.copyWith(isLoadingMorePurchases: true, clearError: true);
    final next = state.purchasesPage + 1;
    final result = await _repo.listPurchases(page: next);
    switch (result) {
      case Success(value: final page):
        state = state.copyWith(
          purchases: [...state.purchases, ...page.items],
          purchasesPage: page.page,
          purchasesHasMore: page.hasMore,
          isLoadingMorePurchases: false,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingMorePurchases: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<Result<ReferenceRequest, Failure>> request(String emailOrCode) async {
    final result = await _repo.request(emailOrCode: emailOrCode);
    if (result case Success()) {
      await refresh();
    }
    return result;
  }

  Future<Result<ReferenceRequest, Failure>> accept(String id) async {
    final result = await _repo.accept(id: id);
    if (result case Success()) {
      await refresh();
    }
    return result;
  }

  Future<Result<ReferenceRequest, Failure>> reject(String id) async {
    final result = await _repo.reject(id: id);
    if (result case Success()) {
      await refresh();
    }
    return result;
  }
}

final referenceHubProvider =
    NotifierProvider<ReferenceHubNotifier, ReferenceHubState>(
  ReferenceHubNotifier.new,
);
