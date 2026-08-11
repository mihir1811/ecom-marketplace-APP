import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/jewellery_category_admin.dart';
import '../../domain/repositories/jewellery_category_admin_repository.dart';
import '../mappers/jewellery_category_admin_mapper.dart';

final jewelleryCategoryAdminRepositoryProvider =
    Provider<JewelleryCategoryAdminRepository>(
  (ref) => JewelleryCategoryAdminRepositoryImpl(ref.watch(dioProvider)),
);

class JewelleryCategoryAdminRepositoryImpl
    implements JewelleryCategoryAdminRepository {
  JewelleryCategoryAdminRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<JewelleryCategoryAdmin, Failure>> getById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.jewelleryCategoryById(id),
        cancelToken: cancelToken,
      );
      final category =
          JewelleryCategoryAdminMapper.categoryFromResponse(response.data);
      if (category == null) {
        return Result.failure(
          const NetworkFailure('Category not found.'),
        );
      }
      return Result.success(category);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<JewelleryCategoryAdmin, Failure>> create(
    JewelleryCategoryInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.jewelleryCategories,
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final category =
          JewelleryCategoryAdminMapper.categoryFromResponse(response.data);
      if (category == null) {
        return Result.failure(
          const NetworkFailure('Could not create category.'),
        );
      }
      return Result.success(category);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<JewelleryCategoryAdmin, Failure>> update(
    String id,
    JewelleryCategoryInput input, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.jewelleryCategoryById(id),
        data: input.toJson(),
        cancelToken: cancelToken,
      );
      final category =
          JewelleryCategoryAdminMapper.categoryFromResponse(response.data);
      if (category == null) {
        return Result.failure(
          const NetworkFailure('Could not update category.'),
        );
      }
      return Result.success(category);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deactivate(
    String id, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.jewelleryCategoryById(id),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<JewellerySubcategoryAdmin, Failure>> addSubcategory(
    String categoryId,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.jewelleryCategorySubcategories(categoryId),
        data: body,
        cancelToken: cancelToken,
      );
      final sub =
          JewelleryCategoryAdminMapper.subcategoryFromResponse(response.data);
      if (sub == null) {
        return Result.failure(
          const NetworkFailure('Could not add subcategory.'),
        );
      }
      return Result.success(sub);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<JewellerySubcategoryAdmin, Failure>> updateSubcategory(
    String subcategoryId,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.jewellerySubcategoryById(subcategoryId),
        data: body,
        cancelToken: cancelToken,
      );
      final sub =
          JewelleryCategoryAdminMapper.subcategoryFromResponse(response.data);
      if (sub == null) {
        return Result.failure(
          const NetworkFailure('Could not update subcategory.'),
        );
      }
      return Result.success(sub);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deactivateSubcategory(
    String subcategoryId, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.jewellerySubcategoryById(subcategoryId),
        cancelToken: cancelToken,
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
