import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The metal of the solitaire rings on the hand.
enum RingMetal {
  yellowGold(0.98, 0.76, 0.4, Color(0xFFE2BE6A)),
  whiteGold(0.78, 0.78, 0.77, Color(0xFFE4E4E2)),
  roseGold(0.98, 0.64, 0.52, Color(0xFFE8B4A0)),
  platinum(0.71, 0.69, 0.66, Color(0xFFCFCDCB));

  const RingMetal(this.r, this.g, this.b, this.swatch);

  /// Reflectance at normal incidence (F0), linear RGB: 18K yellow and
  /// rose gold, rhodium-plated white gold, platinum (Real-Time Rendering,
  /// 4th ed., table 9.2).
  final double r, g, b;

  /// A flat colour for its swatch.
  final Color swatch;
}

/// How many claws hold the stone.
enum RingProngs {
  four(4),
  six(6);

  const RingProngs(this.count);

  final int count;
}

/// A plain solitaire: a comfort-fit band with a claw head that grows
/// with the stone it holds.
@immutable
class RingStyle {
  const RingStyle({
    this.metal = RingMetal.yellowGold,
    this.prongs = RingProngs.four,
    this.bandWidth = 2.0,
  });

  final RingMetal metal;
  final RingProngs prongs;

  /// Width of the band along the finger, mm.
  final double bandWidth;

  static const double minBandWidth = 1.5, maxBandWidth = 4.0;

  /// Depth of the band from the skin out, mm.
  double get thickness => 1.35 + 0.1 * bandWidth;

  RingStyle copyWith({
    RingMetal? metal,
    RingProngs? prongs,
    double? bandWidth,
  }) => RingStyle(
    metal: metal ?? this.metal,
    prongs: prongs ?? this.prongs,
    bandWidth: (bandWidth ?? this.bandWidth).clamp(minBandWidth, maxBandWidth),
  );

  @override
  bool operator ==(Object other) =>
      other is RingStyle &&
      other.metal == metal &&
      other.prongs == prongs &&
      other.bandWidth == bandWidth;

  @override
  int get hashCode => Object.hash(metal, prongs, bandWidth);
}
