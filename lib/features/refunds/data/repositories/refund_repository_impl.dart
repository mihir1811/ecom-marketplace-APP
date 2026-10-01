import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/refund_list_page.dart';
import '../../domain/models/refund_request.dart';
import '../../domain/repositories/refund_repository.dart';
import '../mappers/refund_mapper.dart';

final refundRepositoryProvider = Provider<RefundRepository>(
  (ref) => RefundRepositoryImpl(ref.watch(dioProvider)),
);

class RefundRepositoryImpl implements RefundRepository {
  RefundRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<RefundRequest, Failure>> create({
    required String orderId,
    required String sellerId,
    required String reason,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refunds,
        data: {'orderId': orderId, 'sellerId': sellerId, 'reason': reason},
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not create the refund request.'),
        );
      }
      return Result.success(RefundMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RefundListPage, Failure>> listMine({
    required int page,
    int limit = 10,
    String? status,
    String? orderId,
    CancelToken? cancelToken,
  }) {
    return _list(
      path: ApiEndpoints.refundsMine,
      page: page,
      limit: limit,
      status: status,
      orderId: orderId,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<RefundListPage, Failure>> listSeller({
    required int page,
    int limit = 10,
    String? status,
    CancelToken? cancelToken,
  }) {
    return _list(
      path: ApiEndpoints.refundsSeller,
      page: page,
      limit: limit,
      status: status,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<RefundRequest, Failure>> getById({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.refundById(id),
        cancelToken: cancelToken,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Refund request not found.'),
        );
      }
      return Result.success(RefundMapper.fromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RefundRequest, Failure>> accept({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.refundAccept(id),
        cancelToken: cancelToken,
      );
      return _parseRefund(response.data, 'Could not accept the refund.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RefundRequest, Failure>> reject({
    required String id,
    String? sellerNote,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.refundReject(id),
        data: {
          if (sellerNote != null && sellerNote.trim().isNotEmpty)
            'sellerNote': sellerNote.trim(),
        },
        cancelToken: cancelToken,
      );
      return _parseRefund(response.data, 'Could not reject the refund.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<RefundRequest, Failure>> cancel({
    required String id,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.refundCancel(id),
        cancelToken: cancelToken,
      );
      return _parseRefund(response.data, 'Could not cancel the refund.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Future<Result<RefundListPage, Failure>> _list({
    required String path,
    required int page,
    required int limit,
    String? status,
    String? orderId,
    CancelToken? cancelToken,
  }) async {
    final filters = {
      if (status != null && status.isNotEmpty) 'status': status,
      if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
    };
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'page': page < 1 ? 1 : page,
          'limit': limit < 1 ? 10 : limit,
          'sort': '-createdAt',
          if (filters.isNotEmpty) 'filters': jsonEncode(filters),
        },
        cancelToken: cancelToken,
      );
      return Result.success(
        RefundMapper.listPageFromJson(response.data, page: page, limit: limit),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Result<RefundRequest, Failure> _parseRefund(
    Map<String, dynamic>? root,
    String fallback,
  ) {
    final data = root?['data'];
    if (data is! Map<String, dynamic>) {
      return Result.failure(NetworkFailure(fallback));
    }
    return Result.success(RefundMapper.fromJson(data));
  }
}
