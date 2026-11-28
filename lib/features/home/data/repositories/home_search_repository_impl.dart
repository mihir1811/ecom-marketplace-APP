import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../bullions/data/mappers/bullion_mapper.dart';
import '../../../bullions/data/models/bullion_dto.dart';
import '../../../diamonds/data/mappers/diamond_mapper.dart';
import '../../../diamonds/data/models/diamond_dto.dart';
import '../../../gemstones/data/mappers/gemstone_mapper.dart';
import '../../../gemstones/data/models/gemstone_dto.dart';
import '../../../jewelry/data/mappers/jewelry_mapper.dart';
import '../../../jewelry/data/mappers/marketplace_json.dart';
import '../../../jewelry/data/mappers/marketplace_mapper.dart';
import '../../../product_detail/domain/adapters/bullion_product_detail.dart';
import '../../../product_detail/domain/adapters/rough_product_detail.dart';
import '../../../rough_diamonds/data/mappers/rough_search_request_mapper.dart';
import '../../../rough_diamonds/data/mappers/rough_parcel_mapper.dart';
import '../../../rough_diamonds/domain/models/rough_filter_state.dart';
import '../../../rough_diamonds/domain/models/rough_sort_option.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/domain/adapters/gemstone_product_detail.dart';
import '../../../product_detail/domain/adapters/jewelry_product_detail.dart';
import '../../../product_detail/domain/adapters/watch_product_detail.dart';
import '../../../watches/data/mappers/watch_mapper.dart';
import '../../../watches/data/models/watch_dto.dart';
import '../../domain/home_search_query_classifier.dart';
import '../../domain/home_search_relevance.dart';
import '../../domain/home_search_spelling.dart';
import '../../domain/models/home_search_result.dart';
import '../../domain/repositories/home_search_repository.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../../diamonds/domain/models/diamond_filter_state.dart';
import '../../../diamonds/data/mappers/diamond_search_request_mapper.dart';
import '../../../gemstones/domain/models/gemstone_filter_state.dart';
import '../../../gemstones/data/mappers/gemstone_search_request_mapper.dart';

final homeSearchRepositoryProvider = Provider<HomeSearchRepository>(
  (ref) => HomeSearchRepositoryImpl(ref.watch(dioProvider)),
);

class _CatalogBatch {
  const _CatalogBatch({
    required this.items,
    required this.hasMore,
    required this.total,
  });

  final List<HomeSearchResult> items;
  final bool hasMore;
  final int total;

  static const empty = _CatalogBatch(items: [], hasMore: false, total: 0);
}

