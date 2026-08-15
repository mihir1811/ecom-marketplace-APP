/// Lean stone snapshot used for local stats and project persistence.
class DiamondProjectItem {
  const DiamondProjectItem({
    required this.diamondId,
    this.rowId,
    this.productKind = 'SINGLE',
    this.stockNumber,
    this.shape,
    this.color,
    this.clarity,
    this.cut,
    this.carat = 0,
    this.price = 0,
    this.pricePerCarat,
  });

  final String diamondId;
  final String? rowId;
  final String productKind;
  final String? stockNumber;
  final String? shape;
  final String? color;
  final String? clarity;
  final String? cut;
  final double carat;
  final double price;
  final double? pricePerCarat;

  double get ppc {
    final stored = pricePerCarat;
    if (stored != null && stored > 0) return stored;
    if (carat <= 0) return 0;
    return price / carat;
  }

  String get stockLabel {
    final stock = stockNumber?.trim();
    if (stock != null && stock.isNotEmpty) return stock;
    if (diamondId.length <= 10) return diamondId;
    return diamondId.substring(0, 8);
  }
}
