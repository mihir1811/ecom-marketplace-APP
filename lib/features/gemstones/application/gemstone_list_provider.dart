import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/gemstone_repository_impl.dart';
import '../domain/models/gemstone.dart';
import 'gemstone_search_provider.dart';

enum GemstoneViewMode { grid, list }

class GemstoneListState {
  const GemstoneListState({
    this.gemstones = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isInitialLoading = false,
    this.errorMessage,
    this.totalCount = 0,
  });

  final List<Gemstone> gemstones;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final String? errorMessage;
  final int totalCount;

  GemstoneListState copyWith({
    List<Gemstone>? gemstones,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? errorMessage,
    int? totalCount,
  }) {
    return GemstoneListState(
      gemstones: gemstones ?? this.gemstones,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final gemstoneViewModeProvider =
    StateProvider<GemstoneViewMode>((ref) => GemstoneViewMode.grid);

final gemstoneListProvider =
    AsyncNotifierProvider<GemstoneListNotifier, GemstoneListState>(
  GemstoneListNotifier.new,
);

class GemstoneListNotifier extends AsyncNotifier<GemstoneListState> {
  int _page = 1;

  @override
  GemstoneListState build() {
    _page = 1;
    _loadFirstPage();
    return const GemstoneListState(isInitialLoading: true);
  }

  Future<void> _loadFirstPage() async {
    _page = 1;
    final filters = ref.read(gemstoneSearchProvider);
    final repo = ref.read(gemstoneRepositoryProvider);
    state = const AsyncData(GemstoneListState(isInitialLoading: true));

    final result = await repo.getGemstones(filters: filters, page: 1);
    state = AsyncData(switch (result) {
      Success(:final value) => GemstoneListState(
          gemstones: value.gemstones,
          hasMore: value.hasMore,
          totalCount: value.totalCount,
        ),
      ResultFailure(:final failure) => GemstoneListState(
          errorMessage: failure.message,
        ),
    });
  }

  Future<void> refresh() => _loadFirstPage();

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.isInitialLoading) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    _page++;
    final filters = ref.read(gemstoneSearchProvider);
    final result = await ref
        .read(gemstoneRepositoryProvider)
        .getGemstones(filters: filters, page: _page);

    final base = state.valueOrNull ?? current;
    state = AsyncData(switch (result) {
      Success(:final value) => base.copyWith(
          gemstones: [...base.gemstones, ...value.gemstones],
          hasMore: value.hasMore,
          isLoadingMore: false,
          totalCount: value.totalCount,
        ),
      ResultFailure(:final failure) => base.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        ),
    });
  }
}
