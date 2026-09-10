import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/billion.dart';
import '../../domain/models/bullions_filter_state.dart';
import '../../domain/repositories/bullions_repository.dart';
import '../mappers/bullion_list_query_mapper.dart';
import '../mappers/bullion_mapper.dart';
import '../models/bullion_dto.dart';

final bullionsRepositoryProvider = Provider<BullionsRepository>(
  (ref) => BullionsRepositoryImpl(ref.watch(dioProvider)),
);

/// Live bullion listing repository backed by `GET /bullion/all`.
///
/// Backend accepts `page`/`limit` but may omit `meta`; hasMore falls back to
/// `items.length >= limit` so infinite scroll never loads the full catalog.
class BullionsRepositoryImpl implements BullionsRepository {
  BullionsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<BullionsCatalogResponse, Failure>> searchBullions({
    required BullionsFilterState filters,
    required int page,
    int pageSize = BullionPageSize.defaultSize,
    BullionsSortOption sort = BullionsSortOption.featured,
    String? sellerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final limit = pageSize < 1 ? BullionPageSize.defaultSize : pageSize;
      final query = BullionListQueryMapper.toQuery(
        filters: filters,
        page: page,
        pageSize: limit,
        sort: sort,
        sellerId: sellerId,
      );

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.bullionAll,
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
      final meta = metaJson is Map<String, dynamic>
          ? metaJson
          : const <String, dynamic>{};

      final list = itemsJson is List ? itemsJson : const [];
      final bullions = <Bullion>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dto = BullionDto.fromJson(item);
        if (dto.id.isEmpty) continue;
        bullions.add(BullionMapper.toDomain(dto));
      }

      final total = _asInt(meta['total']);
      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']);

      final bool hasMore;
      if (meta.containsKey('next')) {
        hasMore = meta['next'] != null;
      } else if (lastPage != null) {
        hasMore = currentPage < lastPage;
      } else {
        // No meta (current live API): infer from page fullness.
        hasMore = bullions.length >= limit;
      }

      return Result.success(
        BullionsCatalogResponse(
          bullions: bullions,
          totalCount: total ??
              (hasMore
                  ? (page * limit) + 1
                  : ((page - 1) * limit) + bullions.length),
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
