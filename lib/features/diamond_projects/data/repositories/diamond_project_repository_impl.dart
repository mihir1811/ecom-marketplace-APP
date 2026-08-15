import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/diamond_project.dart';
import '../../domain/models/diamond_project_item.dart';
import '../../domain/repositories/diamond_project_repository.dart';
import '../mappers/diamond_project_mapper.dart';
import '../models/diamond_project_dto.dart';

final diamondProjectRepositoryProvider = Provider<DiamondProjectRepository>(
  (ref) => DiamondProjectRepositoryImpl(ref.watch(dioProvider)),
);

/// Live diamond-project repository backed by `/diamond-projects` APIs.
class DiamondProjectRepositoryImpl implements DiamondProjectRepository {
  DiamondProjectRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<DiamondProjectPage, Failure>> listMine({
    int page = 1,
    int limit = 20,
    String? search,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.diamondProjects,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 20 : limit,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
        cancelToken: cancelToken,
      );
      final dto = DiamondProjectListDto.fromJson(response.data);
      return Result.success(
        DiamondProjectPage(
          projects: dto.items.map(DiamondProjectMapper.toDomain).toList(),
          page: dto.page,
          hasMore: dto.hasMore,
          totalCount: dto.total,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DiamondProject, Failure>> getOne(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.diamondProjectById(id),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Diamond project not found.'),
        );
      }
      return Result.success(
        DiamondProjectMapper.toDomain(DiamondProjectDto.fromJson(data)),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DiamondProject, Failure>> upsert({
    String? id,
    required String name,
    String? diamondType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? analytics,
    required List<DiamondProjectItem> items,
    CancelToken? cancelToken,
  }) {
    return _write(
      path: ApiEndpoints.diamondProjects,
      method: 'POST',
      id: id,
      name: name,
      diamondType: diamondType,
      filters: filters,
      analytics: analytics,
      items: items,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<DiamondProject, Failure>> update({
    required String id,
    required String name,
    String? diamondType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? analytics,
    required List<DiamondProjectItem> items,
    CancelToken? cancelToken,
  }) {
    return _write(
      path: ApiEndpoints.diamondProjectById(id),
      method: 'PUT',
      id: id,
      name: name,
      diamondType: diamondType,
      filters: filters,
      analytics: analytics,
      items: items,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<void, Failure>> remove(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.diamondProjectById(id),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<DiamondProject, Failure>> _write({
    required String path,
    required String method,
    String? id,
    required String name,
    String? diamondType,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? analytics,
    required List<DiamondProjectItem> items,
    CancelToken? cancelToken,
  }) async {
    try {
      final body = <String, dynamic>{
        if (id != null && id.isNotEmpty) 'id': id,
        'name': name,
        if (diamondType != null && diamondType.isNotEmpty)
          'diamondType': diamondType,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
        if (analytics != null && analytics.isNotEmpty) 'analytics': analytics,
        'items': [for (final item in items) DiamondProjectMapper.itemToJson(item)],
      };
      final response = method == 'PUT'
          ? await _dio.put<Map<String, dynamic>>(
              path,
              data: body,
              cancelToken: cancelToken,
            )
          : await _dio.post<Map<String, dynamic>>(
              path,
              data: body,
              cancelToken: cancelToken,
            );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not save the diamond project.'),
        );
      }
      return Result.success(
        DiamondProjectMapper.toDomain(DiamondProjectDto.fromJson(data)),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
