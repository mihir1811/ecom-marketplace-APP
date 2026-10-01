import 'dart:convert';

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
        return Result.failure(const NetworkFailure('Shipment not found.'));
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
        TrackingComment(id: '', shipmentId: shipmentId, userId: '', body: body),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Shipment>, Failure>> listSellerShipments({
    String? orderId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.trackingSellerShipments,
        queryParameters: {
          'page': 1,
          'limit': 50,
          'sort': '-createdAt',
          if (orderId != null && orderId.isNotEmpty)
            'filters': jsonEncode({'orderId': orderId}),
        },
      );
      final root = response.data ?? const <String, dynamic>{};
      final shipments = TrackingMapper.shipmentsFromResponse(root);
      // The filter language is not documented for this route; never show
      // another order's parcel if the server ignored it.
      return Result.success(
        orderId == null || orderId.isEmpty
            ? shipments
            : shipments.where((s) => s.orderId == orderId).toList(),
      );
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Shipment, Failure>> createShipment({
    required String orderId,
    required String status,
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.trackingSellerShipments,
        data: {
          'orderId': orderId,
          'status': status,
          ..._shipmentFields(
            currentLocation: currentLocation,
            carrier: carrier,
            trackingNumber: trackingNumber,
            note: note,
          ),
        },
      );
      return _parseShipment(response.data, 'Could not create the shipment.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Shipment, Failure>> updateShipment({
    required String shipmentId,
    required String status,
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.trackingSellerShipment(shipmentId),
        data: {
          'status': status,
          ..._shipmentFields(
            currentLocation: currentLocation,
            carrier: carrier,
            trackingNumber: trackingNumber,
            note: note,
          ),
        },
      );
      return _parseShipment(response.data, 'Could not update the shipment.');
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  static Map<String, String> _shipmentFields({
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  }) {
    String? clean(String? v) {
      final t = v?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    return {
      if (clean(currentLocation) case final v?) 'currentLocation': v,
      if (clean(carrier) case final v?) 'carrier': v,
      if (clean(trackingNumber) case final v?) 'trackingNumber': v,
      if (clean(note) case final v?) 'note': v,
    };
  }

  Result<Shipment, Failure> _parseShipment(
    Map<String, dynamic>? root,
    String fallback,
  ) {
    final data = root?['data'];
    if (data is! Map<String, dynamic>) {
      return Result.failure(NetworkFailure(fallback));
    }
    return Result.success(TrackingMapper.shipmentFromJson(data));
  }
}
