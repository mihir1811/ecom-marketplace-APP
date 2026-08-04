import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/delivery_address.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../mappers/cart_mapper.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>(
  (ref) => DeliveryRepositoryImpl(ref.watch(dioProvider)),
);

/// Delivery options repository for checkout address selection.
class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<DeliveryAddress>, Failure>> listAddresses({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.deliveryAddresses,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      final list = data is List ? data : const [];
      final addresses = <DeliveryAddress>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        addresses.add(CartMapper.addressFromJson(item));
      }
      return Result.success(addresses);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DeliveryAddress, Failure>> createAddress(
    DeliveryAddress address,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.deliveryAddresses,
        data: CartMapper.addressToCreateBody(address),
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not save the delivery address.'),
        );
      }
      return Result.success(CartMapper.addressFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DeliveryAddress, Failure>> updateAddress(
    DeliveryAddress address,
  ) async {
    final id = address.id;
    if (id == null || id.isEmpty) {
      return Result.failure(
        const NetworkFailure('Could not update the delivery address.'),
      );
    }
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.deliveryAddressById(id),
        data: CartMapper.addressToCreateBody(address),
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not update the delivery address.'),
        );
      }
      return Result.success(CartMapper.addressFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAddress(String addressId) async {
    if (addressId.isEmpty) {
      return Result.failure(
        const NetworkFailure('Could not delete the delivery address.'),
      );
    }
    try {
      await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.deliveryAddressById(addressId),
      );
      return Result.success(null);
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<CartDeliveryState, Failure>> getCartDelivery({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.deliveryCart,
        cancelToken: cancelToken,
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is Map<String, dynamic>) {
        return Result.success(CartMapper.deliveryStateFromJson(data));
      }
      return Result.success(const CartDeliveryState());
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<DeliveryAddress, Failure>> selectAddress({
    required String addressId,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.deliveryCartSelect,
        data: {'addressId': addressId},
      );
      final root = response.data ?? const <String, dynamic>{};
      final data = root['data'];
      if (data is! Map<String, dynamic>) {
        return Result.failure(
          const NetworkFailure('Could not select the delivery address.'),
        );
      }
      return Result.success(CartMapper.addressFromJson(data));
    } on DioException catch (e) {
      return Result.failure(ApiError.fromDio(e));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
