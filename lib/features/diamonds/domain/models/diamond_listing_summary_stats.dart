import 'diamond.dart';

/// Aggregate KPIs for loaded diamond listing rows (search API page data).
class DiamondListingSummaryStats {
  const DiamondListingSummaryStats({
    required this.pcs,
    required this.totalCarat,
    required this.pricePerCarat,
    required this.totalPrice,
    required this.avgTotal,
  });

  static const empty = DiamondListingSummaryStats(
    pcs: 0,
    totalCarat: 0,
    pricePerCarat: 0,
    totalPrice: 0,
    avgTotal: 0,
  );

  final int pcs;
  final double totalCarat;
  final double pricePerCarat;
  final double totalPrice;
  final double avgTotal;

  bool get isEmpty => pcs == 0;

  static DiamondListingSummaryStats fromDiamonds(List<Diamond> diamonds) {
    if (diamonds.isEmpty) return empty;

    final pcs = diamonds.length;
    final totalCarat = diamonds.fold<double>(0, (sum, d) => sum + d.carat);
    final totalPrice = diamonds.fold<double>(0, (sum, d) => sum + d.price);

    return DiamondListingSummaryStats(
      pcs: pcs,
      totalCarat: totalCarat,
      pricePerCarat: totalCarat > 0 ? totalPrice / totalCarat : 0,
      totalPrice: totalPrice,
      avgTotal: totalPrice / pcs,
    );
  }
}
