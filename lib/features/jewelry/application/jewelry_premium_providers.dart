import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import '../domain/models/jewelry_filter_state.dart';
import '../domain/models/jewelry_premium.dart';
import '../domain/repositories/jewelry_repository.dart';
import '../../../core/riverpod/dispose_tolerant.dart';

/// The first Premium pieces for the home strip. The threshold is read on
/// every load (GemWorld can change it); unavailable or empty hides the
/// strip.
final jewelryPremiumStripProvider =
    FutureProvider.autoDispose<JewelryPremiumPage>((ref) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .watch(jewelryRepositoryProvider)
          .getPremium(
            page: 1,
            pageSize: 8,
            sort: JewelrySortOption.newest,
            cancelToken: cancel,
          );
      return switch (result) {
        Success(value: final page) => page,
        ResultFailure(failure: final failure) => throw failure,
      };
    });

/// The Premium screen's tab and sort.
typedef JewelryPremiumQuery = ({String? category, JewelrySortOption sort});

/// Premium pieces plus the segment's threshold and category counts.
class JewelryPremiumState {
  const JewelryPremiumState({
    this.pieces = const PaginatedListState(isInitialLoading: true),
    this.thresholdInr,
    this.categories = const [],
    this.available = true,
  });

  final PaginatedListState<Jewelry> pieces;

  /// Rupees; null until the first page arrives.
  final double? thresholdInr;
  final List<JewelryPremiumCategory> categories;
  final bool available;

  JewelryPremiumState copyWith({
    PaginatedListState<Jewelry>? pieces,
    double? thresholdInr,
    List<JewelryPremiumCategory>? categories,
    bool? available,
  }) => JewelryPremiumState(
    pieces: pieces ?? this.pieces,
    thresholdInr: thresholdInr ?? this.thresholdInr,
    categories: categories ?? this.categories,
    available: available ?? this.available,
  );
}

/// `GET /marketplace/premium`, paged, for one tab and sort.
final jewelryPremiumProvider = NotifierProvider.autoDispose
    .family<JewelryPremiumNotifier, JewelryPremiumState, JewelryPremiumQuery>(
      JewelryPremiumNotifier.new,
    );

class JewelryPremiumNotifier extends Notifier<JewelryPremiumState>
    with DisposeTolerantNotifier<JewelryPremiumState> {
  JewelryPremiumNotifier(this.arg);

  /// The family argument this notifier was created for.
  final JewelryPremiumQuery arg;

  JewelryPremiumQuery get query => arg;

  CancelToken? _cancel;
  int _page = 1;
  int _epoch = 0;

  @override
  JewelryPremiumState build() {
    ref.onDispose(() {
      _epoch++;
      _cancel?.cancel();
    });
    Future.microtask(_loadFirst);
    return const JewelryPremiumState();
  }

  Future<void> refresh() => _loadFirst(keepItems: true);

  Future<void> _loadFirst({bool keepItems = false}) async {
    final epoch = ++_epoch;
    _cancel?.cancel();
    _page = 1;
    state = state.copyWith(
      pieces: keepItems
          ? state.pieces.copyWith(isRefreshing: true)
          : const PaginatedListState(isInitialLoading: true),
    );
    final result = await _fetch(1);
    if (!ref.mounted) return;
    if (epoch != _epoch) return;
    state = switch (result) {
      Success(value: final r) => JewelryPremiumState(
        pieces: PaginatedListState(
          items: r.items,
          hasMore: r.hasMore && r.items.isNotEmpty,
          totalCount: r.total,
        ),
        thresholdInr: r.available ? r.thresholdInr : null,
        categories: r.categories,
        available: r.available,
      ),
      ResultFailure(failure: final f) => state.copyWith(
        pieces: PaginatedListState(errorMessage: f.message),
      ),
    };
  }

  Future<void> loadNextPage() async {
    final current = state.pieces;
    if (!current.hasMore ||
        current.isLoadingMore ||
        current.isInitialLoading ||
        current.isRefreshing) {
      return;
    }
    final epoch = _epoch;
    state = state.copyWith(pieces: current.copyWith(isLoadingMore: true));
    final result = await _fetch(_page + 1);
    if (!ref.mounted) return;
    if (epoch != _epoch) return;
    switch (result) {
      case Success(value: final r):
        _page++;
        state = state.copyWith(
          pieces: current.copyWith(
            items: [...current.items, ...r.items],
            hasMore: r.hasMore && r.items.isNotEmpty,
            totalCount: r.total,
            isLoadingMore: false,
          ),
          thresholdInr: r.available ? r.thresholdInr : null,
        );
      case ResultFailure(failure: final f):
        state = state.copyWith(
          pieces: current.copyWith(
            isLoadingMore: false,
            errorMessage: f.message,
          ),
        );
    }
  }

  Future<Result<JewelryPremiumPage, Failure>> _fetch(int page) {
    _cancel = CancelToken();
    return ref
        .read(jewelryRepositoryProvider)
        .getPremium(
          page: page,
          pageSize: JewelryPageSize.defaultSize,
          category: arg.category,
          sort: arg.sort,
          cancelToken: _cancel,
        );
  }
}
