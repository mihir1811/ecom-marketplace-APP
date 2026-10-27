import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/repositories/jewelry_repository.dart';

/// Builds `GET /marketplace/listings` (and `/facets`) query params.
///
/// Multi-value filters are comma-separated; empty params are left out.
abstract final class JewelryListQueryMapper {
  static Map<String, dynamic> toQuery({
    required JewelryFilterState filters,
    int? page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption? sort,
  }) {
    final f = filters;
    String? csv(Set<String> values) {
      final cleaned = [
        for (final v in values)
          if (v.trim().isNotEmpty) v.trim(),
      ];
      return cleaned.isEmpty ? null : cleaned.join(',');
    }

    String? text(String? v, int max) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) return null;
      return t.length > max ? t.substring(0, max) : t;
    }

    final query = <String, dynamic>{
      if (page != null) 'page': page < 1 ? 1 : page,
      if (page != null) 'limit': pageSize.clamp(1, 100),
      'category': f.categorySlug,
      'search': text(f.searchQuery, 120),
      'shop': text(f.shop, 140),
      'tag': text(f.tag, 80),
      'metal': csv(f.metals),
      'gemstone': csv(f.gemstones),
      'origin': csv(f.origins),
      'style': csv(f.styles),
      'occasion': csv(f.occasions),
      'shape': csv(f.shapes),
      if (f.priceMin != null && f.priceMin! > 0)
        'minPrice': f.priceMin!.round(),
      if (f.priceMax != null) 'maxPrice': f.priceMax!.round(),
      'availability': f.availability,
      'sort': sort?.apiValue,
    }..removeWhere((_, v) => v == null);
    return query;
  }

  /// Facet counts only narrow by category, search, shop and tag.
  static Map<String, dynamic> toFacetQuery(JewelryFilterState filters) =>
      toQuery(
        filters: JewelryFilterState(
          searchQuery: filters.searchQuery,
          category: filters.category,
          subCategory: filters.subCategory,
          shop: filters.shop,
          tag: filters.tag,
        ),
      );
}
