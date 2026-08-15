import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/pagination/paginated_async_notifier.dart';
import '../../../core/pagination/paginated_list_state.dart';
import '../data/repositories/diamond_project_repository_impl.dart';
import '../domain/models/diamond_project.dart';

typedef DiamondProjectListState = PaginatedListState<DiamondProject>;

/// Paginated list of the signed-in seller's diamond projects.
class DiamondProjectListNotifier
    extends PaginatedAsyncNotifier<DiamondProject> {
  @override
  Iterable<ProviderListenable<Object?>> get reloadTriggers => const [];

  @override
  Future<Result<PaginatedPage<DiamondProject>, Failure>> loadPage(
    int page,
  ) async {
    final result = await ref.read(diamondProjectRepositoryProvider).listMine(
          page: page,
          limit: 20,
        );
    return switch (result) {
      Success(value: final pageData) => Success(
          PaginatedPage<DiamondProject>(
            items: pageData.projects,
            hasMore: pageData.hasMore,
            totalCount: pageData.totalCount,
          ),
        ),
      ResultFailure(failure: final failure) => ResultFailure(failure),
    };
  }

  Future<Result<DiamondProject, Failure>> fetchOne(String id) {
    return ref.read(diamondProjectRepositoryProvider).getOne(id);
  }

  Future<void> remove(String id) async {
    final result =
        await ref.read(diamondProjectRepositoryProvider).remove(id);
    if (result is ResultFailure<void, Failure>) {
      throw result.failure;
    }
    final current = state.valueOrNull;
    if (current == null) {
      await loadFirstPage();
      return;
    }
    state = AsyncData(
      current.copyWith(
        items: [
          for (final project in current.items)
            if (project.id != id) project,
        ],
        totalCount: (current.totalCount - 1).clamp(0, current.totalCount),
      ),
    );
  }
}

final diamondProjectListProvider = AsyncNotifierProvider<
    DiamondProjectListNotifier, DiamondProjectListState>(
  DiamondProjectListNotifier.new,
);
