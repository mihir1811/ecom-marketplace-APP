import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/jewelry_review_repository.dart';
import '../domain/models/jewelry_review.dart';

/// A review list: a piece's or shop's public list ([source] set), or the
/// signed-in shop's own list ([source] null, [slug] empty).
typedef JewelryReviewListKey = ({JewelryReviewSource? source, String slug});

class JewelryReviewListState {
  const JewelryReviewListState({
    this.summary = JewelryReviewSummary.empty,
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.rating,
    this.sort = JewelryReviewSort.newest,
    this.show = JewelrySellerReviewShow.all,
  });

  /// From the latest page; always every visible review.
  final JewelryReviewSummary summary;
  final List<JewelryReview> items;
  final int page;
  final int total;
  final bool loading;
  final bool loadingMore;
  final Failure? error;
  final int? rating;
  final JewelryReviewSort sort;
  final JewelrySellerReviewShow show;

  bool get hasMore => page * JewelryReviewRules.pageSize < total;

  JewelryReviewListState copyWith({
    JewelryReviewSummary? summary,
    List<JewelryReview>? items,
    int? page,
    int? total,
    bool? loading,
    bool? loadingMore,
    Failure? error,
    bool clearError = false,
    int? rating,
    bool clearRating = false,
    JewelryReviewSort? sort,
    JewelrySellerReviewShow? show,
  }) => JewelryReviewListState(
    summary: summary ?? this.summary,
    items: items ?? this.items,
    page: page ?? this.page,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : (error ?? this.error),
    rating: clearRating ? null : (rating ?? this.rating),
    sort: sort ?? this.sort,
    show: show ?? this.show,
  );
}

final jewelryReviewListProvider = NotifierProvider.autoDispose
    .family<
      JewelryReviewListNotifier,
      JewelryReviewListState,
      JewelryReviewListKey
    >(JewelryReviewListNotifier.new);

/// Pages through a review list. Changing the star filter, sort or "show"
/// starts again at page 1; "Show more" appends the next page.
class JewelryReviewListNotifier
    extends
        AutoDisposeFamilyNotifier<
          JewelryReviewListState,
          JewelryReviewListKey
        > {
  int _epoch = 0;

  @override
  JewelryReviewListState build(JewelryReviewListKey key) {
    ref.onDispose(() => _epoch++);
    Future.microtask(() => _load(1));
    return const JewelryReviewListState();
  }

  JewelryReviewRepository get _repo =>
      ref.read(jewelryReviewRepositoryProvider);

  Future<Result<JewelryReviewPage, Failure>> _fetch(int page) {
    final s = state;
    final source = arg.source;
    if (source == null) {
      return _repo.sellerList(
        page: page,
        rating: s.rating,
        sort: s.sort,
        show: s.show,
      );
    }
    return _repo.list(
      source: source,
      slug: arg.slug,
      page: page,
      rating: s.rating,
      sort: s.sort,
    );
  }

  Future<void> _load(int page) async {
    final epoch = ++_epoch;
    final result = await _fetch(page);
    if (epoch != _epoch) return;
    state = switch (result) {
      Success(value: final p) => state.copyWith(
        summary: p.summary,
        items: page == 1 ? p.items : [...state.items, ...p.items],
        page: p.page,
        total: p.total,
        loading: false,
        loadingMore: false,
        clearError: true,
      ),
      ResultFailure(:final failure) => state.copyWith(
        loading: false,
        loadingMore: false,
        error: failure,
      ),
    };
  }

  Future<void> refresh() {
    state = state.copyWith(loading: state.items.isEmpty, clearError: true);
    return _load(1);
  }

  /// Tapping the selected bar again clears the filter.
  void setRating(int? rating) {
    final next = rating == state.rating ? null : rating;
    state = state.copyWith(
      rating: next,
      clearRating: next == null,
      loading: true,
      clearError: true,
    );
    _load(1);
  }

  void setSort(JewelryReviewSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort, loading: true, clearError: true);
    _load(1);
  }

  void setShow(JewelrySellerReviewShow show) {
    if (show == state.show) return;
    state = state.copyWith(show: show, loading: true, clearError: true);
    _load(1);
  }

  void loadMore() {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    _load(state.page + 1);
  }

  /// Puts an updated review (e.g. after a reply) in place.
  void replace(JewelryReview review) {
    state = state.copyWith(
      items: [for (final r in state.items) r.id == review.id ? review : r],
    );
  }
}

/// Reviews the buyer just wrote or changed, by order line id. The order
/// screen shows these over the loaded order, so it needs no reload.
final jewelryOwnReviewOverridesProvider =
    StateProvider<Map<String, JewelryOwnReview>>((ref) => const {});

/// The seller dashboard's review card (Reviews badge = `unanswered`).
final jewelrySellerReviewStatsProvider =
    FutureProvider.autoDispose<JewelrySellerReviewStats?>((ref) async {
      final result = await ref
          .read(jewelryReviewRepositoryProvider)
          .sellerStats();
      return switch (result) {
        Success(:final value) => value,
        ResultFailure() => null,
      };
    });
