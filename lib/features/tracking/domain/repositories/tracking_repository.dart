import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/shipment_models.dart';

/// Buyer and seller tracking operations backed by `/tracking/*` APIs.
abstract class TrackingRepository {
  Future<Result<List<Shipment>, Failure>> listByOrder(String orderId);

  Future<Result<Shipment, Failure>> getShipment(String shipmentId);

  Future<Result<List<TrackingComment>, Failure>> listComments(
    String shipmentId,
  );

  Future<Result<TrackingComment, Failure>> addComment({
    required String shipmentId,
    required String body,
  });

  /// `GET /tracking/seller/shipments`, narrowed to [orderId] when given.
  Future<Result<List<Shipment>, Failure>> listSellerShipments({
    String? orderId,
  });

  /// `POST /tracking/seller/shipments` (seller, paid + accepted order).
  Future<Result<Shipment, Failure>> createShipment({
    required String orderId,
    required String status,
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  });

  /// `PATCH /tracking/seller/shipments/{id}`.
  Future<Result<Shipment, Failure>> updateShipment({
    required String shipmentId,
    required String status,
    String? currentLocation,
    String? carrier,
    String? trackingNumber,
    String? note,
  });
}
