enum ProductOfferStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected'),
  expired('EXPIRED', 'Expired');

  const ProductOfferStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ProductOfferStatus fromApi(String? raw) {
    for (final status in ProductOfferStatus.values) {
      if (status.apiValue == raw) return status;
    }
    return ProductOfferStatus.pending;
  }

  bool get isPending => this == ProductOfferStatus.pending;
}

class ProductOffer {
  const ProductOffer({
    required this.id,
    required this.productId,
    required this.productType,
    required this.buyerId,
    required this.sellerId,
    required this.amount,
    required this.status,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    this.message,
    this.productLabel,
    this.stockNumber,
    this.listPrice,
    this.buyerName,
    this.buyerEmail,
  });

  final String id;
  final String productId;
  final String productType;
  final String buyerId;
  final String sellerId;
  final double amount;
  final ProductOfferStatus status;
  final String? message;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String? productLabel;
  final String? stockNumber;
  final double? listPrice;
  final String? buyerName;
  final String? buyerEmail;
}

class ProductOfferListPage {
  const ProductOfferListPage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.hasMore,
  });

  final List<ProductOffer> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final bool hasMore;
}
