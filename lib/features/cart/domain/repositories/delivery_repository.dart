import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/models/delivery_address.dart';

/// Delivery address operations required before payment.
abstract class DeliveryRepository {
  Future<Result<List<DeliveryAddress>, Failure>> listAddresses({
    CancelToken? cancelToken,
  });

  Future<Result<DeliveryAddress, Failure>> createAddress(DeliveryAddress address);

  Future<Result<DeliveryAddress, Failure>> updateAddress(DeliveryAddress address);

  Future<Result<void, Failure>> deleteAddress(String addressId);

  Future<Result<CartDeliveryState, Failure>> getCartDelivery({
    CancelToken? cancelToken,
  });

  Future<Result<DeliveryAddress, Failure>> selectAddress({
    required String addressId,
  });
}
