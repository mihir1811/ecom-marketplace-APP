/// Buyer-facing order summary (mapped from payment APIs).
class BuyerOrder {
  const BuyerOrder({
    required this.id,
    required this.productLabel,
    required this.sellerName,
    required this.status,
    required this.amountInr,
    required this.amountUsd,
    required this.currency,
    this.createdAt,
    this.itemCount = 0,
  });

  final String id;
  final String productLabel;
  final String sellerName;
  final String status;
  final double amountInr;
  final double amountUsd;
  final String currency;
  final DateTime? createdAt;
  final int itemCount;
}
