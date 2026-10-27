/// A single line item in the buyer cart (hydrated from GET /cart + summary).
class CartItem {
  const CartItem({
    required this.cartId,
    required this.productId,
    required this.productType,
    required this.title,
    required this.category,
    required this.quantity,
    required this.priceUsd,
    this.unitPriceUsd,
    this.lineTotalUsd,
    this.imageUrl,
    this.shape,
    this.seller,
    this.sellerId,
    this.quantityEditable = false,
    this.isAvailable = true,
    this.availabilityLabel,
    this.offerId,
    this.listedPriceUsd,
  });

  /// Cart row id — use as `cartId` for update/remove.
  final String cartId;
  final String productId;
  final String productType;
  final String title;
  final String category;
  final int quantity;
  final double priceUsd;
  final double? unitPriceUsd;
  final double? lineTotalUsd;
  final String? imageUrl;
  final String? shape;
  final String? seller;
  final String? sellerId;

  /// False for unique SKUs that reject quantity changes.
  final bool quantityEditable;

  /// False when the product is sold / delisted and must not count toward totals.
  final bool isAvailable;

  /// Short UI label when [isAvailable] is false (e.g. `Sold`, `Unavailable`).
  final String? availabilityLabel;

  /// Accepted offer this line is bought through (`specifications.offerId`).
  final String? offerId;

  /// Original list price of an offer line; the line itself is priced at the
  /// offered amount.
  final double? listedPriceUsd;

  bool get isOfferLine => offerId != null;

  String get id => cartId;

  double get displayPriceUsd => lineTotalUsd ?? priceUsd;

  CartItem copyWith({
    String? title,
    int? quantity,
    double? unitPriceUsd,
    double? lineTotalUsd,
    double? priceUsd,
    bool? isAvailable,
    String? availabilityLabel,
  }) {
    return CartItem(
      cartId: cartId,
      productId: productId,
      productType: productType,
      title: title ?? this.title,
      category: category,
      quantity: quantity ?? this.quantity,
      priceUsd: priceUsd ?? this.priceUsd,
      unitPriceUsd: unitPriceUsd ?? this.unitPriceUsd,
      lineTotalUsd: lineTotalUsd ?? this.lineTotalUsd,
      imageUrl: imageUrl,
      shape: shape,
      seller: seller,
      sellerId: sellerId,
      quantityEditable: quantityEditable,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityLabel: availabilityLabel ?? this.availabilityLabel,
      offerId: offerId,
      listedPriceUsd: listedPriceUsd,
    );
  }
}
