import 'dart:convert';

import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/repositories/jewelry_repository.dart';

/// Builds `GET /jewellery` query params from UI filter/sort state.
abstract final class JewelryListQueryMapper {
  static Map<String, dynamic> toQuery({
    required JewelryFilterState filters,
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption sort = JewelrySortOption.featured,
  }) {
    final query = <String, dynamic>{
      'page': page < 1 ? 1 : page,
      'limit': pageSize < 1 ? JewelryPageSize.defaultSize : pageSize,
    };

    final search = filters.searchQuery.trim();
    if (search.isNotEmpty) {
      query['search'] = search;
      query['searchBy'] = 'productTitle,stockNumber';
    }

    final sortField = _sortField(sort);
    if (sortField != null) query['sort'] = sortField;

    final prismaFilters = _buildFilters(filters);
    if (prismaFilters.isNotEmpty) {
      query['filters'] = jsonEncode(prismaFilters);
    }

    return query;
  }

  static String? _sortField(JewelrySortOption sort) {
    return switch (sort) {
      JewelrySortOption.newest => '-createdAt',
      JewelrySortOption.featured => '-createdAt',
      JewelrySortOption.priceLowToHigh => 'createdAt',
      JewelrySortOption.priceHighToLow => '-createdAt',
      JewelrySortOption.popularity ||
      JewelrySortOption.bestSelling ||
      JewelrySortOption.highestRated ||
      JewelrySortOption.discount =>
        '-createdAt',
    };
  }

  static Map<String, dynamic> _buildFilters(JewelryFilterState f) {
    final filters = <String, dynamic>{};

    final category = f.category;
    if (category != null &&
        category.isNotEmpty &&
        category != 'All Accessories') {
      final apiCategory = _mapCategoryToApi(category);
      if (apiCategory != null) {
        filters['subcategory'] = {
          'category': {
            'name': {'equals': apiCategory},
          },
        };
      }
    }

    if (f.subCategories.isNotEmpty) {
      final names = f.subCategories
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && !s.toLowerCase().startsWith('all '))
          .toList();
      if (names.length == 1) {
        filters['subcategory'] = {
          ...(filters['subcategory'] as Map<String, dynamic>? ?? {}),
          'name': {'equals': names.first},
        };
      } else if (names.length > 1) {
        filters['subcategory'] = {
          ...(filters['subcategory'] as Map<String, dynamic>? ?? {}),
          'name': {'in': names},
        };
      }
    }

    final genders = f.genders
        .map(_mapGenderToApi)
        .whereType<String>()
        .toList();
    _putEqualsOrIn(filters, 'gender', genders);

    final occasions = f.occasions
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();
    _putEqualsOrIn(filters, 'occasion', occasions);

    final variantSome = <String, dynamic>{};

    final availability = f.availability
        .map(_mapAvailabilityToApi)
        .whereType<String>()
        .toList();
    if (availability.length == 1) {
      variantSome['available'] = {'equals': availability.first};
    } else if (availability.length > 1) {
      variantSome['available'] = {'in': availability};
    }

    final metalColors = f.metalColors
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (metalColors.length == 1) {
      variantSome['metalColor'] = {'equals': metalColors.first};
    } else if (metalColors.length > 1) {
      variantSome['metalColor'] = {'in': metalColors};
    }

    final metalTypes = f.metalTypes
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (metalTypes.length == 1) {
      variantSome['metalType'] = {'equals': metalTypes.first};
    } else if (metalTypes.length > 1) {
      variantSome['metalType'] = {'in': metalTypes};
    }

    final metalPurities = f.metalPurities
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map(_normalizePurity)
        .toList();
    if (metalPurities.length == 1) {
      variantSome['metalPurity'] = {'equals': metalPurities.first};
    } else if (metalPurities.length > 1) {
      variantSome['metalPurity'] = {'in': metalPurities};
    }

    if (variantSome.isNotEmpty) {
      filters['variants'] = {'some': variantSome};
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

  static String? _mapCategoryToApi(String ui) {
    return switch (ui.trim()) {
      'Rings' => 'Ring',
      'Earrings' => 'Earring',
      'Bracelets' => 'Bracelet',
      'Necklaces' => 'Necklace',
      'Chains' => 'Necklace',
      _ => null,
    };
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
      'in stock' || 'available' || 'yes' => 'yes',
      'on hold' || 'hold' => 'hold',
      'memo' => 'memo',
      _ => null,
    };
  }

  static String _normalizePurity(String purity) {
    // UI may use "950 Platinum"; API sample uses "18K" / "950".
    if (purity.contains('Platinum')) {
      return purity.replaceAll(RegExp(r'\s*Platinum'), '').trim();
    }
    if (purity.contains('Silver')) {
      return purity.replaceAll(RegExp(r'\s*Silver'), '').trim();
    }
    return purity;
  }
}
