class SellerOrder {
  const SellerOrder({
    required this.id,
    required this.status,
    required this.carrier,
    required this.location,
    required this.trackingNumber,
    required this.updatedAt,
    required this.timeline,
  });

  final String id;
  final String status;
  final String carrier;
  final String location;
  final String trackingNumber;
  final String updatedAt;
  final List<SellerOrderTimelineEntry> timeline;
}

class SellerOrderTimelineEntry {
  const SellerOrderTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final String title;
  final String subtitle;
  final String at;
}

class SellerRefund {
  const SellerRefund({
    required this.id,
    required this.status,
    required this.amountLabel,
    required this.buyer,
    required this.orderId,
    required this.requestedAt,
    required this.buyerReason,
    this.sellerNote,
  });

  final String id;
  final SellerRefundStatus status;
  final String amountLabel;
  final String buyer;
  final String orderId;
  final String requestedAt;
  final String buyerReason;
  final String? sellerNote;
}

enum SellerRefundStatus { accepted, rejected, pending }

class SellerAuction {
  const SellerAuction({
    required this.id,
    required this.productLabel,
    required this.category,
    required this.status,
    required this.minBid,
    required this.currentBid,
    required this.startsAt,
    required this.endsAt,
    required this.bids,
  });

  final String id;
  final String productLabel;
  final String category;
  final SellerAuctionStatus status;
  final String minBid;
  final String currentBid;
  final String startsAt;
  final String endsAt;
  final List<SellerAuctionBid> bids;
}

enum SellerAuctionStatus { active, upcoming, ended }

class SellerAuctionBid {
  const SellerAuctionBid({
    required this.amount,
    required this.bidder,
    required this.email,
    required this.at,
    this.isHighest = false,
  });

  final String amount;
  final String bidder;
  final String email;
  final String at;
  final bool isHighest;
}

enum SellerOfferStatus { pending, accepted, rejected, countered }

class SellerOffer {
  const SellerOffer({
    required this.id,
    required this.productLabel,
    required this.stockNumber,
    required this.category,
    required this.buyer,
    required this.buyerEmail,
    required this.listPrice,
    required this.offerPrice,
    required this.status,
    required this.createdAt,
    this.counterPrice,
    this.message,
  });

  final String id;
  final String productLabel;
  final String stockNumber;
  final String category;
  final String buyer;
  final String buyerEmail;
  final String listPrice;
  final String offerPrice;
  final String? counterPrice;
  final SellerOfferStatus status;
  final String createdAt;
  final String? message;

  SellerOffer copyWith({
    SellerOfferStatus? status,
    String? counterPrice,
  }) {
    return SellerOffer(
      id: id,
      productLabel: productLabel,
      stockNumber: stockNumber,
      category: category,
      buyer: buyer,
      buyerEmail: buyerEmail,
      listPrice: listPrice,
      offerPrice: offerPrice,
      counterPrice: counterPrice ?? this.counterPrice,
      status: status ?? this.status,
      createdAt: createdAt,
      message: message,
    );
  }
}
