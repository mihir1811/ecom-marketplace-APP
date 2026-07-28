import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/diamond_repository_impl.dart';
import '../domain/models/diamond.dart';
import '../domain/models/diamond_catalog_type.dart';
import '../domain/models/sorting_criteria.dart';
import 'diamond_search_provider.dart';

enum ViewMode { grid, list }

/// Holds the active multi-criteria sorting configuration.
/// Empty list means no sorting applied (default order).
final diamondSortingProvider = StateProvider<List<SortingCriteria>>((ref) => []);

typedef DiamondListState = PaginatedListState<Diamond>;

extension DiamondListStateX on DiamondListState {
  List<Diamond> get diamonds => items;
}

final diamondViewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);

final diamondListProvider =
    AsyncNotifierProvider<DiamondListNotifier, DiamondListState>(
  DiamondListNotifier.new,
);

class DiamondListNotifier extends PaginatedAsyncNotifier<Diamond> {
  @override
  Future<Result<PaginatedPage<Diamond>, Failure>> loadPage(int page) async {
    final filters = ref.read(diamondSearchProvider);
    final sorting = ref.read(diamondSortingProvider);
    final catalog = ref.read(diamondCatalogTypeProvider);
    final repo = ref.read(diamondRepositoryProvider);
    final result = await repo.getDiamonds(
      filters: filters,
      page: page,
      sorting: sorting,
      isLabGrown: catalog.isLabGrown,
    );
    return switch (result) {
      Success(value: final response) => Success(
          PaginatedPage<Diamond>(
            items: response.diamonds,
            hasMore: response.hasMore,
            totalCount: response.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<void> applyFiltersAndSort() async {
    await loadFirstPage();
  }
}
