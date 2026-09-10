import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/gemstone.dart';
import '../../domain/models/gemstone_filter_state.dart';
import '../../domain/repositories/gemstone_repository.dart';
import '../mappers/gemstone_mapper.dart';
import '../mappers/gemstone_search_request_mapper.dart';
import '../models/gemstone_dto.dart';

final gemstoneRepositoryProvider = Provider<GemstoneRepository>(
  (ref) => GemstoneRepositoryImpl(ref.watch(dioProvider)),
);

/// Live gemstone listing / detail repository backed by `/gem-stone/*` APIs.
class GemstoneRepositoryImpl implements GemstoneRepository {
  GemstoneRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<GemstoneListResponse, Failure>> getGemstones({
    required GemstoneFilterState filters,
    required int page,
    int pageSize = GemstonePageSize.defaultSize,
    String? sortBy,
    String? sellerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final limit = pageSize < 1 ? GemstonePageSize.defaultSize : pageSize;
      final body = GemstoneSearchRequestMapper.toBody(
        filters: filters,
        page: page,
        pageSize: limit,
        sortBy: sortBy,
        sellerId: sellerId,
      );

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.gemStoneSearch,
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
      final gemstones = <Gemstone>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final dto = GemstoneDto.fromJson(item);
        if (dto.id.isEmpty) continue;
        gemstones.add(GemstoneMapper.toDomain(dto));
      }

      final total = _asInt(meta['total']) ?? gemstones.length;
      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']);
      // Prefer backend cursor: meta.next is null on the last page.
      final hasMore = meta.containsKey('next')
          ? meta['next'] != null
          : (lastPage != null
              ? currentPage < lastPage
              : gemstones.length >= limit);

      return Result.success(
        GemstoneListResponse(
          gemstones: gemstones,
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
  Future<Result<Gemstone, Failure>> getGemstoneById({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.gemStoneById(id),
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('The requested gemstone was not found.'),
        );
      }
      final dto = GemstoneDto.fromJson(data);
      if (dto.id.isEmpty) {
        return Result.failure(
          const NetworkFailure('The requested gemstone was not found.'),
        );
      }
      return Result.success(GemstoneMapper.toDomain(dto));
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
