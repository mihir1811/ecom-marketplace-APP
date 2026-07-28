import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../../../core/error/result.dart';
import '../data/repositories/gemstone_repository_impl.dart';
import '../domain/models/gemstone.dart';
import 'gemstone_search_provider.dart';

enum GemstoneViewMode { grid, list }

typedef GemstoneListState = PaginatedListState<Gemstone>;

extension GemstoneListStateX on GemstoneListState {
  List<Gemstone> get gemstones => items;
}

final gemstoneViewModeProvider =
    StateProvider<GemstoneViewMode>((ref) => GemstoneViewMode.grid);

final gemstoneListProvider =
    AsyncNotifierProvider<GemstoneListNotifier, GemstoneListState>(
  GemstoneListNotifier.new,
);

class GemstoneListNotifier extends PaginatedAsyncNotifier<Gemstone> {
  @override
  Future<Result<PaginatedPage<Gemstone>, Failure>> loadPage(int page) async {
    final filters = ref.read(gemstoneSearchProvider);
    final repo = ref.read(gemstoneRepositoryProvider);
    final result = await repo.getGemstones(filters: filters, page: page);
    return switch (result) {
      Success(:final value) => Success(
          PaginatedPage<Gemstone>(
            items: value.gemstones,
            hasMore: value.hasMore,
            totalCount: value.totalCount,
          ),
        ),
      ResultFailure(:final failure) => ResultFailure(failure),
    };
  }
}
