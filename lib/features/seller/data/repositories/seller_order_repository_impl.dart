import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/seller_order.dart';
import '../../domain/repositories/seller_order_repository.dart';
import '../mappers/seller_order_mapper.dart';

final sellerOrderRepositoryProvider = Provider<SellerOrderRepository>(
  (ref) => SellerOrderRepositoryImpl(ref.watch(dioProvider)),
);

class SellerOrderRepositoryImpl implements SellerOrderRepository {
  SellerOrderRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<SellerOrdersPage, Failure>> list({
    required int page,
    int limit = 10,
    SellerOrderStatus? status,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 10 : limit;
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.sellerOrders,
        queryParameters: {
          'page': safePage,
          'limit': safeLimit,
          'sort': '-createdAt',
          if (status != null && status != SellerOrderStatus.unknown)
            'status': status.apiValue,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        SellerOrderMapper.pageFromResponse(
          response.data,
          page: safePage,
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
  Future<Result<SellerOrder, Failure>> getById(String id) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.sellerOrderById(id),
      );
      final order = SellerOrderMapper.fromResponse(response.data);
      if (order == null) {
        return Result.failure(const NetworkFailure('Order not found.'));
      }
      return Result.success(order);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerOrder?, Failure>> accept(String id) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.sellerOrderAccept(id),
      );
      return Result.success(SellerOrderMapper.fromResponse(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SellerOrder?, Failure>> reject(
    String id, {
    required String reason,
    String? sellerNote,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.sellerOrderReject(id),
        data: {
          'reason': reason,
          if (sellerNote != null && sellerNote.trim().isNotEmpty)
            'sellerNote': sellerNote.trim(),
        },
      );
      return Result.success(SellerOrderMapper.fromResponse(response.data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
