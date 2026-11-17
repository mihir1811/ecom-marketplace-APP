import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../data/repositories/jewelry_repository_impl.dart';
import '../domain/models/jewelry.dart';
import '../domain/models/jewelry_filter_state.dart';

/// Pieces shown in one jewelry home rail.
const jewelryHomeRailSize = 10;

/// First pieces across every collection for one home rail ("New arrivals"
/// is [JewelrySortOption.newest], "Bestsellers" is
/// [JewelrySortOption.popular]). An error or no pieces hides the rail.
final jewelryHomeRailProvider = FutureProvider.autoDispose
    .family<List<Jewelry>, JewelrySortOption>((ref, sort) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final result = await ref
          .watch(jewelryRepositoryProvider)
          .getJewelry(
            filters: const JewelryFilterState(),
            page: 1,
            pageSize: jewelryHomeRailSize,
            sort: sort,
            cancelToken: cancel,
          );
      return switch (result) {
        Success(value: final response) => response.items,
        ResultFailure(failure: final failure) => throw failure,
      };
    });
