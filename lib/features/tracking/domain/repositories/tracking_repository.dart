import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../models/shipment_models.dart';

/// Buyer tracking operations backed by `/tracking/*` APIs.
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
}
