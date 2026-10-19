import 'package:flutter/foundation.dart';

import 'diamond_grades.dart';
import 'diamond_proportions.dart';
import 'diamond_shape.dart';

/// Everything that describes the simulated stone: shape, the 4Cs,
/// inclusions, BGM tinges, treatment, fluorescence and cutting
/// proportions.
@immutable
class DiamondSpec {
  const DiamondSpec({
    required this.shape,
    required this.proportions,
    this.colorGrade = ColorGrade.e,
    this.fancyColor,
    this.fancyIntensity = FancyIntensity.fancyIntense,
    this.clarity = ClarityGrade.vs1,
    this.inclusionTypes,
    this.brown = TingeLevel.none,
    this.green = TingeLevel.none,
    this.milky = MilkyLevel.none,
    this.enhancement = Enhancement.none,
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

  /// Inclusion kinds to show, or null for the clarity grade's usual mix.
  final Set<InclusionType>? inclusionTypes;
  final TingeLevel brown, green;
  final MilkyLevel milky;
  final Enhancement enhancement;
  final double carat;
  final FluorescenceIntensity fluorescence;
  final FluorescenceColor fluorescenceColor;

  bool get isFancy => fancyColor != null;

  bool get hasBgm =>
      brown != TingeLevel.none ||
      green != TingeLevel.none ||
      milky != MilkyLevel.none;

  /// Body absorption per unit path length, from colour, tinges and
  /// treatment.
  SimRgb get absorption {
    var (:r, :g, :b) = _bodyColor;
    if (enhancement == Enhancement.hpht && fancyColor == null) {
      // High pressure and heat anneal out most of the yellow and brown.
      r *= 0.25;
      g *= 0.25;
      b *= 0.25;
    }
    final bs = enhancement == Enhancement.hpht ? 0.0 : brown.strength;
    final gs = green.strength;
    r += TingeLevel.brown.r * bs + TingeLevel.green.r * gs;
    g += TingeLevel.brown.g * bs + TingeLevel.green.g * gs;
    b += TingeLevel.brown.b * bs + TingeLevel.green.b * gs;
    switch (enhancement) {
      case Enhancement.irradiation:
        // Radiation damage turns the body blue-green.
        r += 0.3;
        g += 0.05;
        b += 0.09;
      case Enhancement.surfaceCoating:
        // A thin bluish film masks the yellow, until it wears off.
        r += 0.05;
        g *= 0.5;
        b *= 0.3;
      default:
    }
    // Milky stones also lose a little light overall.
    final grey = milky.scatter * 0.25;
    return (r: r + grey, g: g + grey, b: b + grey);
  }

  SimRgb get _bodyColor {
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
    Set<InclusionType>? inclusionTypes,
    bool gradedInclusions = false,
    TingeLevel? brown,
    TingeLevel? green,
    MilkyLevel? milky,
    Enhancement? enhancement,
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
    inclusionTypes: gradedInclusions
        ? null
        : (inclusionTypes ?? this.inclusionTypes),
    brown: brown ?? this.brown,
    green: green ?? this.green,
    milky: milky ?? this.milky,
    enhancement: enhancement ?? this.enhancement,
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
      setEquals(other.inclusionTypes, inclusionTypes) &&
      other.brown == brown &&
      other.green == green &&
      other.milky == milky &&
      other.enhancement == enhancement &&
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
    inclusionTypes == null ? null : Object.hashAllUnordered(inclusionTypes!),
    brown,
    green,
    milky,
    enhancement,
    carat,
    fluorescence,
    fluorescenceColor,
  );
}
