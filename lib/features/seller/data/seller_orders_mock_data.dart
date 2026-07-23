import '../domain/models/seller_orders_models.dart';

final kSellerOrdersMock = <SellerOrder>[
  SellerOrder(
    id: '274A3B76',
    status: 'Out For Delivery',
    carrier: 'fvg',
    location: 'ghv',
    trackingNumber: 'fbg456y',
    updatedAt: '21/07/2026, 16:39:04',
    timeline: const [
      SellerOrderTimelineEntry(
        title: 'Out For Delivery · ghv',
        subtitle: 'fb',
        at: '21/07/2026, 16:39:04',
      ),
      SellerOrderTimelineEntry(
        title: 'Shipped',
        subtitle: 'Shipment created · Status: SHIPPED',
        at: '13/07/2026, 23:23:33',
      ),
    ],
  ),
  SellerOrder(
    id: '9D38AA35',
    status: 'Processing',
    carrier: 'BlueDart',
    location: 'Mumbai',
    trackingNumber: 'BD99821',
    updatedAt: '20/07/2026, 11:12:00',
    timeline: const [
      SellerOrderTimelineEntry(
        title: 'Processing',
        subtitle: 'Order confirmed · awaiting pack',
        at: '20/07/2026, 11:12:00',
      ),
    ],
  ),
  SellerOrder(
    id: 'A11C90EF',
    status: 'Delivered',
    carrier: 'Delhivery',
    location: 'Pune',
    trackingNumber: 'DL44210',
    updatedAt: '18/07/2026, 09:05:22',
    timeline: const [
      SellerOrderTimelineEntry(
        title: 'Delivered · Pune',
        subtitle: 'Signed by recipient',
        at: '18/07/2026, 09:05:22',
      ),
      SellerOrderTimelineEntry(
        title: 'Out For Delivery',
        subtitle: 'Local hub dispatch',
        at: '18/07/2026, 07:40:00',
      ),
    ],
  ),
];

SellerOrder? findSellerOrderById(String id) {
  for (final o in kSellerOrdersMock) {
    if (o.id == id) return o;
  }
  return null;
}

final kSellerRefundsMock = <SellerRefund>[
  const SellerRefund(
    id: 'r1',
    status: SellerRefundStatus.accepted,
    amountLabel: '₹2',
    buyer: 'monk',
    orderId: '9D38AA35',
    requestedAt: '13/07/2026, 16:15:31',
    buyerReason: 'dsfgxdsfg',
  ),
  const SellerRefund(
    id: 'r2',
    status: SellerRefundStatus.rejected,
    amountLabel: '₹2',
    buyer: 'monk',
    orderId: '9D38AA35',
    requestedAt: '13/07/2026, 15:36:30',
    buyerReason: 'fghjgfh',
    sellerNote: 'noo',
  ),
];

final kSellerAuctionsMock = <SellerAuction>[
  SellerAuction(
    id: '9',
    productLabel: 'mt507-74',
    category: 'Diamond',
    status: SellerAuctionStatus.ended,
    minBid: r'$400',
    currentBid: r'$460',
    startsAt: '09/07/2026, 10:43:00',
    endsAt: '09/07/2026, 10:47:43',
    bids: const [
      SellerAuctionBid(
        amount: r'$460',
        bidder: 'tttt',
        email: 'tttt@gmail.com',
        at: '09/07/2026, 10:47:20',
        isHighest: true,
      ),
      SellerAuctionBid(
        amount: r'$450',
        bidder: 'tttt',
        email: 'tttt@gmail.com',
        at: '09/07/2026, 10:46:50',
      ),
      SellerAuctionBid(
        amount: r'$410',
        bidder: 'tttt',
        email: 'tttt@gmail.com',
        at: '09/07/2026, 10:45:10',
      ),
      SellerAuctionBid(
        amount: r'$405',
        bidder: 'tttt',
        email: 'tttt@gmail.com',
        at: '09/07/2026, 10:44:01',
      ),
    ],
  ),
  SellerAuction(
    id: '12',
    productLabel: 'th555-22',
    category: 'Diamond',
    status: SellerAuctionStatus.active,
    minBid: r'$200',
    currentBid: r'$275',
    startsAt: '21/07/2026, 09:00:00',
    endsAt: '22/07/2026, 09:00:00',
    bids: const [
      SellerAuctionBid(
        amount: r'$275',
        bidder: 'alex',
        email: 'alex@mail.com',
        at: '21/07/2026, 14:20:00',
        isHighest: true,
      ),
      SellerAuctionBid(
        amount: r'$250',
        bidder: 'sam',
        email: 'sam@mail.com',
        at: '21/07/2026, 12:05:00',
      ),
    ],
  ),
  SellerAuction(
    id: '15',
    productLabel: 'lk512-18',
    category: 'Diamond',
    status: SellerAuctionStatus.upcoming,
    minBid: r'$150',
    currentBid: r'$150',
    startsAt: '25/07/2026, 10:00:00',
    endsAt: '26/07/2026, 10:00:00',
    bids: const [],
  ),
];

final kSellerOffersMock = <SellerOffer>[
  const SellerOffer(
    id: 'o1',
    productLabel: '1.02ct Round G VS1',
    stockNumber: 'mt507-74',
    category: 'Diamond',
    buyer: 'alex',
    buyerEmail: 'alex@mail.com',
    listPrice: r'$4,850',
    offerPrice: r'$4,400',
    status: SellerOfferStatus.pending,
    createdAt: '22/07/2026, 11:20:00',
    message: 'Can you do better on this stone?',
  ),
  const SellerOffer(
    id: 'o2',
    productLabel: '0.71ct Oval F VVS2',
    stockNumber: 'th555-22',
    category: 'Diamond',
    buyer: 'sam',
    buyerEmail: 'sam@mail.com',
    listPrice: r'$3,200',
    offerPrice: r'$2,950',
    status: SellerOfferStatus.pending,
    createdAt: '22/07/2026, 09:05:00',
  ),
  const SellerOffer(
    id: 'o3',
    productLabel: 'Emerald cut sapphire 2.1ct',
    stockNumber: 'gs881-09',
    category: 'Gemstone',
    buyer: 'monk',
    buyerEmail: 'monk@mail.com',
    listPrice: r'$1,800',
    offerPrice: r'$1,550',
    counterPrice: r'$1,700',
    status: SellerOfferStatus.countered,
    createdAt: '21/07/2026, 16:40:00',
    message: 'Budget is tight this month.',
  ),
  const SellerOffer(
    id: 'o4',
    productLabel: '0.50ct Princess H SI1',
    stockNumber: 'lk512-18',
    category: 'Diamond',
    buyer: 'tttt',
    buyerEmail: 'tttt@gmail.com',
    listPrice: r'$980',
    offerPrice: r'$920',
    status: SellerOfferStatus.accepted,
    createdAt: '20/07/2026, 14:12:00',
  ),
  const SellerOffer(
    id: 'o5',
    productLabel: 'Pearl strand 18"',
    stockNumber: 'jw220-01',
    category: 'Jewelry',
    buyer: 'rina',
    buyerEmail: 'rina@mail.com',
    listPrice: r'$640',
    offerPrice: r'$400',
    status: SellerOfferStatus.rejected,
    createdAt: '19/07/2026, 10:30:00',
    message: 'Too low vs wholesale.',
  ),
];
