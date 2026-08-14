import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/jewellery_category_admin.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/repositories/jewelry_repository.dart';
import '../mappers/jewellery_category_admin_mapper.dart';
import '../mappers/jewelry_list_query_mapper.dart';
import '../mappers/jewelry_mapper.dart';
import '../models/jewelry_dto.dart';

final jewelryRepositoryProvider = Provider<JewelryRepository>(
  (ref) => JewelryRepositoryImpl(ref.watch(dioProvider)),
);

/// Live jewellery listing repository backed by `GET /jewellery`.
class JewelryRepositoryImpl implements JewelryRepository {
  JewelryRepositoryImpl(this._dio);

  final Dio _dio;

  /// Cached from `GET /jewellery-categories` for subcategoryId resolution.
  List<_JewelryCategoryRef>? _categoriesCache;

  @override
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption sort = JewelrySortOption.featured,
    CancelToken? cancelToken,
  }) async {
    try {
      final limit = pageSize < 1 ? JewelryPageSize.defaultSize : pageSize;
      final subcategoryIds = await _resolveSubcategoryIds(
        filters,
        cancelToken: cancelToken,
      );

      final query = JewelryListQueryMapper.toQuery(
        filters: filters,
        page: page,
        pageSize: limit,
        sort: sort,
        subcategoryIds: subcategoryIds,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.jewellery,
        queryParameters: query,
        cancelToken: cancelToken,
      );

      final root = response.data ?? const <String, dynamic>{};
      final dataNode = root['data'];
      final payload = dataNode is Map<String, dynamic>
          ? dataNode
          : const <String, dynamic>{};
      final itemsJson = payload['data'];
      final metaJson = payload['meta'];
      final meta =
          metaJson is Map<String, dynamic> ? metaJson : const <String, dynamic>{};

      final list = itemsJson is List ? itemsJson : const [];
      final items = <Jewelry>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dto = JewelryDto.fromJson(item);
        if (dto.id.isEmpty) continue;
        items.add(JewelryMapper.toDomain(dto));
      }

      final total = _asInt(meta['total']) ?? items.length;
      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']);
      final hasMore = meta.containsKey('next')
          ? meta['next'] != null
          : (lastPage != null
              ? currentPage < lastPage
              : items.length >= limit);

      return Result.success(
        JewelryListResponse(
          items: items,
          totalCount: total,
          hasMore: hasMore,
          page: currentPage,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(NetworkFailure.fromDioException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// Maps UI category / subcategory selections to live `subcategoryId` values.
  Future<List<String>> _resolveSubcategoryIds(
    JewelryFilterState filters, {
    CancelToken? cancelToken,
  }) async {
    final category = filters.category;
    final hasCategory = category != null &&
        category.isNotEmpty &&
        category != 'All Accessories';
    final selectedSubs = filters.subCategories
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.toLowerCase().startsWith('all '))
        .toList();

    if (!hasCategory && selectedSubs.isEmpty) return const [];

    final categories = await _loadCategories(cancelToken: cancelToken);
    if (categories.isEmpty) return const [];

    final apiCategoryName =
        hasCategory ? JewelleryCategoryMatch.apiNameForUi(category) : null;
    final scoped = apiCategoryName == null
        ? categories
        : categories
            .where(
              (c) => c.name.toLowerCase() == apiCategoryName.toLowerCase(),
            )
            .toList();

    if (scoped.isEmpty) return const [];

    if (selectedSubs.isEmpty) {
      // Whole parent category → all of its subcategory IDs.
      return scoped.expand((c) => c.subcategories.map((s) => s.id)).toList();
    }

    final ids = <String>{};
    for (final uiName in selectedSubs) {
      for (final cat in scoped) {
        for (final sub in cat.subcategories) {
          if (_subcategoryMatches(uiName, sub.name)) {
            ids.add(sub.id);
          }
        }
      }
    }
    return ids.toList();
  }

  Future<List<_JewelryCategoryRef>> _loadCategories({
    CancelToken? cancelToken,
  }) async {
    final cached = _categoriesCache;
    if (cached != null) return cached;

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.jewelleryCategories,
      queryParameters: const {'page': 1, 'limit': 50},
      cancelToken: cancelToken,
    );
    final page = JewelleryCategoryAdminMapper.listPageFromJson(
      response.data,
      page: 1,
      limit: 50,
    );

    final parsed = <_JewelryCategoryRef>[
      for (final category in page.items)
        if (category.isActive &&
            category.id.isNotEmpty &&
            category.name.trim().isNotEmpty)
          _JewelryCategoryRef(
            id: category.id,
            name: category.name,
            subcategories: [
              for (final sub in category.subcategories)
                if (sub.isActive &&
                    sub.id.isNotEmpty &&
                    sub.name.trim().isNotEmpty)
                  _JewelrySubcategoryRef(id: sub.id, name: sub.name),
            ],
          ),
    ];

    _categoriesCache = parsed;
    return parsed;
  }

  /// Matches UI chip labels like "Engagement" / "Drop Earrings" to API names.
  static bool _subcategoryMatches(String uiName, String apiName) {
    final a = uiName.trim().toLowerCase();
    final b = apiName.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    if (b.startsWith(a) || a.startsWith(b)) return true;
    // "Drop Earrings" ↔ "Drop Earring"
    final aSingular = a.endsWith('s') ? a.substring(0, a.length - 1) : a;
    final bSingular = b.endsWith('s') ? b.substring(0, b.length - 1) : b;
    return aSingular == bSingular ||
        bSingular.startsWith(aSingular) ||
        aSingular.startsWith(bSingular);
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class _JewelryCategoryRef {
  const _JewelryCategoryRef({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final String id;
  final String name;
  final List<_JewelrySubcategoryRef> subcategories;
}

class _JewelrySubcategoryRef {
  const _JewelrySubcategoryRef({required this.id, required this.name});

  final String id;
  final String name;
}
