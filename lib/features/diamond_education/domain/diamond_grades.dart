import 'dart:math' as math;

/// Linear RGB triple, 0..1 per channel (absorption, emission, tints).
typedef SimRgb = ({double r, double g, double b});

/// GIA colour scale for white diamonds, D (colourless) to Z (light yellow).
enum ColorGrade {
  d,
  e,
  f,
  g,
  h,
  i,
  j,
  k,
  l,
  m,
  n,
  o,
  p,
  q,
  r,
  s,
  t,
  u,
  v,
  w,
  x,
  y,
  z;

  String get label => name.toUpperCase();

  /// Colour group this grade belongs to.
  ColorGroup get group => switch (index) {
    <= 2 => ColorGroup.colorless,
    <= 6 => ColorGroup.nearColorless,
    <= 9 => ColorGroup.faint,
    <= 14 => ColorGroup.veryLight,
    _ => ColorGroup.light,
  };

  /// Body absorption per unit path (half-widths) for this grade: nitrogen
  /// soaks up blue first, so stones warm toward yellow down the scale.
  SimRgb get absorption {
    final k = math.pow(index / 22, 1.25).toDouble();
    return (r: 0.002 * k, g: 0.014 * k, b: 0.17 * k);
  }
}

/// Named bands of the D–Z scale.
enum ColorGroup { colorless, nearColorless, faint, veryLight, light }

/// Natural fancy colours the simulator can tint a stone with.
enum FancyColor {
  yellow(r: 0.0, g: 0.07, b: 0.55),
  pink(r: 0.0, g: 0.36, b: 0.13),
  blue(r: 0.46, g: 0.16, b: 0.0),
  green(r: 0.38, g: 0.0, b: 0.34),
  orange(r: 0.0, g: 0.24, b: 0.62),
  purple(r: 0.14, g: 0.42, b: 0.02),
  champagne(r: 0.08, g: 0.17, b: 0.36);

  const FancyColor({required this.r, required this.g, required this.b});

  /// Absorption at "Fancy Intense" saturation.
  final double r, g, b;

  /// Display swatch (sRGB), as the stone reads face up.
  SimRgb get swatch {
    double t(double a) => math.exp(-a * 2.6);
    return (r: t(r), g: t(g), b: t(b));
  }
}

/// GIA fancy colour saturation, lightest to deepest.
enum FancyIntensity {
  fancyLight(0.4),
  fancy(0.7),
  fancyIntense(1.0),
  fancyVivid(1.45),
  fancyDeep(2.2);

  const FancyIntensity(this.strength);

  /// Multiplier on the fancy colour's absorption.
  final double strength;
}

/// GIA clarity scale.
enum ClarityGrade {
  fl('FL'),
  internallyFlawless('IF'),
  vvs1('VVS1'),
  vvs2('VVS2'),
  vs1('VS1'),
  vs2('VS2'),
  si1('SI1'),
  si2('SI2'),
  i1('I1'),
  i2('I2'),
  i3('I3');

  const ClarityGrade(this.label);

  final String label;

  /// Milky scatter from clouds in the lowest grades, per unit path.
  double get haze => switch (this) {
    ClarityGrade.si2 => 0.01,
    ClarityGrade.i1 => 0.03,
    ClarityGrade.i2 => 0.07,
    ClarityGrade.i3 => 0.13,
    _ => 0,
  };
}

/// Kinds of clarity characteristic, as GIA names them. GIA's plotting key
/// splits them into internal characteristics (inclusions, plotted red)
/// and external ones (blemishes, plotted green); see
/// `inclusion_catalog.dart` for how each is classed and plotted.
///
/// New kinds go at the end: a kind's index seeds where it sits.
enum InclusionType {
  crystal,
  carbon,
  feather,
  cloud,
  pinpoint,
  needle,
  graining,
  twinningWisp,
  openFeather,
  knot,
  cavity,
  chip,
  bruise,
  bearding,
  indentedNatural,
  etchChannel,
  laserDrillHole,
  filledFeather,
  cleavage,
  grainCenter,
  abrasion,
  natural,
  nick,
  pit,
  polishLines,
  burnMark,
  scratch,
  surfaceGraining,
  extraFacet,
}

