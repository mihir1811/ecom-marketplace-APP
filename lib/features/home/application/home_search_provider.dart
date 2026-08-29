import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/home_search_repository_impl.dart';
import '../domain/models/home_search_result.dart';
import '../domain/repositories/home_search_repository.dart';

/// Live text in the sticky home search field (updated after debounce).
final homeSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Banner / spelling / similar-results metadata for the current search.
class HomeSearchMeta {
  const HomeSearchMeta({
    this.notice,
    this.isApproximate = false,
    this.correctedQuery,
  });

  final String? notice;
  final bool isApproximate;
  final String? correctedQuery;
}

final homeSearchMetaProvider = StateProvider<HomeSearchMeta>(
  (ref) => const HomeSearchMeta(),
);

typedef HomeSearchListState = PaginatedListState<HomeSearchResult>;

/// Infinite-scroll results for debounced [homeSearchQueryProvider].
final homeSearchResultsProvider =
    AsyncNotifierProvider<HomeSearchListNotifier, HomeSearchListState>(
      HomeSearchListNotifier.new,
    );

class HomeSearchListNotifier extends PaginatedAsyncNotifier<HomeSearchResult> {
  CancelToken? _cancelToken;
  bool _usingSimilar = false;

  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => [
    homeSearchQueryProvider,
  ];

  @override
  void onResetPagination() {
    _usingSimilar = false;
    ref.read(homeSearchMetaProvider.notifier).state = const HomeSearchMeta();
    final token = _cancelToken;
    if (token != null && !token.isCancelled) {
      token.cancel('home-search-reset');
    }
    _cancelToken = CancelToken();
  }

  @override
  Future<Result<PaginatedPage<HomeSearchResult>, Failure>> loadPage(
    int page,
  ) async {
    final query = ref.read(homeSearchQueryProvider).trim();
    if (query.length < 2) {
      ref.read(homeSearchMetaProvider.notifier).state = const HomeSearchMeta();
      return const Success(
        PaginatedPage<HomeSearchResult>(
          items: [],
          hasMore: false,
          totalCount: 0,
        ),
      );
    }

    if (page == 1) _usingSimilar = false;

    _cancelToken ??= CancelToken();
    final result = await ref
        .read(homeSearchRepositoryProvider)
        .search(
          query,
          page: page,
          pageSize: HomeSearchPageSize.defaultSize,
          forceSimilar: page > 1 && _usingSimilar,
          cancelToken: _cancelToken,
        );

    return switch (result) {
      Success(:final value) => _mapSuccessPage(page, value),
      ResultFailure(:final failure) => ResultFailure(failure),
    };
  }

  Success<PaginatedPage<HomeSearchResult>, Failure> _mapSuccessPage(
    int page,
    HomeSearchPage value,
  ) {
    if (page == 1) {
      _usingSimilar = value.isApproximate;
      ref.read(homeSearchMetaProvider.notifier).state = HomeSearchMeta(
        notice: value.notice,
        isApproximate: value.isApproximate,
        correctedQuery: value.correctedQuery,
      );
    } else if (value.isApproximate) {
      _usingSimilar = true;
    }
    return Success(
      PaginatedPage<HomeSearchResult>(
        items: value.items,
        hasMore: value.hasMore,
        totalCount: value.totalCount,
      ),
    );
  }
}
