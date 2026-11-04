import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/jewelry_premium.dart';
import '../../domain/models/marketplace_listing.dart';
import '../../domain/repositories/jewelry_repository.dart';
import '../mappers/jewelry_list_query_mapper.dart';
import '../mappers/jewelry_mapper.dart';
import '../mappers/marketplace_json.dart';
import '../mappers/marketplace_mapper.dart';

final jewelryRepositoryProvider = Provider<JewelryRepository>(
  (ref) => JewelryRepositoryImpl(ref.watch(dioProvider)),
);

/// Jewellery marketplace catalogue backed by the public `/marketplace` GETs.
class JewelryRepositoryImpl implements JewelryRepository {
  JewelryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<JewelryListResponse, Failure>> getJewelry({
    required JewelryFilterState filters,
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    JewelrySortOption? sort,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceListings,
      queryParameters: JewelryListQueryMapper.toQuery(
        filters: filters,
        page: page,
        pageSize: pageSize,
        sort: sort,
      ),
      cancelToken: cancelToken,
    );
    final parsed = MarketplaceMapper.page(
      MarketplaceJson.data(response.data),
      page: page,
    );
    return JewelryListResponse(
      items: parsed.items.map(JewelryMapper.fromListing).toList(),
      totalCount: parsed.total,
      hasMore: parsed.hasMore,
      page: parsed.page,
    );
  });

  @override
  Future<Result<List<Jewelry>, Failure>> getByIds({
    required JewelryFilterState filters,
    required List<String> ids,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final wanted = [
      for (final id in ids.toSet())
        if (id.trim().isNotEmpty) id.trim(),
    ].take(JewelryListQueryMapper.maxIds).toList();
    if (wanted.isEmpty) return const <Jewelry>[];
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceListings,
      queryParameters: {
        ...JewelryListQueryMapper.toQuery(
          filters: filters,
          page: 1,
          pageSize: wanted.length,
        ),
        'ids': wanted.join(','),
      },
      cancelToken: cancelToken,
    );
    final parsed = MarketplaceMapper.page(
      MarketplaceJson.data(response.data),
      page: 1,
    );
    final byId = {
      for (final l in parsed.items)
        if (l.slug.isNotEmpty) l.id: JewelryMapper.fromListing(l),
    };
    return [for (final id in wanted) ?byId[id]];
  });

  @override
  Future<Result<Jewelry, Failure>> getListing(
    String slug, {
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceListing(slug),
      cancelToken: cancelToken,
    );
    final data = MarketplaceJson.obj(MarketplaceJson.data(response.data));
    return JewelryMapper.fromJson(data);
  });

  @override
  Future<Result<List<Jewelry>, Failure>> getRelated(
    String slug, {
    int limit = 8,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceRelated(slug),
      queryParameters: {'limit': limit.clamp(1, 24)},
      cancelToken: cancelToken,
    );
    return [
      for (final l in MarketplaceJson.listOf(
        MarketplaceJson.data(response.data),
        MarketplaceMapper.listing,
      ))
        if (l.slug.isNotEmpty) JewelryMapper.fromListing(l),
    ];
  });

  @override
  Future<Result<MarketplaceFacets, Failure>> getFacets({
    required JewelryFilterState filters,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceFacets,
      queryParameters: JewelryListQueryMapper.toFacetQuery(filters),
      cancelToken: cancelToken,
    );
    return MarketplaceMapper.facets(MarketplaceJson.data(response.data));
  });

  @override
  Future<Result<JewelryPremiumPage, Failure>> getPremium({
    required int page,
    int pageSize = JewelryPageSize.defaultSize,
    String? category,
    JewelrySortOption? sort,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        ApiEndpoints.marketplacePremium,
        queryParameters: JewelryListQueryMapper.toQuery(
          filters: JewelryFilterState(category: category),
          page: page,
          pageSize: pageSize,
          sort: sort,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const JewelryPremiumPage.unavailable();
      }
      rethrow;
    }
    final data = MarketplaceJson.obj(MarketplaceJson.data(response.data));
    final parsed = MarketplaceMapper.page(data, page: page);
    return JewelryPremiumPage(
      items: parsed.items.map(JewelryMapper.fromListing).toList(),
      total: parsed.total,
      page: parsed.page,
      hasMore: parsed.hasMore,
      thresholdInr: MarketplaceJson.money(data['thresholdInr']),
      categories: [
        for (final c in MarketplaceJson.listOf(data['categories'], (c) => c))
          if (MarketplaceJson.text(c['slug']) case final slug?)
            (
              slug: slug,
              name: MarketplaceJson.text(c['name']) ?? slug,
              count: MarketplaceJson.asInt(c['count']),
            ),
      ],
    );
  });

  @override
  Future<Result<List<MarketplaceCategory>, Failure>> getCategories({
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceCategories,
      cancelToken: cancelToken,
    );
    return MarketplaceMapper.categories(MarketplaceJson.data(response.data));
  });

  @override
  Future<Result<List<MarketplaceShop>, Failure>> getShops({
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceShops,
      cancelToken: cancelToken,
    );
    return MarketplaceJson.listOf(
      MarketplaceJson.data(response.data),
      MarketplaceMapper.shop,
    );
  });

  @override
  Future<Result<MarketplaceShop, Failure>> getShop(
    String slug, {
    CancelToken? cancelToken,
  }) => _guard(() async {
    final response = await _dio.get<Object?>(
      ApiEndpoints.marketplaceShop(slug),
      cancelToken: cancelToken,
    );
    return MarketplaceMapper.shop(
      MarketplaceJson.obj(MarketplaceJson.data(response.data)),
    );
  });

  static Future<Result<T, Failure>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.success(await run());
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
