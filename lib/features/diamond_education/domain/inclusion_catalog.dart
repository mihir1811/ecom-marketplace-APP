import 'diamond_grades.dart';

/// Whether a clarity characteristic stays wholly inside the stone or
/// breaks its polished surface. Open ones are the durability concern:
/// a knock can spread a crack that already reaches the surface, dirt
/// collects in openings, and only an open fracture can be glass filled.
enum InclusionReach { closed, open }

/// What a clarity characteristic physically is.
enum InclusionFamily {
  /// A solid crystal of another mineral, or of diamond, trapped as the
  /// stone grew (pinpoints and clouds are the smallest of these).
  mineral,

  /// A break in the crystal: feathers and their kin.
  fracture,

  /// Irregular crystal growth: graining, twinning, the rough's skin.
  growth,

  /// Damage from cutting or wear.
  damage,

  /// Dissolved away by fluids in the earth after the stone formed.
  etching,

  /// Left by a treatment that hides other inclusions.
  treatment,
}

/// When a clarity characteristic came about.
enum InclusionOrigin {
  /// Grew with the diamond (or before it, and was engulfed).
  growth,

  /// Formed in the earth after the stone had grown: stress fractures,
  /// etching.
  afterGrowth,

  /// From cutting, polishing or wear.
  cutting,

  /// From a treatment.
  treatment,
}

/// A three step scale for how much a characteristic matters.
enum InclusionLevel { none, low, medium, high }

/// How a clarity characteristic is classed, as a grader would explain it.
class InclusionClass {
  const InclusionClass({
    required this.reach,
    required this.family,
    required this.origin,
    required this.clarity,
    required this.durability,
  });

  final InclusionReach reach;
  final InclusionFamily family;
  final InclusionOrigin origin;

  /// How much it typically lowers the clarity grade.
  final InclusionLevel clarity;

  /// How much it typically risks the stone's durability.
  final InclusionLevel durability;
}

extension InclusionTypeClass on InclusionType {
  /// Classed after GIA's clarity characteristic definitions and common
  /// grading practice: surface-reaching feathers, chips and cavities are
  /// the durability risks; pinpoints, needles and graining rarely matter.
  InclusionClass get info => switch (this) {
    InclusionType.pinpoint => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.none,
    ),
    InclusionType.cloud => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.low,
    ),
    InclusionType.needle => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.low,
    ),
    InclusionType.crystal => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.low,
    ),
    InclusionType.carbon => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.high,
      durability: InclusionLevel.low,
    ),
    InclusionType.feather => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.fracture,
      origin: InclusionOrigin.afterGrowth,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.low,
    ),
    InclusionType.graining => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.growth,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.none,
    ),
    InclusionType.twinningWisp => const InclusionClass(
      reach: InclusionReach.closed,
      family: InclusionFamily.growth,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.low,
    ),
    InclusionType.openFeather => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.fracture,
      origin: InclusionOrigin.afterGrowth,
      clarity: InclusionLevel.high,
      durability: InclusionLevel.high,
    ),
    InclusionType.knot => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.mineral,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.medium,
    ),
    InclusionType.cavity => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.damage,
      origin: InclusionOrigin.cutting,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.medium,
    ),
    InclusionType.chip => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.damage,
      origin: InclusionOrigin.cutting,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.high,
    ),
    InclusionType.bruise => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.damage,
      origin: InclusionOrigin.cutting,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.medium,
    ),
    InclusionType.bearding => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.fracture,
      origin: InclusionOrigin.cutting,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.medium,
    ),
    InclusionType.indentedNatural => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.growth,
      origin: InclusionOrigin.growth,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.low,
    ),
    InclusionType.etchChannel => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.etching,
      origin: InclusionOrigin.afterGrowth,
      clarity: InclusionLevel.low,
      durability: InclusionLevel.low,
    ),
    InclusionType.laserDrillHole => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.treatment,
      origin: InclusionOrigin.treatment,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.low,
    ),
    InclusionType.filledFeather => const InclusionClass(
      reach: InclusionReach.open,
      family: InclusionFamily.treatment,
      origin: InclusionOrigin.treatment,
      clarity: InclusionLevel.medium,
      durability: InclusionLevel.medium,
    ),
  };

  bool get isOpen => info.reach == InclusionReach.open;
}