/// Client-side global search — mirrors web `useLiveSearchResults` fan-out.
///
/// Fetches one `page`/`limit` from each catalog API in parallel, then merges
/// and ranks. Infinite scroll advances [page] — never loads the full catalog.
class HomeSearchRepositoryImpl implements HomeSearchRepository {
  const HomeSearchRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<HomeSearchPage, Failure>> search(
    String query, {
    required int page,
    int pageSize = HomeSearchPageSize.defaultSize,
    bool forceSimilar = false,
    CancelToken? cancelToken,
  }) async {
    final original = query.trim();
    final safePage = page < 1 ? 1 : page;
    final limit = pageSize < 1 ? HomeSearchPageSize.defaultSize : pageSize;

    if (original.length < 2) {
      return Result.success(
        HomeSearchPage(
          items: const [],
          hasMore: false,
          totalCount: 0,
          page: safePage,
        ),
      );
    }

    try {
      final corrected = HomeSearchSpelling.correct(original);
      final spellingChanged = HomeSearchSpelling.didChange(original, corrected);
      final effectiveQuery = corrected;
      final targetCarat =
          HomeSearchCaratParser.parse(original) ??
          HomeSearchCaratParser.parse(corrected);

      // Pagination continuation after an approximate first page.
      if (forceSimilar && targetCarat != null) {
        final similar = await _caratRangeSearch(
          targetCarat: targetCarat,
          range: HomeSearchCaratParser.nearbyRange(targetCarat),
          maxDistance: 0.35,
          page: safePage,
          limit: limit,
          cancelToken: cancelToken,
        );
        return Result.success(
          HomeSearchPage(
            items: similar.items,
            hasMore: similar.hasMore,
            totalCount: similar.total,
            page: safePage,
            isApproximate: true,
            correctedQuery: spellingChanged ? corrected : null,
            notice:
                'No exact results for “$original”, but similar carat weights are available.',
          ),
        );
      }

      final caratDominant =
          targetCarat != null &&
          (HomeSearchCaratParser.isCaratDominant(original) ||
              HomeSearchCaratParser.isCaratDominant(corrected));

      // Free-text list APIs do not understand "5 carat" — always accompany
      // carat intent with structured POST carat filters.
      final textBatch = caratDominant
          ? _CatalogBatch.empty
          : await _fanOut(
              effectiveQuery,
              page: safePage,
              limit: limit,
              cancelToken: cancelToken,
              rankQuery: effectiveQuery,
              // Mixed carat queries should not drop API hits on text mismatch.
              requireTextMatch: targetCarat == null,
            );

      _CatalogBatch caratBatch = _CatalogBatch.empty;
      if (targetCarat != null) {
        caratBatch = await _caratRangeSearch(
          targetCarat: targetCarat,
          range: HomeSearchCaratParser.nearbyRange(targetCarat),
          maxDistance: 0.35,
          page: safePage,
          limit: limit,
          cancelToken: cancelToken,
        );
      }

      final merged = _dedupeResults([...textBatch.items, ...caratBatch.items]);
      final hasMore = textBatch.hasMore || caratBatch.hasMore;
      final totalCount = textBatch.total + caratBatch.total;

      if (merged.isEmpty) {
        return Result.success(
          HomeSearchPage(
            items: const [],
            hasMore: false,
            totalCount: 0,
            page: safePage,
            correctedQuery: spellingChanged ? corrected : null,
            notice: spellingChanged
                ? 'No results found for “$original” (tried “$corrected”).'
                : null,
          ),
        );
      }

      if (targetCarat != null) {
        final exactHits = <HomeSearchResult>[];
        final nearHits = <HomeSearchResult>[];
        final textOnlyHits = <HomeSearchResult>[];

        for (final item in merged) {
          final distance = _caratDistance(item, targetCarat);
          if (distance < 900) {
            if (HomeSearchCaratParser.isExactMatch(distance)) {
              exactHits.add(item);
            } else if (distance <= 0.35) {
              nearHits.add(item);
            }
          } else if (!caratDominant) {
            // Mixed query (e.g. brand + carat): keep text matches without carat.
            textOnlyHits.add(item);
          }
        }

        if (exactHits.isNotEmpty) {
          exactHits.sort((a, b) {
            final da = _caratDistance(a, targetCarat);
            final db = _caratDistance(b, targetCarat);
            final byCarat = da.compareTo(db);
            if (byCarat != 0) return byCarat;
            return a.title.compareTo(b.title);
          });
          return Result.success(
            HomeSearchPage(
              items: [...exactHits, ...textOnlyHits],
              hasMore: hasMore,
              totalCount: totalCount,
              page: safePage,
              correctedQuery: spellingChanged ? corrected : null,
              notice: spellingChanged
                  ? 'Showing results for “$corrected”.'
                  : null,
            ),
          );
        }

        if (nearHits.isNotEmpty) {
          nearHits.sort((a, b) {
            final da = _caratDistance(a, targetCarat);
            final db = _caratDistance(b, targetCarat);
            return da.compareTo(db);
          });
          return Result.success(
            HomeSearchPage(
              items: nearHits,
              hasMore: hasMore,
              totalCount: totalCount,
              page: safePage,
              isApproximate: true,
              correctedQuery: spellingChanged ? corrected : null,
              notice:
                  'No results found for “$original”, but similar items are available.',
            ),
          );
        }

        if (textOnlyHits.isNotEmpty) {
          return Result.success(
            HomeSearchPage(
              items: textOnlyHits,
              hasMore: hasMore,
              totalCount: totalCount,
              page: safePage,
              correctedQuery: spellingChanged ? corrected : null,
              notice: spellingChanged
                  ? 'Showing results for “$corrected”.'
                  : null,
            ),
          );
        }

        return Result.success(
          HomeSearchPage(
            items: const [],
            hasMore: false,
            totalCount: 0,
            page: safePage,
            correctedQuery: spellingChanged ? corrected : null,
            notice: spellingChanged
                ? 'No results found for “$original” (tried “$corrected”).'
                : null,
          ),
        );
      }

      return Result.success(
        HomeSearchPage(
          items: merged,
          hasMore: hasMore,
          totalCount: totalCount,
          page: safePage,
          correctedQuery: spellingChanged ? corrected : null,
          notice: spellingChanged ? 'Showing results for “$corrected”.' : null,
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || e.type == DioExceptionType.cancel) {
        return Result.failure(NetworkFailure.cancelled);
      }
      return Result.failure(NetworkFailure.fromDioException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<_CatalogBatch> _fanOut(
    String query, {
    required int page,
    required int limit,
    required String rankQuery,
    bool requireTextMatch = true,
    CancelToken? cancelToken,
  }) async {
    final mode = HomeSearchQueryClassifier.classify(query);
    final tasks = <Future<_CatalogBatch>>[
      _safe(() => _searchDiamonds(query, mode, page, limit, cancelToken)),
      _safe(() => _searchMelee(query, mode, page, limit, cancelToken)),
      _safe(() => _searchGemstones(query, mode, page, limit, cancelToken)),
      _safe(() => _searchWatches(query, mode, page, limit, cancelToken)),
      _safe(() => _searchJewelry(query, mode, page, limit, cancelToken)),
      _safe(() => _searchBullions(query, mode, page, limit, cancelToken)),
      _safe(() => _searchRough(query, page, limit, cancelToken)),
    ];

    final batches = await Future.wait(tasks);
    final merged = <HomeSearchResult>[];
    var hasMore = false;
    var totalCount = 0;

    for (final batch in batches) {
      merged.addAll(batch.items);
      hasMore = hasMore || batch.hasMore;
      totalCount += batch.total;
    }

    final ranked = HomeSearchRelevance.sort(
      merged,
      rankQuery,
      requireTextMatch: requireTextMatch && mode == HomeSearchMode.freeText,
    );

    final items = ranked.isNotEmpty || merged.isEmpty
        ? ranked
        : HomeSearchRelevance.sort(merged, rankQuery, requireTextMatch: false);

    return _CatalogBatch(items: items, hasMore: hasMore, total: totalCount);
  }

  Future<_CatalogBatch> _caratRangeSearch({
    required double targetCarat,
    required (double, double) range,
    required double maxDistance,
    required int page,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    final tasks = <Future<_CatalogBatch>>[
      _safe(
        () => _postDiamondCarat(
          targetCarat: targetCarat,
          minCarat: range.$1,
          maxCarat: range.$2,
          maxDistance: maxDistance,
          catalog: DiamondCatalogType.natural,
          page: page,
          limit: limit,
          cancelToken: cancelToken,
        ),
      ),
      _safe(
        () => _postDiamondCarat(
          targetCarat: targetCarat,
          minCarat: range.$1,
          maxCarat: range.$2,
          maxDistance: maxDistance,
          catalog: DiamondCatalogType.labGrown,
          page: page,
          limit: limit,
          cancelToken: cancelToken,
        ),
      ),
      _safe(
        () => _postGemstoneCarat(
          targetCarat: targetCarat,
          minCarat: range.$1,
          maxCarat: range.$2,
          maxDistance: maxDistance,
          page: page,
          limit: limit,
          cancelToken: cancelToken,
        ),
      ),
    ];

    final batches = await Future.wait(tasks);
    final merged = <HomeSearchResult>[];
    var hasMore = false;
    var totalCount = 0;
    for (final batch in batches) {
      merged.addAll(batch.items);
      hasMore = hasMore || batch.hasMore;
      totalCount += batch.total;
    }

    merged.sort((a, b) {
      final da = _caratDistance(a, targetCarat);
      final db = _caratDistance(b, targetCarat);
      return da.compareTo(db);
    });

    return _CatalogBatch(items: merged, hasMore: hasMore, total: totalCount);
  }

  Future<_CatalogBatch> _postDiamondCarat({
    required double targetCarat,
    required double minCarat,
    required double maxCarat,
    required double maxDistance,
    required DiamondCatalogType catalog,
    required int page,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    final body = DiamondSearchRequestMapper.toBody(
      filters: DiamondFilterState(minCarat: minCarat, maxCarat: maxCarat),
      catalog: catalog,
      page: page,
      pageSize: limit,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.diamondSearch,
      data: body,
      cancelToken: cancelToken,
    );
    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final items = _mapDiamonds(parsed.items, isMelee: false)
        .where((item) => _caratDistance(item, targetCarat) <= maxDistance)
        .toList(growable: false);
    return _CatalogBatch(
      items: items,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  Future<_CatalogBatch> _postGemstoneCarat({
    required double targetCarat,
    required double minCarat,
    required double maxCarat,
    required double maxDistance,
    required int page,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    final body = GemstoneSearchRequestMapper.toBody(
      filters: GemstoneFilterState(
        minTotalCarat: minCarat,
        maxTotalCarat: maxCarat,
      ),
      page: page,
      pageSize: limit,
    );
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.gemStoneSearch,
      data: body,
      cancelToken: cancelToken,
    );
    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final out = <HomeSearchResult>[];
    for (final item in parsed.items) {
      final dto = GemstoneDto.fromJson(item);
      if (dto.id.isEmpty) continue;
      final g = GemstoneMapper.toDomain(dto);
      if ((g.carat - targetCarat).abs() > maxDistance) continue;
      out.add(
        HomeSearchResult(
          id: g.id,
          title: g.type,
          subtitle: [
            if (g.carat > 0) '${formatDecimal(g.carat)}ct',
            if (g.color.isNotEmpty) g.color,
            if (g.shape.isNotEmpty) g.shape,
            if (g.stockNumber != null && g.stockNumber!.isNotEmpty)
              g.stockNumber!,
          ].join(' · '),
          categoryLabel: 'Gemstone',
          priceLabel: _usd(g.price),
          kind: HomeSearchKind.gemstone,
          imageUrl: g.imageUrl,
          detail: gemstoneProductDetail(g),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  static double _caratDistance(HomeSearchResult item, double target) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*ct',
      caseSensitive: false,
    ).firstMatch('${item.title} ${item.subtitle}');
    if (match == null) return 999;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return 999;
    return (value - target).abs();
  }

  static List<HomeSearchResult> _dedupeResults(List<HomeSearchResult> items) {
    final seen = <String>{};
    final out = <HomeSearchResult>[];
    for (final item in items) {
      final key = '${item.kind.name}:${item.id}';
      if (!seen.add(key)) continue;
      out.add(item);
    }
    return out;
  }

  Future<_CatalogBatch> _safe(Future<_CatalogBatch> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return _CatalogBatch.empty;
    } catch (_) {
      return _CatalogBatch.empty;
    }
  }

  /// Free text → `GET /diamond/search`. Stock/cert → `GET /diamond`.
  Future<_CatalogBatch> _searchDiamonds(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final Response<Map<String, dynamic>> response;
    if (mode == HomeSearchMode.freeText) {
      response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.diamondSearch,
        queryParameters: {'search': query, 'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
    } else {
      response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.diamond,
        queryParameters: {
          'page': page,
          'limit': limit,
          'search': query,
          'searchBy': HomeSearchQueryClassifier.searchBy(
            mode: mode,
            kind: HomeSearchKind.diamond,
          ),
        },
        cancelToken: cancelToken,
      );
    }

    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final items = _mapDiamonds(parsed.items, isMelee: false);
    return _CatalogBatch(
      items: items,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  Future<_CatalogBatch> _searchMelee(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.meleeDiamond,
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': query,
        'searchBy': HomeSearchQueryClassifier.searchBy(
          mode: mode,
          kind: HomeSearchKind.melee,
        ),
      },
      cancelToken: cancelToken,
    );
    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    return _CatalogBatch(
      items: _mapDiamonds(parsed.items, isMelee: true),
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  Future<_CatalogBatch> _searchGemstones(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.gemStone,
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': query,
        'searchBy': HomeSearchQueryClassifier.searchBy(
          mode: mode,
          kind: HomeSearchKind.gemstone,
        ),
      },
      cancelToken: cancelToken,
    );

    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final out = <HomeSearchResult>[];
    for (final item in parsed.items) {
      final dto = GemstoneDto.fromJson(item);
      if (dto.id.isEmpty) continue;
      final g = GemstoneMapper.toDomain(dto);
      out.add(
        HomeSearchResult(
          id: g.id,
          title: g.type,
          subtitle: [
            if (g.carat > 0) '${formatDecimal(g.carat)}ct',
            if (g.color.isNotEmpty) g.color,
            if (g.shape.isNotEmpty) g.shape,
            if (g.stockNumber != null && g.stockNumber!.isNotEmpty)
              g.stockNumber!,
          ].join(' · '),
          categoryLabel: 'Gemstone',
          priceLabel: _usd(g.price),
          kind: HomeSearchKind.gemstone,
          imageUrl: g.imageUrl,
          detail: gemstoneProductDetail(g),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  Future<_CatalogBatch> _searchWatches(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.watchAll,
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': query,
        'searchBy': HomeSearchQueryClassifier.searchBy(
          mode: mode,
          kind: HomeSearchKind.watch,
        ),
      },
      cancelToken: cancelToken,
    );

    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final out = <HomeSearchResult>[];
    for (final item in parsed.items) {
      final dto = WatchDto.fromJson(item);
      if (dto.id.isEmpty) continue;
      final w = WatchMapper.toDomain(dto);
      out.add(
        HomeSearchResult(
          id: w.id,
          title: '${w.brand} ${w.model}'.trim(),
          subtitle: [
            'Watch',
            if (w.collection.isNotEmpty) w.collection,
            if (w.dialColor.isNotEmpty) w.dialColor,
            if (w.caseMaterial.isNotEmpty) w.caseMaterial,
          ].join(' · '),
          categoryLabel: 'Watch',
          priceLabel: _usd(w.price),
          kind: HomeSearchKind.watch,
          imageUrl: w.renderableImageUrl,
          detail: watchProductDetail(w),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  /// Jewellery marketplace full-text search (ranked by relevance).
  Future<_CatalogBatch> _searchJewelry(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final trimmed = query.trim();
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceListings,
      queryParameters: {
        'page': page,
        'limit': limit.clamp(1, 100),
        if (trimmed.isNotEmpty)
          'search': trimmed.length > 120 ? trimmed.substring(0, 120) : trimmed,
      },
      cancelToken: cancelToken,
    );

    final parsed = MarketplaceMapper.page(
      MarketplaceJson.data(response.data),
      page: page,
    );
    final out = <HomeSearchResult>[];
    for (final listing in parsed.items) {
      final j = JewelryMapper.fromListing(listing);
      out.add(
        HomeSearchResult(
          id: j.id,
          title: j.name,
          subtitle: [
            if ((j.subCategory ?? j.category).isNotEmpty)
              j.subCategory ?? j.category,
            if (j.metalPurity.isNotEmpty) j.metalPurity,
            if (j.shopName != null) j.shopName!,
          ].join(' · '),
          categoryLabel: 'Jewelry',
          priceLabel: '${AppCurrency.inrSymbol}${formatInrPrice(j.price)}',
          kind: HomeSearchKind.jewelry,
          imageUrl: j.displayImageUrl,
          detail: jewelryProductDetail(j),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  Future<_CatalogBatch> _searchBullions(
    String query,
    HomeSearchMode mode,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.bullionAll,
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': query,
        'searchBy': HomeSearchQueryClassifier.searchBy(
          mode: mode,
          kind: HomeSearchKind.bullion,
        ),
      },
      cancelToken: cancelToken,
    );

    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final out = <HomeSearchResult>[];
    for (final item in parsed.items) {
      final dto = BullionDto.fromJson(item);
      if (dto.id.isEmpty) continue;
      final b = BullionMapper.toDomain(dto);
      out.add(
        HomeSearchResult(
          id: b.id,
          title: b.name,
          subtitle: [
            if (b.weightLabel.isNotEmpty) b.weightLabel,
            if (b.purity > 0) '${formatDecimal(b.purity)}‰',
            if (b.stockNumber != null && b.stockNumber!.isNotEmpty)
              b.stockNumber!,
          ].join(' · '),
          categoryLabel: 'Bullion',
          priceLabel: _usd(b.price),
          kind: HomeSearchKind.bullion,
          imageUrl: b.renderableImageUrl,
          detail: bullionProductDetail(b),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  /// Natural and lab rough together; the API matches stock number, title,
  /// mine, country, crystal shape, description and seller company.
  Future<_CatalogBatch> _searchRough(
    String query,
    int page,
    int limit,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.roughDiamondSearch,
      data: RoughSearchRequestMapper.toBody(
        filters: RoughFilterState(search: query),
        page: page,
        pageSize: limit,
        sort: RoughSortOption.newest,
        allTypes: true,
      ),
      cancelToken: cancelToken,
    );

    final parsed = _parseListResponse(response.data, limit: limit, page: page);
    final out = <HomeSearchResult>[];
    for (final item in parsed.items) {
      final r = RoughParcelMapper.fromJson(item);
      if (r.id.isEmpty) continue;
      out.add(
        HomeSearchResult(
          id: r.id,
          title: r.displayName,
          subtitle: [
            roughCarat(r.totalCaratWeight),
            roughPieces(r.totalPcs),
            if (r.stockNumber.isNotEmpty) r.stockNumber,
          ].join(' · '),
          categoryLabel: r.isLab ? 'Lab rough' : 'Rough diamond',
          priceLabel: _usd(r.totalPrice),
          kind: HomeSearchKind.rough,
          imageUrl: r.images.isEmpty ? null : r.images.first,
          detail: roughProductDetail(r),
        ),
      );
    }
    return _CatalogBatch(
      items: out,
      hasMore: parsed.hasMore,
      total: parsed.total,
    );
  }

  List<HomeSearchResult> _mapDiamonds(
    List<Map<String, dynamic>> items, {
    required bool isMelee,
  }) {
    final out = <HomeSearchResult>[];
    for (final item in items) {
      final dto = DiamondDto.fromJson(item, isMelee: isMelee);
      if (dto.id.isEmpty) continue;
      final growth = dto.growthType?.trim().toLowerCase() ?? '';
      final isLab = growth == 'cvd' || growth == 'hpht';
      final d = DiamondMapper.toDomain(dto, isLabGrown: isLab);

      final kind = isMelee
          ? HomeSearchKind.melee
          : (d.isLabGrown ? HomeSearchKind.lab : HomeSearchKind.diamond);

      final caratLabel = d.carat > 0 ? '${formatDecimal(d.carat)}ct' : null;
      final title = isMelee
          ? '${d.isLabGrown ? 'Lab ' : ''}${d.shape} Melee'
                '${caratLabel != null ? ' $caratLabel' : ''}'
          : '${d.isLabGrown ? 'Lab ' : ''}${d.shape}'
                '${caratLabel != null ? ' $caratLabel' : ''}';

      out.add(
        HomeSearchResult(
          id: d.id,
          title: title.trim(),
          subtitle: [
            if (isMelee) (d.isLabGrown ? 'Lab Melee' : 'Melee'),
            if (!isMelee && d.isLabGrown) 'Lab',
            if (caratLabel != null) caratLabel,
            if (d.color.isNotEmpty) d.color,
            if (d.clarity.isNotEmpty) d.clarity,
            if (d.cut.isNotEmpty) d.cut,
            if (d.stockNumber != null && d.stockNumber!.isNotEmpty)
              d.stockNumber!,
          ].join(' · '),
          categoryLabel: switch (kind) {
            HomeSearchKind.melee => 'Melee',
            HomeSearchKind.lab => 'Lab Grown Diamond',
            _ => 'Natural Diamond',
          },
          priceLabel: _usd(d.price),
          kind: kind,
          imageUrl: d.imageUrl,
          detail: diamondProductDetail(d),
        ),
      );
    }
    return out;
  }

  static ({List<Map<String, dynamic>> items, bool hasMore, int total})
  _parseListResponse(Object? root, {required int limit, required int page}) {
    final items = _extractItems(root);
    final meta = _extractMeta(root);
    final total = _asInt(meta['total']) ?? items.length;
    final currentPage = _asInt(meta['currentPage']) ?? page;
    final lastPage = _asInt(meta['lastPage']);

    final bool hasMore;
    if (meta.containsKey('next')) {
      hasMore = meta['next'] != null;
    } else if (lastPage != null) {
      hasMore = currentPage < lastPage;
    } else {
      hasMore = items.length >= limit;
    }

    return (items: items, hasMore: hasMore, total: total);
  }

  /// Handles `{ data: [...] }`, `{ data: { data: [...] } }`, or bare lists.
  static List<Map<String, dynamic>> _extractItems(Object? root) {
    if (root == null) return const [];
    if (root is List) {
      return root.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (root is! Map) return const [];

    final map = Map<String, dynamic>.from(root);
    final data = map['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (data is Map) {
      final nested = data['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }
    return const [];
  }

  static Map<String, dynamic> _extractMeta(Object? root) {
    if (root is! Map) return const {};
    final map = Map<String, dynamic>.from(root);
    final topMeta = map['meta'];
    if (topMeta is Map<String, dynamic>) return topMeta;
    if (topMeta is Map) return Map<String, dynamic>.from(topMeta);

    final data = map['data'];
    if (data is Map) {
      final nestedMeta = data['meta'];
      if (nestedMeta is Map<String, dynamic>) return nestedMeta;
      if (nestedMeta is Map) return Map<String, dynamic>.from(nestedMeta);
    }
    return const {};
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _usd(double price) {
    if (price <= 0) return '';
    return AppCurrency.format(formatGroupedPrice(price));
  }
}
