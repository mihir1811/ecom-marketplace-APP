/// Linear RGB, 0..1.
typedef JRgb = ({double r, double g, double b});

/// The precious metals a piece can be made in.
enum JewelryMetal { yellowGold, whiteGold, roseGold, platinum, silver }

/// Fineness: how much of the alloy is the precious metal itself.
enum MetalPurity {
  k10('10K', 0.417),
  k14('14K', 0.585),
  k18('18K', 0.75),
  k22('22K', 0.916),
  pt950('PT950', 0.95),
  s925('925', 0.925);

  const MetalPurity(this.label, this.fineness);

  final String label;
  final double fineness;
}

/// Surface finish: how smooth the metal is polished, which sets how
/// sharply it mirrors the studio (microfacet roughness).
enum MetalFinish {
  polished(0.06),
  satin(0.24),
  matte(0.42);

  const MetalFinish(this.roughness);

  final double roughness;
}

extension JewelryMetalX on JewelryMetal {
  /// Purities this metal is sold in, most popular first.
  List<MetalPurity> get purities => switch (this) {
    JewelryMetal.yellowGold => const [
      MetalPurity.k18,
      MetalPurity.k14,
      MetalPurity.k22,
      MetalPurity.k10,
    ],
    JewelryMetal.whiteGold || JewelryMetal.roseGold => const [
      MetalPurity.k18,
      MetalPurity.k14,
      MetalPurity.k10,
    ],
    JewelryMetal.platinum => const [MetalPurity.pt950],
    JewelryMetal.silver => const [MetalPurity.s925],
  };

  MetalPurity get defaultPurity => purities.first;

  bool get isGold =>
      this == JewelryMetal.yellowGold ||
      this == JewelryMetal.whiteGold ||
      this == JewelryMetal.roseGold;

  /// Reflectance at normal incidence (F0), linear RGB. Metals have no
  /// diffuse colour: all of their colour is in this tinted reflection.
  /// Pure gold is (1.0, 0.77, 0.34); alloying it with silver and copper
  /// whitens it as the karat falls, copper warms rose gold, and white
  /// gold is plated in neutral rhodium. Values follow measured spectral
  /// reflectance (Real-Time Rendering, 4th ed., table 9.2).
  JRgb f0(MetalPurity purity) {
    switch (this) {
      case JewelryMetal.yellowGold:
        // Fineness 0.417..0.916 blends from pale 10K to rich 22K.
        final t = ((purity.fineness - 0.417) / (0.916 - 0.417)).clamp(0.0, 1.0);
        return (r: 0.96 + 0.04 * t, g: 0.82 - 0.11 * t, b: 0.55 - 0.26 * t);
      case JewelryMetal.roseGold:
        final t = ((purity.fineness - 0.417) / (0.75 - 0.417)).clamp(0.0, 1.0);
        return (r: 0.97 + 0.03 * t, g: 0.66 - 0.04 * t, b: 0.56 - 0.08 * t);
      case JewelryMetal.whiteGold:
        return (r: 0.78, g: 0.78, b: 0.77);
      case JewelryMetal.platinum:
        return (r: 0.71, g: 0.69, b: 0.66);
      case JewelryMetal.silver:
        return (r: 0.96, g: 0.94, b: 0.90);
    }
  }

  /// Alloy density, g/cm³ (equal to mg/mm³).
  double density(MetalPurity purity) => switch ((this, purity)) {
    (JewelryMetal.platinum, _) => 20.1,
    (JewelryMetal.silver, _) => 10.36,
    (JewelryMetal.yellowGold, MetalPurity.k22) => 17.7,
    (JewelryMetal.yellowGold, MetalPurity.k18) => 15.6,
    (JewelryMetal.yellowGold, MetalPurity.k10) => 11.6,
    (JewelryMetal.yellowGold, _) => 13.1,
    (JewelryMetal.whiteGold, MetalPurity.k18) => 14.7,
    (JewelryMetal.whiteGold, MetalPurity.k10) => 11.1,
    (JewelryMetal.whiteGold, _) => 12.9,
    (JewelryMetal.roseGold, MetalPurity.k18) => 15.0,
    (JewelryMetal.roseGold, MetalPurity.k10) => 11.5,
    (JewelryMetal.roseGold, _) => 13.0,
  };
}
