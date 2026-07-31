import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/jewelry.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/repositories/jewelry_repository.dart';
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
      final query = JewelryListQueryMapper.toQuery(
        filters: filters,
        page: page,
        pageSize: limit,
        sort: sort,
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
      // Prefer backend cursor: meta.next is null on the last page.
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

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
