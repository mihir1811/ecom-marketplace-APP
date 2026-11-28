enum ProductOfferStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected'),
  expired('EXPIRED', 'Expired'),

  /// Answered with a counter-offer, which is the next move of the
  /// negotiation.
  countered('COUNTERED', 'Countered');

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

  /// Whole parcels only; once a lot is sold or held no offers are taken.
  static const String roughDiamond = 'roughDiamond';

  static const values = {diamond, meleeDiamond, gemstone, roughDiamond};

  static bool supports(String productType) => values.contains(productType);
}

/// Default cap on offers and counter-offers per buyer per stone, any status.
const int defaultMaxOfferAttemptsPerUser = 5;

/// One earlier move of a negotiation (`history` on list rows), oldest first.
class OfferMove {
  const OfferMove({
    required this.id,
    required this.amount,
    required this.fromSeller,
    required this.status,
    this.message,
    this.createdAt,
  });

  final String id;
  final double amount;

  /// True on the seller's counter-offer.
  final bool fromSeller;
  final ProductOfferStatus status;
  final String? message;
  final DateTime? createdAt;
}

/// Pending offers and counter-offers expire 24 hours after they were made.
const Duration offerAnswerWindow = Duration(hours: 24);

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
    this.paymentWithGemworld = false,
    this.belowMinimum = false,
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
    this.fromSeller = false,
    this.counterToId,
    this.history = const [],
    this.attemptsUsed,
    this.maxAttempts,
    this.privateOffer = false,
    this.sellerName,
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

  /// `acceptedAt + 24 h` while accepted and unpaid, otherwise null (also
  /// null while [paymentWithGemworld]).
  final DateTime? paymentExpiresAt;

  /// GemWorld is collecting the payment (the order was over the online
  /// limit and the buyer chose Contact GemWorld). The 24-hour clock is
  /// paused: no countdown and no Pay now.
  final bool paymentWithGemworld;

  /// Seller's view only: the offer is under the seller's private minimum.
  /// While pending it is declined automatically within 10 minutes unless
  /// accepted; when rejected, it was declined automatically.
  final bool belowMinimum;
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

  /// True on the seller's counter-offer, which the buyer answers; false on
  /// the buyer's offers and counter-offers.
  final bool fromSeller;

  /// The offer this one answers (now `COUNTERED`); null on a first offer.
  final String? counterToId;

  /// Lists only: the negotiation's earlier moves, oldest first.
  final List<OfferMove> history;

  /// Lists only: offers and counter-offers so far in this buyer's
  /// negotiations on the stone, and the stone's cap. No counter or new offer
  /// once they are equal.
  final int? attemptsUsed;
  final int? maxAttempts;

  /// The seller started this negotiation from the buyer's cart (Interested
  /// buyers); no buyer offer came before it. Only the opening row carries it.
  final bool privateOffer;

  /// Seller's shop or display name, when the row includes it.
  final String? sellerName;

  /// No attempts left for another offer or counter-offer. Accept and
  /// decline still work.
  bool get attemptsExhausted =>
      attemptsUsed != null &&
      maxAttempts != null &&
      attemptsUsed! >= maxAttempts!;

  /// The seller's counter-offer, waiting for the buyer's answer.
  bool get isOpenCounter => status.isPending && fromSeller;

  /// The buyer's offer or counter-offer, waiting for the seller.
  bool get isAwaitingSeller => status.isPending && !fromSeller;

  /// When an unanswered pending move expires (`createdAt + 24 h`).
  DateTime? get answerExpiresAt => status.isPending && createdAt != null
      ? createdAt!.add(offerAnswerWindow)
      : null;

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

  /// Accepted, unpaid and with GemWorld arranging the payment.
  bool get isWithGemworld =>
      status == ProductOfferStatus.accepted &&
      paidAt == null &&
      paymentWithGemworld;

  /// Accepted, unpaid and still inside the 24-hour window.
  bool get isPayable => isPayableAt(DateTime.now());

  bool isPayableAt(DateTime now) =>
      status == ProductOfferStatus.accepted &&
      paidAt == null &&
      !paymentWithGemworld &&
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
    if (isWithGemworld) return 'With GemWorld';
    if (status == ProductOfferStatus.accepted) {
      return isPayable ? 'Awaiting payment' : 'Accepted';
    }
    if (isOpenCounter) return privateOffer ? 'Private offer' : 'Counter-offer';
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
      paymentWithGemworld: paymentWithGemworld,
      belowMinimum: belowMinimum,
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
      fromSeller: fromSeller,
      counterToId: counterToId,
      history: history,
      attemptsUsed: attemptsUsed,
      maxAttempts: maxAttempts,
      privateOffer: privateOffer,
      sellerName: sellerName,
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

  /// An accepted offer whose payment GemWorld is arranging.
  ProductOffer? get withGemworld {
    for (final o in offers) {
      if (o.isWithGemworld) return o;
    }
    return null;
  }

  ProductOffer? get paid {
    for (final o in offers) {
      if (o.isPaid) return o;
    }
    return null;
  }

  /// The seller's counter-offer waiting for this buyer.
  ProductOffer? get openCounter {
    for (final o in offers) {
      if (o.isOpenCounter) return o;
    }
    return null;
  }

  /// The buyer's own offer or counter-offer waiting for the seller.
  bool get hasPending => offers.any((o) => o.isAwaitingSeller);

  /// Every move counts towards the cap, any status, the seller's
  /// counter-offers included: with 5, an offer leaves 4 and a counter 3.
  bool get limitReached => offers.length >= maxAttempts;

  int get attemptsLeft =>
      (maxAttempts - offers.length).clamp(0, maxAttempts).toInt();

  bool get canSubmit =>
      payable == null &&
      paid == null &&
      withGemworld == null &&
      openCounter == null &&
      !hasPending &&
      !limitReached;
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
