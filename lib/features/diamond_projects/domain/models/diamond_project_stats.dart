import 'diamond_project_item.dart';

/// Client-side analytics for a loaded diamond selection.
class DiamondProjectStats {
  const DiamondProjectStats({
    required this.stones,
    required this.totalCarat,
    required this.avgCarat,
    required this.totalPrice,
    required this.avgPrice,
    required this.avgPpc,
    required this.meanPrice,
    required this.medianPrice,
    required this.modePrice,
    required this.modeCount,
    required this.iqrLow,
    required this.iqrHigh,
    required this.outliers,
    required this.shapeMix,
    required this.colorMix,
    required this.clarityMix,
    required this.priceBuckets,
    required this.ppcBuckets,
    required this.caratBuckets,
    required this.scatter,
  });

  static const empty = DiamondProjectStats(
    stones: 0,
    totalCarat: 0,
    avgCarat: 0,
    totalPrice: 0,
    avgPrice: 0,
    avgPpc: 0,
    meanPrice: 0,
    medianPrice: 0,
    modePrice: 0,
    modeCount: 0,
    iqrLow: 0,
    iqrHigh: 0,
    outliers: [],
    shapeMix: [],
    colorMix: [],
    clarityMix: [],
    priceBuckets: [],
    ppcBuckets: [],
    caratBuckets: [],
    scatter: [],
  );

  final int stones;
  final double totalCarat;
  final double avgCarat;
  final double totalPrice;
  final double avgPrice;
  final double avgPpc;
  final double meanPrice;
  final double medianPrice;
  final double modePrice;
  final int modeCount;
  final double iqrLow;
  final double iqrHigh;
  final List<DiamondProjectOutlier> outliers;
  final List<NamedCount> shapeMix;
  final List<NamedCount> colorMix;
  final List<NamedCount> clarityMix;
  final List<NamedCount> priceBuckets;
  final List<NamedCount> ppcBuckets;
  final List<NamedCount> caratBuckets;
  final List<DiamondProjectScatterPoint> scatter;

  bool get isEmpty => stones == 0;
}

class NamedCount {
  const NamedCount({required this.label, required this.count});

  final String label;
  final int count;
}

class DiamondProjectOutlier {
  const DiamondProjectOutlier({
    required this.item,
    required this.isHigh,
  });

  final DiamondProjectItem item;
  final bool isHigh;
}

class DiamondProjectScatterPoint {
  const DiamondProjectScatterPoint({
    required this.item,
    required this.isOutlier,
  });

  final DiamondProjectItem item;
  final bool isOutlier;
}
