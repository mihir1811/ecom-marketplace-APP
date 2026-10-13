import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../data/repositories/diamond_project_repository_impl.dart';
import '../domain/diamond_project_stats_calculator.dart';
import '../domain/models/diamond_project.dart';
import 'diamond_project_list_provider.dart';
import 'diamond_project_selection_provider.dart';

/// Saves the in-memory selection as a diamond project (create or update).
class DiamondProjectSaveNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Result<DiamondProject, Failure>> save() async {
    final selection = ref.read(diamondProjectSelectionProvider);
    if (selection.items.isEmpty) {
      const failure = ValidationFailure('Select diamonds before saving.');
      state = const AsyncError(failure, StackTrace.empty);
      return Result.failure(failure);
    }

    state = const AsyncLoading();
    final stats = ref.read(diamondProjectStatsProvider);
    final repo = ref.read(diamondProjectRepositoryProvider);
    final id = selection.projectId;
    final result = id != null && id.isNotEmpty
        ? await repo.update(
            id: id,
            name: selection.name,
            diamondType: selection.diamondType,
            filters: selection.filters,
            analytics: DiamondProjectStatsCalculator.toAnalytics(stats),
            items: selection.items,
          )
        : await repo.upsert(
            name: selection.name,
            diamondType: selection.diamondType,
            filters: selection.filters,
            analytics: DiamondProjectStatsCalculator.toAnalytics(stats),
            items: selection.items,
          );

    switch (result) {
      case Success(value: final project):
        ref.read(diamondProjectSelectionProvider.notifier).markSaved(project);
        ref.invalidate(diamondProjectListProvider);
        state = const AsyncData(null);
      case ResultFailure(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
    }
    return result;
  }
}

final diamondProjectSaveProvider =
    AutoDisposeAsyncNotifierProvider<DiamondProjectSaveNotifier, void>(
      DiamondProjectSaveNotifier.new,
    );
