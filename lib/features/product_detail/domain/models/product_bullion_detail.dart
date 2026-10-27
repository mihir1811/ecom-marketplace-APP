/// Bullion-only layout data for Overview / Specifications / Seller tabs.
class ProductBullionDetail {
  const ProductBullionDetail({required this.overview, required this.specRows});

  final String overview;
  final List<ProductBullionSpecRow> specRows;
}

class ProductBullionSpecRow {
  const ProductBullionSpecRow(this.label, this.value);

  final String label;
  final String value;
}
