import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/rough_facets.dart';
import '../../domain/models/rough_filter_state.dart';
import '../../domain/models/rough_parcel.dart';
import '../../domain/models/rough_sort_option.dart';
import '../../domain/repositories/rough_diamond_repository.dart';
import '../mappers/rough_parcel_mapper.dart';
import '../mappers/rough_search_request_mapper.dart';

final roughDiamondRepositoryProvider = Provider<RoughDiamondRepository>(
  (ref) => RoughDiamondRepositoryImpl(ref.watch(dioProvider)),
);

/// Rough catalogue backed by the public `/rough-diamond/*` endpoints.
class RoughDiamondRepositoryImpl implements RoughDiamondRepository {
  RoughDiamondRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<RoughSearchPage, Failure>> search({
    required RoughFilterState filters,
    required int page,
    int pageSize = RoughPageSize.defaultSize,
    RoughSortOption sort = RoughSortOption.newest,
    String? sellerId,
    bool allTypes = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.roughDiamondSearch,
        data: RoughSearchRequestMapper.toBody(
          filters: filters,
          page: page,
          pageSize: pageSize,
          sort: sort,
          sellerId: sellerId,
          allTypes: allTypes,
        ),
        cancelToken: cancelToken,
      );
      final (parcels, meta) = _page(response.data);
      final total = RoughParcelMapper.integer(meta['total']) ?? parcels.length;
      final hasMore = meta.containsKey('next')
          ? meta['next'] != null
          : parcels.length >= pageSize;
      return Result.success(
        RoughSearchPage(parcels: parcels, totalCount: total, hasMore: hasMore),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<RoughParcel>, Failure>> byIds(List<String> ids) async {
    final unique = {
      for (final id in ids)
        if (id.trim().isNotEmpty) id.trim(),
    }.take(200).toList();
    if (unique.isEmpty) return Result.success(const []);
    try {
      // Without diamondType the search covers natural and lab rough.
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.roughDiamondSearch,
        data: {'ids': unique, 'page': 1, 'limit': unique.length},
      );
      return Result.success(_page(response.data).$1);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RoughFacets, Failure>> facets(RoughDiamondType type) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.roughDiamondFilters,
        queryParameters: {'diamondType': type.query},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.success(RoughFacets.empty);
      }
      return Result.success(RoughParcelMapper.facetsFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RoughParcel, Failure>> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.roughDiamondById(id),
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NotFoundFailure('Rough diamond not found.'),
        );
      }
      final parcel = RoughParcelMapper.fromJson(data);
      if (parcel.id.isEmpty) {
        return Result.failure(
          const NotFoundFailure('Rough diamond not found.'),
        );
      }
      return Result.success(parcel);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  /// `{ data: { data: [...], meta: {...} } }` → parcels + meta.
  static (List<RoughParcel>, Map<String, dynamic>) _page(
    Map<String, dynamic>? root,
  ) {
    final payload = root?['data'];
    final node = payload is Map<String, dynamic>
        ? payload
        : const <String, dynamic>{};
    final items = node['data'];
    final meta = node['meta'];
    final parcels = <RoughParcel>[
      if (items is List)
        for (final item in items)
          if (item is Map<String, dynamic>) RoughParcelMapper.fromJson(item),
    ]..removeWhere((p) => p.id.isEmpty);
    return (
      parcels,
      meta is Map<String, dynamic> ? meta : const <String, dynamic>{},
    );
  }
}
