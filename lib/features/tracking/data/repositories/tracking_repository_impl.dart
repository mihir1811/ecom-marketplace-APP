import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/shipment_models.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../mappers/tracking_mapper.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepositoryImpl(ref.watch(dioProvider)),
);

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Shipment>, Failure>> listByOrder(String orderId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trackingOrders(orderId),
      );
      final root = response.data ?? const <String, dynamic>{};
      return Result.success(TrackingMapper.shipmentsFromResponse(root));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Shipment, Failure>> getShipment(String shipmentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trackingShipment(shipmentId),
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Shipment not found.'),
        );
      }
      return Result.success(TrackingMapper.shipmentFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<TrackingComment>, Failure>> listComments(
    String shipmentId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trackingShipmentComments(shipmentId),
      );
      final root = response.data ?? const <String, dynamic>{};
      return Result.success(TrackingMapper.commentsFromResponse(root));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<TrackingComment, Failure>> addComment({
    required String shipmentId,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.trackingShipmentComments(shipmentId),
        data: {'body': body},
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        return Result.success(TrackingMapper.commentFromJson(data));
      }
      return Result.success(
        TrackingComment(
          id: '',
          shipmentId: shipmentId,
          userId: '',
          body: body,
        ),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
