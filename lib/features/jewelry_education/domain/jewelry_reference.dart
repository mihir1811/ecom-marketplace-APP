/// The kinds of piece the jewelry education page explains.
enum JewelryType { ring, earrings, necklace, bracelet }

/// The precious metals a piece can be made in.
enum JewelryMetal { yellowGold, whiteGold, roseGold, platinum, silver }

/// Necklace lengths in inches, as sold.
enum ChainLength {
  in14(14),
  in16(16),
  in18(18),
  in20(20),
  in22(22),
  in24(24),
  in30(30);

  const ChainLength(this.inches);

  final int inches;

  double get mm => inches * 25.4;
}

/// Ring sizes on the US scale and their inside diameter.
abstract final class RingSizes {
  /// Inside diameter in mm (ISO 8653 via the US scale).
  static double diameterMm(double us) => 11.63 + 0.8128 * us;
}
