import '../../domain/models/shipment_models.dart';

/// Parses tracking / shipment JSON into domain models.
abstract final class TrackingMapper {
  static List<Shipment> shipmentsFromResponse(Map<String, dynamic> root) {
    final data = root['data'];
    final list = <dynamic>[];
    if (data is List) {
      list.addAll(data);
    } else if (data is Map<String, dynamic>) {
      final nested = data['shipments'] ?? data['data'] ?? data['items'];
      if (nested is List) list.addAll(nested);
    }
    final out = <Shipment>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final shipment = shipmentFromJson(item);
      if (shipment.id.isEmpty) continue;
      out.add(shipment);
    }
    return out;
  }

  static Shipment shipmentFromJson(Map<String, dynamic> json) {
    final updatesJson = json['updates'] ?? json['timeline'];
    final updates = <TrackingUpdate>[];
    if (updatesJson is List) {
      for (final u in updatesJson) {
        if (u is! Map<String, dynamic>) continue;
        updates.add(updateFromJson(u));
      }
    }

    final commentsJson = json['comments'];
    final comments = <TrackingComment>[];
    if (commentsJson is List) {
      for (final c in commentsJson) {
        if (c is! Map<String, dynamic>) continue;
        comments.add(commentFromJson(c));
      }
    }

    return Shipment(
      id: _str(json['id']) ?? '',
      orderId: _str(json['orderId']) ?? '',
      sellerId: _str(json['sellerId']) ?? '',
      status: _str(json['status']) ?? ShipmentStatuses.processing,
      currentLocation: _str(json['currentLocation']),
      carrier: _str(json['carrier']),
      trackingNumber: _str(json['trackingNumber']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
      updates: updates,
      comments: comments,
    );
  }

  static TrackingUpdate updateFromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: _str(json['id']) ?? '',
      shipmentId: _str(json['shipmentId']) ?? '',
      status: _str(json['status']) ?? '',
      location: _str(json['location']),
      note: _str(json['note']),
      createdByUserId: _str(json['createdByUserId']),
      createdAt: _date(json['createdAt']),
    );
  }

  static TrackingComment commentFromJson(Map<String, dynamic> json) {
    return TrackingComment(
      id: _str(json['id']) ?? '',
      shipmentId: _str(json['shipmentId']) ?? '',
      userId: _str(json['userId']) ?? '',
      body: _str(json['body']) ?? '',
      createdAt: _date(json['createdAt']),
    );
  }

  static List<TrackingComment> commentsFromResponse(
    Map<String, dynamic> root,
  ) {
    final data = root['data'];
    final list = <dynamic>[];
    if (data is List) {
      list.addAll(data);
    } else if (data is Map<String, dynamic>) {
      final nested = data['comments'] ?? data['data'] ?? data['items'];
      if (nested is List) list.addAll(nested);
    }
    final out = <TrackingComment>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final comment = commentFromJson(item);
      if (comment.id.isEmpty && comment.body.isEmpty) continue;
      out.add(comment);
    }
    return out;
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _date(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
