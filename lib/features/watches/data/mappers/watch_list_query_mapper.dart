import 'dart:convert';

import '../../domain/models/watch_filter_state.dart';
import '../../domain/repositories/watch_repository.dart';

/// Builds `GET /watch/all` query params from UI filter/sort state.
abstract final class WatchListQueryMapper {
  static Map<String, dynamic> toQuery({
    required WatchFilterState filters,
    required int page,
    int pageSize = WatchPageSize.defaultSize,
    WatchSortOption sort = WatchSortOption.featured,
    String? sellerId,
  }) {
    final query = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? WatchPageSize.defaultSize : pageSize,
    };

    final search = filters.searchQuery.trim();
    if (search.isNotEmpty) {
      query['search'] = search;
      query['searchBy'] = 'brand,model,stockNumber,referenceNumber';
    }

    final sortField = _sortField(sort);
    if (sortField != null) query['sort'] = sortField;

    final prismaFilters = _buildFilters(filters, sellerId: sellerId);
    if (prismaFilters.isNotEmpty) {
      query['filters'] = jsonEncode(prismaFilters);
    }

    return query;
  }

  static String? _sortField(WatchSortOption sort) {
    return switch (sort) {
      WatchSortOption.featured => '-createdAt',
      WatchSortOption.newest => '-createdAt',
      WatchSortOption.oldest => 'createdAt',
      WatchSortOption.priceLowToHigh => 'price',
      WatchSortOption.priceHighToLow => '-price',
      WatchSortOption.brandAz => 'brand',
      WatchSortOption.brandZa => '-brand',
    };
  }

  static Map<String, dynamic> _buildFilters(
    WatchFilterState f, {
    String? sellerId,
  }) {
    final filters = <String, dynamic>{};

    final sid = sellerId?.trim();
    if (sid != null && sid.isNotEmpty) {
      filters['sellerId'] = {'equals': sid};
    }

    final brands =
        f.brands.map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
    _putEqualsOrIn(filters, 'brand', brands);

    final models =
        f.models.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    _putEqualsOrIn(filters, 'model', models);

    final movements = f.movements
        .map(_mapMovementToApi)
        .whereType<String>()
        .toList();
    _putEqualsOrIn(filters, 'movementType', movements);

    final genders =
        f.genders.map(_mapGenderToApi).whereType<String>().toList();
    _putEqualsOrIn(filters, 'gender', genders);

    final conditions = f.conditions.map(_mapConditionToApi).whereType<String>().toList();
    _putEqualsOrIn(filters, 'condition', conditions);

    final availability = f.availabilityStatuses
        .map(_mapAvailabilityToApi)
        .whereType<String>()
        .toList();
    _putEqualsOrIn(filters, 'availabilityStatus', availability);

    final caseMaterials = f.caseMaterials
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    _putEqualsOrIn(filters, 'caseMaterial', caseMaterials);

    final dialColors =
        f.dialColors.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    _putEqualsOrIn(filters, 'dialColor', dialColors);

    final caseShapes =
        f.caseShapes.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    _putEqualsOrIn(filters, 'caseShape', caseShapes);

    final strapMaterials = f.strapMaterials
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    _putEqualsOrIn(filters, 'strapMaterial', strapMaterials);

    if (f.boxIncluded) filters['boxIncluded'] = {'equals': true};
    if (f.papersIncluded) filters['papersIncluded'] = {'equals': true};
    if (f.warrantyCardIncluded) {
      filters['warrantyCardIncluded'] = {'equals': true};
    }

    return filters;
  }

  static void _putEqualsOrIn(
    Map<String, dynamic> filters,
    String key,
    List<String> values,
  ) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      filters[key] = {'equals': values.first};
    } else {
      filters[key] = {'in': values};
    }
  }

  static String? _mapMovementToApi(String ui) {
    final v = ui.trim().toLowerCase();
    if (v.contains('automatic')) return 'AUTOMATIC';
    if (v.contains('manual')) return 'MANUAL';
    if (v.contains('quartz')) return 'QUARTZ';
    if (v.contains('spring')) return 'SPRING_DRIVE';
    if (v.contains('solar')) return 'SOLAR';
    if (v.contains('kinetic')) return 'KINETIC';
    return null;
  }

  static String? _mapGenderToApi(String ui) {
    return switch (ui.trim().toLowerCase()) {
      'women' || 'woman' => 'women',
      'men' || 'man' => 'men',
      'unisex' => 'unisex',
      'kids' || 'kid' => 'kids',
      _ => ui.trim().isEmpty ? null : ui.trim().toLowerCase(),
    };
  }

  static String? _mapAvailabilityToApi(String ui) {
    return switch (ui.trim().toLowerCase()) {
      'available' || 'yes' || 'in stock' => 'yes',
      'on hold' || 'hold' => 'hold',
      'memo' => 'memo',
      _ => null,
    };
  }

  static String? _mapConditionToApi(String ui) {
    final v = ui.trim().toLowerCase();
    if (v.startsWith('new')) return 'New';
    return ui.trim().isEmpty ? null : ui.trim();
  }
}
