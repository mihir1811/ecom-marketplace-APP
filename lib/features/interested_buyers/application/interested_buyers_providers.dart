import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/riverpod/dispose_tolerant.dart';
import '../data/repositories/interested_buyers_repository.dart';
import '../domain/models/interested_buyer.dart';

class InterestedBuyersState {
  const InterestedBuyersState({
    this.tab = InterestedBuyersTab.fresh,
    this.search = '',
    this.items = const [],
    this.summary,
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final InterestedBuyersTab tab;
  final String search;
  final List<InterestedBuyer> items;

  /// Null until the first load; stays put while tab and search change.
  final InterestedBuyersSummary? summary;
  final int total;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  InterestedBuyersState copyWith({
    List<InterestedBuyer>? items,
    InterestedBuyersSummary? summary,
    int? total,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InterestedBuyersState(
      tab: tab,
      search: search,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// The seller's Interested buyers list (`GET /interested-buyers`).
class InterestedBuyersNotifier extends Notifier<InterestedBuyersState>
    with DisposeTolerantNotifier<InterestedBuyersState> {
  CancelToken? _cancelToken;

  InterestedBuyersRepository get _repo =>
      ref.read(interestedBuyersRepositoryProvider);

  @override
  InterestedBuyersState build() {
    ref.watch(authProvider.select((s) => s.user?.id));
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const InterestedBuyersState(isLoading: true);
  }

  Future<void> setTab(InterestedBuyersTab tab) =>
      tab == state.tab ? Future.value() : _load(tab: tab, search: state.search);

  Future<void> setSearch(String search) => search.trim() == state.search
      ? Future.value()
      : _load(tab: state.tab, search: search.trim());

  Future<void> refresh() => _load(tab: state.tab, search: state.search);

  Future<void> _load({
    required InterestedBuyersTab tab,
    required String search,
  }) async {
    _cancelToken?.cancel('refresh');
    final token = _cancelToken = CancelToken();
    final same = tab == state.tab && search == state.search;
    state = InterestedBuyersState(
      tab: tab,
      search: search,
      items: same ? state.items : const [],
      summary: state.summary,
      total: same ? state.total : 0,
      isLoading: true,
    );
    final result = await _repo.list(
      tab: tab,
      search: search,
      cancelToken: token,
    );
    if (token.isCancelled) return;
    switch (result) {
      case Success(value: final page):
        state = InterestedBuyersState(
          tab: tab,
          search: search,
          items: page.items,
          summary: page.summary,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        );
      case ResultFailure(:final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final tab = state.tab;
    final search = state.search;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final result = await _repo.list(
      tab: tab,
      search: search,
      page: state.currentPage + 1,
    );
    if (state.tab != tab || state.search != search) return;
    switch (result) {
      case Success(value: final page):
        final known = {for (final b in state.items) b.id};
        state = state.copyWith(
          items: [
            ...state.items,
            for (final b in page.items)
              if (!known.contains(b.id)) b,
          ],
          summary: page.summary,
          total: page.total,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(:final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }

  /// Drops a row the server says is gone (404) until the reload lands.
  void drop(String cartId) {
    state = state.copyWith(
      items: [
        for (final b in state.items)
          if (b.id != cartId) b,
      ],
    );
  }
}

final interestedBuyersProvider =
    NotifierProvider.autoDispose<
      InterestedBuyersNotifier,
      InterestedBuyersState
    >(InterestedBuyersNotifier.new);

/// The buyer's "Seller offers on my cart" switch. Null while loading; on a
/// failed read the switch shows its default (on).
class SellerCartOutreachNotifier extends AsyncNotifier<bool>
    with DisposeTolerantAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null || userId.isEmpty) return true;
    final result = await ref
        .read(interestedBuyersRepositoryProvider)
        .readPreference();
    return switch (result) {
      Success(:final value) => value,
      ResultFailure() => true,
    };
  }

  /// Flips the switch at once; puts it back and returns false if the save
  /// fails.
  Future<bool> set(bool allow) async {
    final before = state.asData?.value ?? true;
    state = AsyncData(allow);
    final result = await ref
        .read(interestedBuyersRepositoryProvider)
        .savePreference(allow);
    if (!ref.mounted) return result is Success;
    switch (result) {
      case Success(:final value):
        state = AsyncData(value);
        return true;
      case ResultFailure():
        state = AsyncData(before);
        return false;
    }
  }
}

final sellerCartOutreachProvider =
    AsyncNotifierProvider<SellerCartOutreachNotifier, bool>(
      SellerCartOutreachNotifier.new,
    );
