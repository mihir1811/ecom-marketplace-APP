enum ProductOfferStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected'),
  expired('EXPIRED', 'Expired');

  const ProductOfferStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ProductOfferStatus fromApi(String? raw) {
    final upper = raw?.trim().toUpperCase();
    for (final status in ProductOfferStatus.values) {
      if (status.apiValue == upper) return status;
    }
    return ProductOfferStatus.pending;
  }

  bool get isPending => this == ProductOfferStatus.pending;
}

/// Product types that can take offers (`productType` on the offer API).
abstract final class OfferProductType {
  static const String diamond = 'diamond';
  static const String meleeDiamond = 'meleeDiamond';
  static const String gemstone = 'gemstone';

  static const values = {diamond, meleeDiamond, gemstone};

  static bool supports(String productType) => values.contains(productType);
}

/// Default cap on offers one buyer may make on a stone, any status.
const int defaultMaxOfferAttemptsPerUser = 5;

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
    this.createdAt,
    this.acceptedAt,
    this.paidAt,
    this.paymentExpiresAt,
    this.message,
    this.productLabel,
    this.stockNumber,
    this.listPrice,
    this.buyerName,
    this.buyerEmail,
    this.imageUrl,
    this.productSpecs,
    this.certificateLabel,
    this.productIsSold = false,
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
  final DateTime? createdAt;

  /// Set when the seller accepts.
  final DateTime? acceptedAt;

  /// Set when the buyer's order is paid. `ACCEPTED` + [paidAt] = bought.
  final DateTime? paidAt;

  /// `acceptedAt + 24 h` while accepted and unpaid, otherwise null.
  final DateTime? paymentExpiresAt;
  final String? productLabel;
  final String? stockNumber;
  final double? listPrice;
  final String? buyerName;
  final String? buyerEmail;
  final String? imageUrl;
  final String? productSpecs;
  final String? certificateLabel;

  /// `product.isSold` from the buyer list snapshot.
  final bool productIsSold;

  /// Best available product title for list cards.
  String get displayTitle {
    final label = productLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final stock = stockNumber?.trim();
    if (stock != null && stock.isNotEmpty) return stock;
    return productTypeLabel;
  }

  String get productTypeLabel => switch (productType) {
    OfferProductType.diamond => 'Diamond',
    OfferProductType.meleeDiamond => 'Melee diamond',
    OfferProductType.gemstone => 'Gemstone',
    _ => productType,
  };

  bool get isPaid => status == ProductOfferStatus.accepted && paidAt != null;

  /// Accepted, unpaid and still inside the 24-hour window.
  bool get isPayable => isPayableAt(DateTime.now());

  bool isPayableAt(DateTime now) =>
      status == ProductOfferStatus.accepted &&
      paidAt == null &&
      paymentExpiresAt != null &&
      paymentExpiresAt!.isAfter(now);

  Duration get timeLeftToPay {
    final expires = paymentExpiresAt;
    if (expires == null) return Duration.zero;
    final left = expires.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Status shown to people: PAID is `ACCEPTED` with [paidAt] set.
  String get displayStatusLabel {
    if (isPaid) return 'Paid';
    if (status == ProductOfferStatus.accepted) {
      return isPayable ? 'Awaiting payment' : 'Accepted';
    }
    return status.label;
  }

  ProductOffer withProduct({
    String? productLabel,
    String? stockNumber,
    double? listPrice,
    String? imageUrl,
    String? productSpecs,
    String? certificateLabel,
  }) {
    return ProductOffer(
      id: id,
      productId: productId,
      productType: productType,
      buyerId: buyerId,
      sellerId: sellerId,
      amount: amount,
      status: status,
      createdAtLabel: createdAtLabel,
      updatedAtLabel: updatedAtLabel,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      paidAt: paidAt,
      paymentExpiresAt: paymentExpiresAt,
      message: message,
      productLabel: this.productLabel ?? productLabel,
      stockNumber: this.stockNumber ?? stockNumber,
      listPrice: this.listPrice ?? listPrice,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      imageUrl: this.imageUrl ?? imageUrl,
      productSpecs: this.productSpecs ?? productSpecs,
      certificateLabel: this.certificateLabel ?? certificateLabel,
      productIsSold: productIsSold,
    );
  }
}

/// What the product page may offer the signed-in buyer, from their own
/// offers on the stone (`GET /product-offer/mine/{type}/{id}`).
class ProductOfferEligibility {
  const ProductOfferEligibility({
    required this.offers,
    required this.maxAttempts,
  });

  static const empty = ProductOfferEligibility(
    offers: [],
    maxAttempts: defaultMaxOfferAttemptsPerUser,
  );

  final List<ProductOffer> offers;
  final int maxAttempts;

  ProductOffer? get payable {
    for (final o in offers) {
      if (o.isPayable) return o;
    }
    return null;
  }

  ProductOffer? get paid {
    for (final o in offers) {
      if (o.isPaid) return o;
    }
    return null;
  }

  bool get hasPending => offers.any((o) => o.status.isPending);

  /// Expired and rejected offers count towards the cap.
  bool get limitReached => offers.length >= maxAttempts;

  int get attemptsLeft =>
      (maxAttempts - offers.length).clamp(0, maxAttempts).toInt();

  bool get canSubmit =>
      payable == null && paid == null && !hasPending && !limitReached;
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
