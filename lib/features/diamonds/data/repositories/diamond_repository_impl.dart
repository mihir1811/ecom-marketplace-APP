import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_catalog_type.dart';
import '../../domain/models/diamond_filter_state.dart';
import '../../domain/models/sorting_criteria.dart';
import '../../domain/repositories/diamond_repository.dart';
import '../mappers/diamond_mapper.dart';
import '../mappers/diamond_search_request_mapper.dart';
import '../models/diamond_dto.dart';

final diamondRepositoryProvider = Provider<DiamondRepository>(
  (ref) => DiamondRepositoryImpl(ref.watch(dioProvider)),
);

/// Live diamond listing / detail repository backed by `/diamond/*` APIs.
class DiamondRepositoryImpl implements DiamondRepository {
  DiamondRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<DiamondListResponse, Failure>> getDiamonds({
    required DiamondFilterState filters,
    required DiamondCatalogType catalog,
    required int page,
    int pageSize = DiamondPageSize.defaultSize,
    List<SortingCriteria> sorting = const [],
    CancelToken? cancelToken,
  }) async {
    try {
      final isMelee = catalog.isLabGrown
          ? filters.labCategory == 'Lab Melee'
          : filters.labNatural.usesMeleeFilters;
      final limit = pageSize < 1 ? DiamondPageSize.defaultSize : pageSize;
      final body = DiamondSearchRequestMapper.toBody(
        filters: filters,
        catalog: catalog,
        page: page,
        pageSize: limit,
        sorting: sorting,
      );

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.diamondSearch,
        data: body,
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
      final diamonds = <Diamond>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dto = DiamondDto.fromJson(item, isMelee: isMelee);
        if (dto.id.isEmpty) continue;
        diamonds.add(
          DiamondMapper.toDomain(dto, isLabGrown: catalog.isLabGrown),
        );
      }

      final total = _asInt(meta['total']) ?? diamonds.length;
      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']);
      // Prefer backend cursor: meta.next is null on the last page.
      final hasMore = meta.containsKey('next')
          ? meta['next'] != null
          : (lastPage != null
              ? currentPage < lastPage
              : diamonds.length >= limit);

      return Result.success(
        DiamondListResponse(
          diamonds: diamonds,
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

  @override
  Future<Result<Diamond, Failure>> getDiamondById({
    required String id,
    required bool isMelee,
    required bool isLabGrown,
    CancelToken? cancelToken,
  }) async {
    try {
      final path = isMelee
          ? ApiEndpoints.meleeDiamondById(id)
          : ApiEndpoints.diamondById(id);
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('The requested diamond was not found.'),
        );
      }
      final dto = DiamondDto.fromJson(data, isMelee: isMelee);
      if (dto.id.isEmpty) {
        return Result.failure(
          const NetworkFailure('The requested diamond was not found.'),
        );
      }
      return Result.success(
        DiamondMapper.toDomain(dto, isLabGrown: isLabGrown),
      );
    } on DioException catch (e) {
      return Result.failure(NetworkFailure.fromDioException(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
