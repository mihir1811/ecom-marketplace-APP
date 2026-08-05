import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/mappers/inquiry_request_mapper.dart';
import '../data/repositories/inquiry_repository_impl.dart';
import '../domain/models/seller_inquiry.dart';
import '../domain/repositories/inquiry_repository.dart';

String _inquiryCacheKey(InquiryCategory category, String id) =>
    '${category.name}:$id';

/// Inquiries already loaded in list tabs — used as detail fallback when GET
/// one fails but the row came from the user's own list.
final inquiryListCacheProvider = Provider<Map<String, SellerInquiry>>((ref) {
  final cache = <String, SellerInquiry>{};
  for (final category in InquiryCategory.values) {
    final listState = ref.watch(inquiryListProvider(category));
    for (final item in listState.items) {
      cache[_inquiryCacheKey(category, item.id)] = item;
    }
  }
  return cache;
});

class InquiryListState {
  const InquiryListState({
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<SellerInquiry> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  InquiryListState copyWith({
    List<SellerInquiry>? items,
    int? total,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InquiryListState(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InquiryListNotifier
    extends FamilyNotifier<InquiryListState, InquiryCategory> {
  CancelToken? _cancelToken;

  @override
  InquiryListState build(InquiryCategory category) {
    ref.onDispose(() => _cancelToken?.cancel());
    Future.microtask(refresh);
    return const InquiryListState(isLoading: true);
  }

  InquiryRepository get _repo => ref.read(inquiryRepositoryProvider);

  List<SellerInquiry> _ownedItems(List<SellerInquiry> items) {
    final user = ref.read(authProvider).user;
    if (user == null || user.isAdmin) return items;
    return items.where((item) => item.userId == user.id).toList();
  }

  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repo.listInquiries(
      category: arg,
      page: 1,
      cancelToken: _cancelToken,
    );

    switch (result) {
      case Success(value: final page):
        final owned = _ownedItems(page.items);
        state = InquiryListState(
          items: owned,
          total: owned.length,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        );
      case ResultFailure(failure: final failure):
        if (failure is NetworkFailure && failure.isCancelled) return;
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.currentPage + 1;

    final result = await _repo.listInquiries(
      category: arg,
      page: nextPage,
    );

    switch (result) {
      case Success(value: final page):
        final owned = _ownedItems(page.items);
        final merged = [...state.items, ...owned];
        state = state.copyWith(
          items: merged,
          total: merged.length,
          currentPage: page.currentPage,
          hasMore: page.hasMore,
          isLoadingMore: false,
        );
      case ResultFailure(failure: final failure):
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
    }
  }
}

final inquiryListProvider = NotifierProvider.family<InquiryListNotifier,
    InquiryListState, InquiryCategory>(
  InquiryListNotifier.new,
);

final inquiryDetailProvider = FutureProvider.autoDispose
    .family<SellerInquiry, ({InquiryCategory category, String id})>(
  (ref, params) async {
    final result = await ref.read(inquiryRepositoryProvider).getInquiry(
          category: params.category,
          id: params.id,
        );

    switch (result) {
      case Success(value: final inquiry):
        return inquiry;
      case ResultFailure(failure: final failure):
        final cached = ref.read(inquiryListCacheProvider)[
          _inquiryCacheKey(params.category, params.id)
        ];
        final user = ref.read(authProvider).user;
        if (cached != null &&
            user != null &&
            (user.isAdmin || cached.userId == user.id)) {
          return cached;
        }
        throw failure;
    }
  },
);

class InquiryMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<Result<SellerInquiry, Failure>> create({
    required InquiryCategory category,
    required Map<String, String> textFields,
    required Map<String, bool> boolFields,
    DateTime? urgency,
  }) async {
    state = const AsyncValue.loading();
    final body = InquiryRequestMapper.toCreateBody(
      category: category,
      textFields: textFields,
      boolFields: boolFields,
      urgency: urgency,
    );

    final result = await ref.read(inquiryRepositoryProvider).createInquiry(
          category: category,
          body: body,
        );

    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };

    if (result case Success()) {
      ref.invalidate(inquiryListProvider(category));
    }

    return result;
  }

  Future<Result<void, Failure>> delete({
    required InquiryCategory category,
    required String id,
  }) async {
    state = const AsyncValue.loading();
    final result = await ref.read(inquiryRepositoryProvider).deleteInquiry(
          category: category,
          id: id,
        );

    state = switch (result) {
      Success() => const AsyncValue.data(null),
      ResultFailure(failure: final failure) =>
        AsyncValue.error(failure, StackTrace.current),
    };

    if (result case Success()) {
      ref.invalidate(inquiryListProvider(category));
      ref.invalidate(
        inquiryDetailProvider((category: category, id: id)),
      );
    }

    return result;
  }
}

final inquiryMutationProvider =
    NotifierProvider<InquiryMutationNotifier, AsyncValue<void>>(
  InquiryMutationNotifier.new,
);
