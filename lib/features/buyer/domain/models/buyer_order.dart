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
    this.sellerDecision,
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

  /// Combined seller approval (`PENDING` / `ACCEPTED` / `REJECTED`), or
  /// `null` when the API sent no decision data.
  final String? sellerDecision;

  /// Payment status, refined by the seller decision once the order is paid.
  String get displayStatus {
    if (status.toUpperCase() != 'PAID') return status;
    return switch (sellerDecision) {
      'PENDING' => 'Awaiting seller',
      'ACCEPTED' => 'Confirmed',
      'REJECTED' => 'Rejected',
      _ => status,
    };
  }
}
