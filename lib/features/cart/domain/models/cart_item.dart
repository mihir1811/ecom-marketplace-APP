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

  String get id => cartId;

  double get displayPriceUsd => lineTotalUsd ?? priceUsd;

  CartItem copyWith({
    int? quantity,
    double? unitPriceUsd,
    double? lineTotalUsd,
    double? priceUsd,
  }) {
    return CartItem(
      cartId: cartId,
      productId: productId,
      productType: productType,
      title: title,
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
    );
  }
}
