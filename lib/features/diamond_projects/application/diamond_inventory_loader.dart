import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../diamonds/application/diamond_list_provider.dart';
import '../../diamonds/application/diamond_search_provider.dart';
import '../../diamonds/data/repositories/diamond_repository_impl.dart';
import '../../diamonds/domain/models/diamond.dart';
import '../../diamonds/domain/models/diamond_catalog_type.dart';

/// Every stone matching the listing's filters — the whole inventory, not
/// just the pages scrolled so far. Pages through the search in bulk, capped
/// like the seller dashboard's project inventory.
abstract final class DiamondInventoryLoader {
  static const int _pageSize = 100;
  static const int _maxPages = 50;

  static Future<Result<List<Diamond>, Failure>> loadAll(
    WidgetRef ref, {
    CancelToken? cancelToken,
  }) async {
    final listed = ref.read(diamondListProvider).value;
    if (listed != null && !listed.hasMore && !listed.isInitialLoading) {
      return Success(listed.diamonds);
    }

    final filters = ref.read(diamondSearchProvider);
    final catalog = ref.read(diamondCatalogTypeProvider);
    final sorting = ref.read(diamondSortingProvider);
    final repo = ref.read(diamondRepositoryProvider);

    final all = <Diamond>[];
    final seen = <String>{};
    for (var page = 1; page <= _maxPages; page++) {
      final result = await repo.getDiamonds(
        filters: filters,
        catalog: catalog,
        page: page,
        pageSize: _pageSize,
        sorting: sorting,
        cancelToken: cancelToken,
      );
      switch (result) {
        case Success(value: final response):
          for (final d in response.diamonds) {
            if (d.id.isNotEmpty && seen.add(d.id)) all.add(d);
          }
          if (!response.hasMore || response.diamonds.isEmpty) {
            return Success(all);
          }
        case ResultFailure(failure: final failure):
          return ResultFailure(failure);
      }
    }
    return Success(all);
  }
}
