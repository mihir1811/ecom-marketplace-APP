/// A single line item in the buyer cart.
class CartItem {
  const CartItem({
    required this.id,
    required this.title,
    required this.category,
    required this.priceUsd,
    required this.priceInr,
    this.imageUrl,
    this.shape,
  });

  final String id;
  final String title;
  final String category;
  final double priceUsd;
  final double priceInr;
  final String? imageUrl;
  final String? shape;
}
