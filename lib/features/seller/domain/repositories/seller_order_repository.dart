import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/seller_order.dart';

/// Incoming orders for the signed-in seller (`/seller/orders`).
abstract class SellerOrderRepository {
  Future<Result<SellerOrdersPage, Failure>> list({
    required int page,
    int limit = 10,
    SellerOrderStatus? status,
    String? search,
    CancelToken? cancelToken,
  });

  Future<Result<SellerOrder, Failure>> getById(String id);

  /// `POST /seller/orders/{id}/accept`. Returns the updated order when the
  /// API echoes it, otherwise `null` (callers then refetch).
  Future<Result<SellerOrder?, Failure>> accept(String id);

  /// `POST /seller/orders/{id}/reject` — the backend refunds the buyer's
  /// payment for this order straight to their wallet.
  Future<Result<SellerOrder?, Failure>> reject(
    String id, {
    required String reason,
    String? sellerNote,
  });
}
