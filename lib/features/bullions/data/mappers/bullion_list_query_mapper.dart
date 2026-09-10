import 'dart:convert';

import '../../domain/models/bullions_filter_state.dart';
import '../../domain/repositories/bullions_repository.dart';

/// Builds `GET /bullion/all` query params from UI filter/sort state.
abstract final class BullionListQueryMapper {
  static Map<String, dynamic> toQuery({
    required BullionsFilterState filters,
    required int page,
    int pageSize = BullionPageSize.defaultSize,
    BullionsSortOption sort = BullionsSortOption.featured,
    String? sellerId,
  }) {
    final query = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? BullionPageSize.defaultSize : pageSize,
      'sort': _sortField(sort),
    };

    final search = filters.searchQuery.trim();
    if (search.isNotEmpty) {
      query['search'] = search;
      query['searchBy'] = 'mintMark,stockNumber,design,certification';
    }

    final prismaFilters = _buildFilters(filters, sellerId: sellerId);
    if (prismaFilters.isNotEmpty) {
      query['filters'] = jsonEncode(prismaFilters);
    }

    return query;
  }

  /// Maps UI sort to API `sort` (`-` prefix = DESC).
  static String _sortField(BullionsSortOption sort) {
    return switch (sort) {
      BullionsSortOption.featured => '-createdAt',
      BullionsSortOption.newest => '-createdAt',
      BullionsSortOption.oldest => 'createdAt',
      BullionsSortOption.priceLowToHigh => 'price',
      BullionsSortOption.priceHighToLow => '-price',
      BullionsSortOption.weightLowToHigh => 'metalWeight',
      BullionsSortOption.weightHighToLow => '-metalWeight',
    };
  }

  static Map<String, dynamic> _buildFilters(
    BullionsFilterState f, {
    String? sellerId,
  }) {
    final filters = <String, dynamic>{};

    final sid = sellerId?.trim();
    if (sid != null && sid.isNotEmpty) {
      filters['sellerId'] = {'equals': sid};
    }

    final metal = f.metalFilter.metal;
    if (metal != null) {
      filters['metalType'] = {
        'name': {'equals': metal.name.toUpperCase()},
      };
    }

    final shapes = f.shapes
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (shapes.isNotEmpty) {
      if (shapes.length == 1) {
        filters['metalShape'] = {
          'name': {'equals': shapes.first},
        };
      } else {
        filters['metalShape'] = {
          'name': {'in': shapes},
        };
      }
    }

    final fineness = _mapVariantToFineness(f.selectedVariant);
    if (fineness != null) {
      filters['metalFineness'] = {
        'value': {'equals': fineness},
      };
    }

    final conditions = f.conditions
        .map(_mapConditionToApi)
        .whereType<String>()
        .toList();
    _putEqualsOrIn(filters, 'condition', conditions);

    final certifications = f.certifications
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    _putEqualsOrIn(filters, 'certification', certifications);

    final mintMarks =
        f.mintMarks.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    _putEqualsOrIn(filters, 'mintMark', mintMarks);

    _putRange(filters, 'price', f.priceMin, f.priceMax);
    _putRange(filters, 'metalWeight', f.weightMin, f.weightMax);
    _putRange(filters, 'quantity', f.quantityMin, f.quantityMax);

    final weightValues = f.weightChips
        .map(_mapWeightChip)
        .whereType<String>()
        .toList();
    if (weightValues.isNotEmpty && f.weightMin <= 0 && f.weightMax <= 0) {
      if (weightValues.length == 1) {
        filters['metalWeight'] = {'equals': weightValues.first};
      } else {
        filters['metalWeight'] = {'in': weightValues};
      }
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

  static void _putRange(
    Map<String, dynamic> filters,
    String key,
    double min,
    double max,
  ) {
    if (min <= 0 && max <= 0) return;
    final range = <String, dynamic>{};
    if (min > 0) range['gte'] = _numString(min);
    if (max > 0) range['lte'] = _numString(max);
    filters[key] = range;
  }

  static String _numString(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static String? _mapVariantToFineness(String? variant) {
    if (variant == null) return null;
    return switch (variant.trim().toUpperCase()) {
      '24K' => '999.9',
      '22K' => '916',
      '18K' => '750',
      '999' => '999',
      '999.9' => '999.9',
      '999.5' => '999.5',
      '950' => '950',
      '925' || 'STERLING' => '925',
      _ => variant.trim().isEmpty ? null : variant.trim(),
    };
  }

  static String? _mapConditionToApi(String ui) {
    final v = ui.trim().toLowerCase();
    if (v.isEmpty) return null;
    if (v == 'bu' || v.contains('brilliant')) return 'BU';
    if (v.startsWith('new')) return 'New';
    return ui.trim();
  }

  static String? _mapWeightChip(String chip) {
    return switch (chip.trim().toLowerCase()) {
      '1g' => '1',
      '5g' => '5',
      '10g' => '10',
      '1oz' || 'oz' => '31.103',
      _ => null,
    };
  }
}
