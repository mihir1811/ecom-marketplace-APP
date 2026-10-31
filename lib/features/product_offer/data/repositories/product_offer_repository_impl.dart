import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/response_parser.dart';
import '../../domain/models/product_offer.dart';
import '../../domain/repositories/product_offer_repository.dart';
import '../mappers/product_offer_mapper.dart';

final productOfferRepositoryProvider = Provider<ProductOfferRepository>(
  (ref) => ProductOfferRepositoryImpl(ref.watch(dioProvider)),
);

class ProductOfferRepositoryImpl implements ProductOfferRepository {
  ProductOfferRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<ProductOffer, Failure>> create({
    required String productId,
    required String productType,
    required String amount,
    String? message,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.productOffer,
        data: {
          'productId': productId,
          'productType': productType,
          'amount': amount,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
        cancelToken: cancelToken,
      );
      final data = ResponseParser.entity(response.data);
      if (data == null) {
        return Result.failure(
          const NetworkFailure('Could not submit the offer.'),
        );
      }
      return Result.success(ProductOfferMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<ProductOffer>, Failure>> listMine({
    required String productType,
    required String productId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.productOfferMine(productType, productId),
        cancelToken: cancelToken,
      );
      final root = response.data;
      final data = root?['data'];
      final list = data is List ? data : const [];
      final items = <ProductOffer>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        items.add(ProductOfferMapper.fromJson(item));
      }
      return Result.success(items);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ProductOfferListPage, Failure>> listMineAll({
    required int page,
    int limit = 20,
    String? statusFilter,
    CancelToken? cancelToken,
  }) =>
      _listPage(
        ApiEndpoints.productOfferMineAll,
        page: page,
        limit: limit,
        defaultLimit: 20,
        statusFilter: statusFilter,
        cancelToken: cancelToken,
      );

  @override
  Future<Result<ProductOfferListPage, Failure>> listSeller({
    required int page,
    int limit = 10,
    String? statusFilter,
    CancelToken? cancelToken,
  }) =>
      _listPage(
        ApiEndpoints.productOfferSeller,
        page: page,
        limit: limit,
        defaultLimit: 10,
        statusFilter: statusFilter,
        cancelToken: cancelToken,
      );

  /// Paged offer list; `status` filters by an own column of the offer.
  Future<Result<ProductOfferListPage, Failure>> _listPage(
    String path, {
    required int page,
    required int limit,
    required int defaultLimit,
    String? statusFilter,
    CancelToken? cancelToken,
  }) async {
    final safeLimit = limit < 1 ? defaultLimit : limit;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': safeLimit,
          'sort': '-createdAt',
          if (statusFilter != null && statusFilter.isNotEmpty)
            'status': statusFilter,
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        ProductOfferMapper.listPageFromJson(
          response.data,
          page: page,
          limit: safeLimit,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ProductOffer, Failure>> respond({
    required String id,
    required ProductOfferStatus status,
    String? amount,
    String? message,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.productOfferRespond(id),
        data: {
          'status': status.apiValue,
          if (status == ProductOfferStatus.countered && amount != null)
            'amount': amount,
          if (status == ProductOfferStatus.countered &&
              message != null &&
              message.trim().isNotEmpty)
            'message': message.trim(),
        },
        cancelToken: cancelToken,
      );
      final data = ResponseParser.entity(response.data);
      if (data == null) {
        return Result.failure(
          const NetworkFailure('Could not update the offer.'),
        );
      }
      return Result.success(ProductOfferMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
