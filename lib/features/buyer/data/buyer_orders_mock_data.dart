import '../domain/models/buyer_order.dart';

final kBuyerOrdersMock = <BuyerOrder>[
  BuyerOrder(
    id: '274A3B76',
    productLabel: '1.02ct Round D VVS1',
    sellerName: 'GemVault',
    status: 'Out For Delivery',
    carrier: 'BlueDart',
    location: 'Mumbai hub',
    trackingNumber: 'BD456Y78',
    updatedAt: '21/07/2026, 16:39:04',
    timeline: const [
      BuyerOrderTimelineEntry(
        title: 'Out For Delivery · Mumbai hub',
        subtitle: 'Courier is on the way',
        at: '21/07/2026, 16:39:04',
      ),
      BuyerOrderTimelineEntry(
        title: 'Shipped',
        subtitle: 'Shipment created · Status: SHIPPED',
        at: '13/07/2026, 23:23:33',
      ),
      BuyerOrderTimelineEntry(
        title: 'Order confirmed',
        subtitle: 'Payment received',
        at: '12/07/2026, 10:05:00',
      ),
    ],
  ),
  BuyerOrder(
    id: '9D38AA35',
    productLabel: '0.71ct Oval F VVS2',
    sellerName: 'Sparkle Co',
    status: 'Processing',
    carrier: 'Delhivery',
    location: 'Seller warehouse',
    trackingNumber: 'DL99821',
    updatedAt: '20/07/2026, 11:12:00',
    timeline: const [
      BuyerOrderTimelineEntry(
        title: 'Processing',
        subtitle: 'Seller is preparing your order',
        at: '20/07/2026, 11:12:00',
      ),
      BuyerOrderTimelineEntry(
        title: 'Order confirmed',
        subtitle: 'Payment received',
        at: '19/07/2026, 18:40:00',
      ),
    ],
  ),
  BuyerOrder(
    id: 'A11C90EF',
    productLabel: 'Burmese Ruby 2.14ct',
    sellerName: 'Ruby House',
    status: 'Delivered',
    carrier: 'Delhivery',
    location: 'Pune',
    trackingNumber: 'DL44210',
    updatedAt: '18/07/2026, 09:05:22',
    timeline: const [
      BuyerOrderTimelineEntry(
        title: 'Delivered · Pune',
        subtitle: 'Signed by recipient',
        at: '18/07/2026, 09:05:22',
      ),
      BuyerOrderTimelineEntry(
        title: 'Out For Delivery',
        subtitle: 'Local hub dispatch',
        at: '18/07/2026, 07:40:00',
      ),
    ],
  ),
];

BuyerOrder? findBuyerOrderById(String id) {
  for (final o in kBuyerOrdersMock) {
    if (o.id == id) return o;
  }
  return null;
}
