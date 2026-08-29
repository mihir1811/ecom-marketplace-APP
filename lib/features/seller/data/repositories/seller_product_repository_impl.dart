import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/seller_product.dart';
import '../../domain/repositories/seller_product_repository.dart';
import '../mappers/seller_product_mapper.dart';
import '../mappers/seller_product_request_mapper.dart';

final sellerProductRepositoryProvider = Provider<SellerProductRepository>(
  (ref) => SellerProductRepositoryImpl(ref.watch(dioProvider)),
);

class SellerProductRepositoryImpl implements SellerProductRepository {
  const SellerProductRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<SellerProduct>, Failure>> listProducts({
    required String sellerId,
    CancelToken? cancelToken,
  }) async {
    try {
      final natural = await _listAll(
        path: ApiEndpoints.diamond,
        isNatural: true,
        sellerId: sellerId,
        cancelToken: cancelToken,
      );
      final melee = await _listAll(
        path: ApiEndpoints.meleeDiamond,
        isNatural: false,
        sellerId: sellerId,
        cancelToken: cancelToken,
      );
      return Result.success([...natural, ...melee]);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> updateProduct(
    SellerProduct product, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        _itemPath(product),
        data: SellerProductRequestMapper.toUpdateFormData(product),
        options: Options(contentType: Headers.multipartFormDataContentType),
        cancelToken: cancelToken,
      );
      return _okOrMessage(
        response.data,
        fallback: 'Could not update this product. Please try again.',
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteProduct(
    SellerProduct product, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        _itemPath(product),
        cancelToken: cancelToken,
      );
      return _okOrMessage(
        response.data,
        fallback: 'Could not delete this product. Please try again.',
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<List<SellerProduct>> _listAll({
    required String path,
    required bool isNatural,
    required String sellerId,
    CancelToken? cancelToken,
  }) async {
    final products = <SellerProduct>[];
    var page = 1;
    const limit = 100;

    while (page <= 20) {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': '-updatedAt',
          'filters': jsonEncode({'sellerId': sellerId}),
        },
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

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final product = SellerProductMapper.fromJson(
          item,
          isNatural: isNatural,
        );
        if (product.id.isEmpty) continue;
        if (product.sellerId.isNotEmpty && product.sellerId != sellerId) {
          continue;
        }
        products.add(product);
      }

      if (list.isEmpty || list.length < limit) break;

      final currentPage = _asInt(meta['currentPage']) ?? page;
      final lastPage = _asInt(meta['lastPage']);
      final hasMore = lastPage != null
          ? currentPage < lastPage
          : (meta.containsKey('next') && meta['next'] != null);
      if (!hasMore) break;
      final nextPage = currentPage + 1;
      if (nextPage <= page) break;
      page = nextPage;
    }

    return products;
  }

  String _itemPath(SellerProduct product) => product.isNatural
      ? ApiEndpoints.diamondById(product.id)
      : ApiEndpoints.meleeDiamondById(product.id);

  Result<void, Failure> _okOrMessage(
    Map<String, dynamic>? root, {
    required String fallback,
  }) {
    if (root != null && root['success'] == false) {
      return Result.failure(
        ValidationFailure(ApiError.extractMessage(root) ?? fallback),
      );
    }
    return Result.success(null);
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
