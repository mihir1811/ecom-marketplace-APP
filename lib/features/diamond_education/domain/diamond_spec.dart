import 'package:flutter/foundation.dart';

import 'diamond_grades.dart';
import 'diamond_proportions.dart';
import 'diamond_shape.dart';

/// Everything that describes the simulated stone: shape, the 4Cs,
/// fluorescence and cutting proportions.
@immutable
class DiamondSpec {
  const DiamondSpec({
    required this.shape,
    required this.proportions,
    this.colorGrade = ColorGrade.e,
    this.fancyColor,
    this.fancyIntensity = FancyIntensity.fancyIntense,
    this.clarity = ClarityGrade.vs1,
    this.carat = 1.0,
    this.fluorescence = FluorescenceIntensity.none,
    this.fluorescenceColor = FluorescenceColor.blue,
  });

  factory DiamondSpec.initial() => DiamondSpec(
    shape: SimShape.round,
    proportions: DiamondProportions.ideal(SimShape.round),
  );

  static const minCarat = 0.1, maxCarat = 5.0;

  final SimShape shape;
  final DiamondProportions proportions;

  /// D–Z grade; ignored while [fancyColor] is set.
  final ColorGrade colorGrade;

  /// Natural fancy colour, or null for the D–Z scale.
  final FancyColor? fancyColor;
  final FancyIntensity fancyIntensity;
  final ClarityGrade clarity;
  final double carat;
  final FluorescenceIntensity fluorescence;
  final FluorescenceColor fluorescenceColor;

  bool get isFancy => fancyColor != null;

  /// Body absorption per unit path length, from colour.
  SimRgb get absorption {
    final fancy = fancyColor;
    if (fancy == null) return colorGrade.absorption;
    final s = fancyIntensity.strength;
    // Deep stones also darken overall.
    final dark = fancyIntensity == FancyIntensity.fancyDeep ? 0.05 : 0.0;
    return (
      r: fancy.r * s + dark,
      g: fancy.g * s + dark,
      b: fancy.b * s + dark,
    );
  }

  DiamondSpec copyWith({
    SimShape? shape,
    DiamondProportions? proportions,
    ColorGrade? colorGrade,
    FancyColor? fancyColor,
    bool clearFancy = false,
    FancyIntensity? fancyIntensity,
    ClarityGrade? clarity,
    double? carat,
    FluorescenceIntensity? fluorescence,
    FluorescenceColor? fluorescenceColor,
  }) => DiamondSpec(
    shape: shape ?? this.shape,
    proportions: proportions ?? this.proportions,
    colorGrade: colorGrade ?? this.colorGrade,
    fancyColor: clearFancy ? null : (fancyColor ?? this.fancyColor),
    fancyIntensity: fancyIntensity ?? this.fancyIntensity,
    clarity: clarity ?? this.clarity,
    carat: (carat ?? this.carat).clamp(minCarat, maxCarat),
    fluorescence: fluorescence ?? this.fluorescence,
    fluorescenceColor: fluorescenceColor ?? this.fluorescenceColor,
  );

  @override
  bool operator ==(Object other) =>
      other is DiamondSpec &&
      other.shape == shape &&
      other.proportions == proportions &&
      other.colorGrade == colorGrade &&
      other.fancyColor == fancyColor &&
      other.fancyIntensity == fancyIntensity &&
      other.clarity == clarity &&
      other.carat == carat &&
      other.fluorescence == fluorescence &&
      other.fluorescenceColor == fluorescenceColor;

  @override
  int get hashCode => Object.hash(
    shape,
    proportions,
    colorGrade,
    fancyColor,
    fancyIntensity,
    clarity,
    carat,
    fluorescence,
    fluorescenceColor,
  );
}
