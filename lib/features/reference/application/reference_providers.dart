import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/reference_repository_impl.dart';
import '../domain/models/reference_models.dart';
import '../domain/repositories/reference_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

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
    this.isLoadingPurchases = false,
    this.errorMessage,
    this.purchasesError,
  });

  final ReferenceProfile? profile;
  final List<ReferenceRequest> inbound;
  final List<ReferenceRequest> outbound;
  final List<ReferencePurchase> purchases;
  final int purchasesPage;
  final bool purchasesHasMore;
  final bool isLoading;
  final bool isLoadingMorePurchases;
  final bool isLoadingPurchases;
  final String? errorMessage;
  final String? purchasesError;

  ReferenceHubState copyWith({
    ReferenceProfile? profile,
    List<ReferenceRequest>? inbound,
    List<ReferenceRequest>? outbound,
    List<ReferencePurchase>? purchases,
    int? purchasesPage,
    bool? purchasesHasMore,
    bool? isLoading,
    bool? isLoadingMorePurchases,
    bool? isLoadingPurchases,
    String? errorMessage,
    String? purchasesError,
    bool clearError = false,
    bool clearPurchasesError = false,
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
      isLoadingPurchases: isLoadingPurchases ?? this.isLoadingPurchases,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      purchasesError: clearPurchasesError
          ? null
          : (purchasesError ?? this.purchasesError),
    );
  }
}

class ReferenceHubNotifier extends Notifier<ReferenceHubState>
    with DisposeTolerantNotifier<ReferenceHubState> {
  CancelToken? _cancelToken;
  bool _started = false;
  Future<void>? _inFlight;
  int _refreshGen = 0;

  ReferenceRepository get _repo => ref.read(referenceRepositoryProvider);

  @override
  ReferenceHubState build() {
    ref.onDispose(() => _cancelToken?.cancel());
    if (!_started) {
      _started = true;
      Future.microtask(refresh);
    }
    return const ReferenceHubState(isLoading: true);
  }

  Future<void> refresh() async {
    final done = _doRefresh();
    _inFlight = done;
    try {
      await done;
      if (!ref.mounted) return;
    } finally {
      if (identical(_inFlight, done)) _inFlight = null;
    }
  }

  Future<void> _doRefresh() async {
    final gen = ++_refreshGen;
    final token = CancelToken();
    _cancelToken?.cancel('refresh');
    _cancelToken = token;

    state = state.copyWith(
      isLoading: true,
      isLoadingPurchases: true,
      clearError: true,
      clearPurchasesError: true,
    );

    final results = await Future.wait([
      _repo.getMe(cancelToken: token),
      _repo.listInbound(cancelToken: token),
      _repo.listOutbound(cancelToken: token),
      _repo.listPurchases(page: 1, cancelToken: token),
    ]);
    if (!ref.mounted) return;

    if (gen != _refreshGen || token.isCancelled) return;

    final me = results[0] as Result<ReferenceProfile, Failure>;
    final inbound = results[1] as Result<List<ReferenceRequest>, Failure>;
    final outbound = results[2] as Result<List<ReferenceRequest>, Failure>;
    final purchases = results[3] as Result<ReferencePurchasePage, Failure>;

    Failure? firstFailure;
    for (final result in [me, inbound, outbound, purchases]) {
      if (result case ResultFailure(:final failure)) {
        if (failure is NetworkFailure && failure.isCancelled) return;
        firstFailure ??= failure;
      }
    }

    final purchasePage = switch (purchases) {
      Success(:final value) => value,
      ResultFailure() => null,
    };
    final purchasesFailed = purchasePage == null;
    final purchasesError = switch (purchases) {
      ResultFailure(:final failure)
          when failure is! NetworkFailure || !failure.isCancelled =>
        failure.message,
      _ => null,
    };

    state = ReferenceHubState(
      profile: switch (me) {
        Success(:final value) => value,
        ResultFailure() => state.profile,
      },
      inbound: switch (inbound) {
        Success(:final value) => value,
        ResultFailure() => state.inbound,
      },
      outbound: switch (outbound) {
        Success(:final value) => value,
        ResultFailure() => state.outbound,
      },
      // Never wipe a successful purchases list when a later refresh fails.
      purchases: purchasePage?.items ?? state.purchases,
      purchasesPage: purchasePage?.page ?? state.purchasesPage,
      purchasesHasMore: purchasePage?.hasMore ?? state.purchasesHasMore,
      isLoading: false,
      isLoadingPurchases: false,
      errorMessage: firstFailure?.message,
      purchasesError: purchasesError,
    );

    // Profile can succeed while purchases flakes (connection blip). Retry once.
    if (purchasesFailed && state.profile != null) {
      Future.microtask(_retryPurchasesOnce);
    }
  }

  Future<void> _retryPurchasesOnce() async {
    if (state.isLoadingPurchases || state.isLoading) return;
    state = state.copyWith(isLoadingPurchases: true, clearPurchasesError: true);
    final result = await _repo.listPurchases(page: 1);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = state.copyWith(
          purchases: value.items,
          purchasesPage: value.page,
          purchasesHasMore: value.hasMore,
          isLoadingPurchases: false,
          clearPurchasesError: true,
        );
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) {
          state = state.copyWith(isLoadingPurchases: false);
          return;
        }
        state = state.copyWith(
          isLoadingPurchases: false,
          purchasesError: failure.message,
        );
    }
  }

  Future<void> loadMorePurchases() async {
    if (state.isLoading ||
        state.isLoadingMorePurchases ||
        state.isLoadingPurchases ||
        !state.purchasesHasMore) {
      return;
    }
    state = state.copyWith(
      isLoadingMorePurchases: true,
      clearPurchasesError: true,
    );
    final next = state.purchasesPage + 1;
    final result = await _repo.listPurchases(page: next);
    if (!ref.mounted) return;
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
          purchasesError: failure.message,
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