/// Strength of a brown or green body tinge (the B and G of BGM).
enum TingeLevel {
  none(0),
  faint(0.4),
  light(0.75),
  medium(1.1),
  strong(1.6);

  const TingeLevel(this.strength);

  /// Multiplier on the tinge's absorption.
  final double strength;

  /// Absorption per unit path of a medium brown tinge: brown soaks up
  /// blue, then green, and leaves red.
  static const SimRgb brown = (r: 0.03, g: 0.075, b: 0.16);

  /// Absorption per unit path of a medium green tinge: soaks up red and
  /// some blue.
  static const SimRgb green = (r: 0.14, g: 0.01, b: 0.09);
}

/// Milkiness (the M of BGM): a hazy veil from sub-microscopic clouds
/// that scatters light and dulls brilliance. [catalogValue] is the
/// shared catalog label key.
enum MilkyLevel {
  none('None', 0),
  slightly('Slightly', 0.025),
  moderately('Moderately', 0.05),
  strongly('Strongly', 0.085),
  severely('Severely', 0.13);

  const MilkyLevel(this.catalogValue, this.scatter);

  final String catalogValue;

  /// Scatter per unit path.
  final double scatter;
}

/// Treatments applied after cutting to improve how a stone looks.
/// [catalogValue] is the shared catalog label key.
enum Enhancement {
  none('None (Treatment)'),
  hpht('HPHT (Treatment)'),
  irradiation('Irradiation'),
  fractureFilling('Fracture Filling'),
  laserDrilling('Laser Drilling'),
  surfaceCoating('Surface Coating');

  const Enhancement(this.catalogValue);

  final String catalogValue;

  /// Whether this treatment changes the stone's inclusions.
  bool get altersInclusions =>
      this == Enhancement.fractureFilling || this == Enhancement.laserDrilling;
}

/// Overall cut grade, from proportions.
enum CutGrade { excellent, veryGood, good, fair, poor }

/// Strength of a stone's glow under ultraviolet light. [catalogValue] is
/// the shared catalog label key.
enum FluorescenceIntensity {
  none('None', 0),
  faint('Faint', 0.18),
  medium('Medium', 0.42),
  strong('Strong', 0.72),
  veryStrong('Very Strong', 1);

  const FluorescenceIntensity(this.catalogValue, this.strength);

  final String catalogValue;
  final double strength;
}

/// Colour of the fluorescent glow; blue is by far the most common.
enum FluorescenceColor {
  blue('Blue', r: 0.28, g: 0.5, b: 1.0),
  white('White', r: 0.9, g: 0.93, b: 1.0),
  yellow('Yellow', r: 1.0, g: 0.86, b: 0.25),
  green('Green', r: 0.35, g: 1.0, b: 0.45),
  orange('Orange', r: 1.0, g: 0.55, b: 0.18);

  const FluorescenceColor(
    this.catalogValue, {
    required this.r,
    required this.g,
    required this.b,
  });

  final String catalogValue;
  final double r, g, b;
}

/// GIA girdle thickness bands; [percent] is the thinnest point as a
/// percentage of the stone's width.
enum GirdleThickness {
  extremelyThin(0.6),
  veryThin(1.2),
  thin(2.0),
  medium(3.0),
  slightlyThick(4.0),
  thick(5.3),
  veryThick(7.0),
  extremelyThick(9.5);

  const GirdleThickness(this.percent);

  final double percent;
}

/// GIA culet size bands; [percent] is the culet facet's width as a
/// percentage of the stone's width (0 is a pointed culet).
enum CuletSize {
  none(0),
  verySmall(0.8),
  small(1.6),
  medium(3.0),
  slightlyLarge(4.5),
  large(6.0),
  veryLarge(8.0),
  extremelyLarge(11.0);

  const CuletSize(this.percent);

  final double percent;
}

/// Lighting the simulator studio is set to. [heartsArrows] is a hearts &
/// arrows scope: a red filter cone around a white disc and a dark viewing
/// hole, which reveals the eight arrows and hearts of a precisely cut
/// round brilliant.
enum SimLighting { daylight, ultraviolet, heartsArrows }
