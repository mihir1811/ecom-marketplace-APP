/// Shipment status values from the tracking API.
abstract final class ShipmentStatuses {
  static const processing = 'PROCESSING';
  static const packed = 'PACKED';
  static const shipped = 'SHIPPED';
  static const inTransit = 'IN_TRANSIT';
  static const outForDelivery = 'OUT_FOR_DELIVERY';
  static const delivered = 'DELIVERED';
  static const cancelled = 'CANCELLED';

  /// Refunds stop once the parcel reaches out-for-delivery or later.
  static bool blocksBuyerRefund(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == outForDelivery || normalized == delivered;
  }
}

/// Shipment summary for a paid order.
class Shipment {
  const Shipment({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.status,
    this.currentLocation,
    this.carrier,
    this.trackingNumber,
    this.createdAt,
    this.updatedAt,
    this.updates = const [],
    this.comments = const [],
  });

  final String id;
  final String orderId;
  final String sellerId;
  final String status;
  final String? currentLocation;
  final String? carrier;
  final String? trackingNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TrackingUpdate> updates;
  final List<TrackingComment> comments;

  String get statusLabel => status.replaceAll('_', ' ');
}

class TrackingUpdate {
  const TrackingUpdate({
    required this.id,
    required this.shipmentId,
    required this.status,
    this.location,
    this.note,
    this.createdByUserId,
    this.createdAt,
  });

  final String id;
  final String shipmentId;
  final String status;
  final String? location;
  final String? note;
  final String? createdByUserId;
  final DateTime? createdAt;

  String get statusLabel => status.replaceAll('_', ' ');
}

class TrackingComment {
  const TrackingComment({
    required this.id,
    required this.shipmentId,
    required this.userId,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String shipmentId;
  final String userId;
  final String body;
  final DateTime? createdAt;
}
