import '../../domain/models/rough_filter_state.dart';
import '../../domain/models/rough_sort_option.dart';

/// Builds the POST /rough-diamond/search body like the website: empty
/// lists, false flags, blank strings and unset bounds are left out.
abstract final class RoughSearchRequestMapper {
  static Map<String, dynamic> toBody({
    required RoughFilterState filters,
    required int page,
    required int pageSize,
    required RoughSortOption sort,
    String? sellerId,
    bool allTypes = false,
  }) {
    final body = <String, dynamic>{
      if (!allTypes) 'diamondType': filters.diamondType.query,
      'sort': sort.apiValue,
      'page': page < 1 ? 1 : page,
      'limit': pageSize.clamp(1, 200),
    };
    filters.lists.forEach((key, values) {
      final list = [
        for (final v in values)
          if (v.trim().isNotEmpty) v.trim(),
      ];
      if (list.isNotEmpty) body[key] = list.take(100).toList();
    });
    for (final flag in filters.flags) {
      body[flag] = true;
    }
    filters.ranges.forEach((range, bounds) {
      final (min, max) = bounds;
      if (min > 0) body['${range.apiPrefix}Min'] = min;
      if (max > 0) body['${range.apiPrefix}Max'] = max;
    });
    if (filters.yieldMin > 0) body['yieldMin'] = filters.yieldMin;
    final search = filters.search.trim();
    if (search.isNotEmpty) {
      body['search'] = search.length > 100 ? search.substring(0, 100) : search;
    }
    final seller = sellerId?.trim();
    if (seller != null && seller.isNotEmpty) body['sellerId'] = seller;
    return body;
  }
}
