import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/features/tracking/domain/models/shipment_models.dart';

Shipment _s(String seller, String status) => Shipment(
  id: '$seller-$status',
  orderId: 'o1',
  sellerId: seller,
  status: status,
);

void main() {
  test('review opens only for sellers whose parcels are all delivered', () {
    final ids = deliveredSellerIds([
      _s('a', 'DELIVERED'),
      _s('b', 'IN_TRANSIT'),
      _s('c', 'DELIVERED'),
      _s('c', 'SHIPPED'),
      _s('d', 'delivered'),
      _s('d', 'CANCELLED'),
      _s('e', 'CANCELLED'),
    ]);
    expect(ids, {'a', 'd'});
  });

  test('no shipments means nothing to review yet', () {
    expect(deliveredSellerIds(const []), isEmpty);
  });
}
