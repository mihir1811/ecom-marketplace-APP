import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/wishlist_item.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../mappers/favorite_mapper.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepositoryImpl(ref.watch(dioProvider)),
);

/// Live favorites repository backed by `/favorites*` APIs.
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<WishlistItem, Failure>> add({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.favorites,
        data: {
          'productId': productId,
          'productType': productType,
        },
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return Result.success(FavoriteMapper.fromJson(data));
      }
      return Result.success(
        WishlistItem(
          id: productId,
          category: FavoriteProductType.toCategory(productType),
          productType: productType,
          title: FavoriteProductType.label(productType),
          subtitle: '',
          priceLabel: '',
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<WishlistPage, Failure>> list({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.favoritesAll,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 20 : limit,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        FavoriteMapper.pageFromJson(
          response.data,
          page: page,
          limit: limit,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<WishlistItem, Failure>> getOne({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.favoriteByProductId(productId),
        queryParameters: {'productType': productType},
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Favorite not found.'),
        );
      }
      return Result.success(FavoriteMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> remove({
    required String productId,
    required String productType,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.favoritesRemove,
        data: {
          'productId': productId,
          'productType': productType,
        },
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      if (root['success'] == false) {
        return Result.failure(
          ValidationFailure(
            ApiError.extractMessage(root) ?? 'Could not remove from favorites.',
          ),
        );
      }
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
