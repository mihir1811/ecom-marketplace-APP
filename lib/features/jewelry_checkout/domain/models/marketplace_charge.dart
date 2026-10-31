/// One tax row GemWorld adds on top of the price, e.g. "GST (3%)" and its
/// amount in rupees. Quotes and orders send one row per tax and rate.
class MarketplaceCharge {
  const MarketplaceCharge({
    required this.label,
    required this.amount,
    this.name = '',
  });

  /// `GST`.
  final String name;

  /// `GST (3%)`, ready to show.
  final String label;
  final double amount;
}
