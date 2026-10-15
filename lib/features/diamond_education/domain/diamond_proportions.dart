import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'diamond_grades.dart';
import 'diamond_shape.dart';

/// Allowed slider ranges for each proportion.
abstract final class ProportionLimits {
  static const tableMin = 50.0, tableMax = 75.0;
  static const crownAngleMin = 22.0, crownAngleMax = 42.0;
  static const pavilionAngleMin = 36.5, pavilionAngleMax = 49.0;
}

/// A stone's cutting proportions. Table, angles, girdle and culet are the
/// free values; crown height, pavilion depth and total depth follow from
/// them, exactly as on a grading report.
@immutable
class DiamondProportions {
  const DiamondProportions({
    required this.tablePct,
    required this.crownAngle,
    required this.pavilionAngle,
    required this.girdle,
    required this.culet,
  });

  /// Table width as a percentage of the stone's width.
  final double tablePct;

  /// Crown and pavilion main facet angles to the girdle plane, degrees.
  final double crownAngle;
  final double pavilionAngle;
  final GirdleThickness girdle;
  final CuletSize culet;

  static const _cos8 = 0.9238795325112867; // cos(π / 8)

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;

  /// Culet half-width in half-width units.
  double get culetScale => culet.percent / 100;

  /// Pavilion mains run from the girdle to the culet edge; on brilliant
  /// cuts that edge sits at an eighth-turn to each main.
  static double _pavilionRun(SimCutFamily family, double culetScale) =>
      family == SimCutFamily.brilliant
      ? 1 - culetScale * _cos8
      : 1 - culetScale;

  /// Crown height, % of width.
  double get crownHeightPct =>
      math.tan(_rad(crownAngle)) * (1 - tablePct / 100) / 2 * 100;

  /// Pavilion depth, % of width.
  double pavilionDepthPct(SimCutFamily family) =>
      math.tan(_rad(pavilionAngle)) *
      _pavilionRun(family, culetScale) /
      2 *
      100;

  /// Total depth ignoring the girdle's scalloped edge, % of width. The
  /// simulator measures the exact value on the built stone.
  double approxDepthPct(SimCutFamily family) =>
      crownHeightPct + pavilionDepthPct(family) + girdle.percent;

  DiamondProportions copyWith({
    double? tablePct,
    double? crownAngle,
    double? pavilionAngle,
    GirdleThickness? girdle,
    CuletSize? culet,
  }) => DiamondProportions(
    tablePct: (tablePct ?? this.tablePct).clamp(
      ProportionLimits.tableMin,
      ProportionLimits.tableMax,
    ),
    crownAngle: (crownAngle ?? this.crownAngle).clamp(
      ProportionLimits.crownAngleMin,
      ProportionLimits.crownAngleMax,
    ),
    pavilionAngle: (pavilionAngle ?? this.pavilionAngle).clamp(
      ProportionLimits.pavilionAngleMin,
      ProportionLimits.pavilionAngleMax,
    ),
    girdle: girdle ?? this.girdle,
    culet: culet ?? this.culet,
  );

  /// Same table, with the crown angle that gives [pct] crown height.
  DiamondProportions withCrownHeight(double pct) {
    final run = 1 - tablePct / 100;
    return copyWith(crownAngle: _deg(math.atan(pct / 100 * 2 / run)));
  }

  /// Same culet, with the pavilion angle that gives [pct] pavilion depth.
  DiamondProportions withPavilionDepth(double pct, SimCutFamily family) {
    final run = _pavilionRun(family, culetScale);
    return copyWith(pavilionAngle: _deg(math.atan(pct / 100 * 2 / run)));
  }

  /// Crown height range reachable at the current table.
  (double, double) crownHeightRange() {
    final run = (1 - tablePct / 100) / 2 * 100;
    return (
      math.tan(_rad(ProportionLimits.crownAngleMin)) * run,
      math.tan(_rad(ProportionLimits.crownAngleMax)) * run,
    );
  }

  /// Pavilion depth range reachable with the current culet.
  (double, double) pavilionDepthRange(SimCutFamily family) {
    final run = _pavilionRun(family, culetScale) / 2 * 100;
    return (
      math.tan(_rad(ProportionLimits.pavilionAngleMin)) * run,
      math.tan(_rad(ProportionLimits.pavilionAngleMax)) * run,
    );
  }

  /// Best-practice proportions for [shape].
  static DiamondProportions ideal(SimShape shape) => switch (shape) {
    SimShape.round => const DiamondProportions(
      tablePct: 57,
      crownAngle: 34.5,
      pavilionAngle: 40.8,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.princess => const DiamondProportions(
      tablePct: 68,
      crownAngle: 34,
      pavilionAngle: 46,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.cushion => const DiamondProportions(
      tablePct: 61,
      crownAngle: 35,
      pavilionAngle: 42.5,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.oval => const DiamondProportions(
      tablePct: 57,
      crownAngle: 34,
      pavilionAngle: 41.2,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.emerald => const DiamondProportions(
      tablePct: 64,
      crownAngle: 31,
      pavilionAngle: 44,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.pear => const DiamondProportions(
      tablePct: 58,
      crownAngle: 34,
      pavilionAngle: 41.5,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.marquise => const DiamondProportions(
      tablePct: 58,
      crownAngle: 34,
      pavilionAngle: 41.5,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.radiant => const DiamondProportions(
      tablePct: 65,
      crownAngle: 34,
      pavilionAngle: 43,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.asscher => const DiamondProportions(
      tablePct: 62,
      crownAngle: 33,
      pavilionAngle: 45,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
    SimShape.heart => const DiamondProportions(
      tablePct: 58,
      crownAngle: 34,
      pavilionAngle: 41.5,
      girdle: GirdleThickness.medium,
      culet: CuletSize.none,
    ),
  };

  /// Representative proportions for a stone of [grade] in [shape]: each
  /// step down drifts further from ideal. Fair is cut deep (dark centre),
  /// Poor shallow (light leaks out of the bottom as a glassy window).
  static DiamondProportions forGrade(SimShape shape, CutGrade grade) {
    final i = ideal(shape);
    // Step cuts are graded more leniently, so their drift is wider too.
    final k = shape.family == SimCutFamily.step ? 1.6 : 1.0;
    DiamondProportions drift(
      double table,
      double crown,
      double pavilion,
      GirdleThickness girdle,
      CuletSize culet,
    ) => i.copyWith(
      tablePct: i.tablePct + table * k,
      crownAngle: i.crownAngle + crown * k,
      pavilionAngle: i.pavilionAngle + pavilion * k,
      girdle: girdle,
      culet: culet,
    );

    return switch (grade) {
      CutGrade.excellent => i,
      CutGrade.veryGood => drift(
        3,
        -2.8,
        0.9,
        GirdleThickness.slightlyThick,
        CuletSize.verySmall,
      ),
      CutGrade.good => drift(
        6,
        -6,
        1.7,
        GirdleThickness.thick,
        CuletSize.small,
      ),
      CutGrade.fair => drift(
        7,
        -8,
        3.8,
        GirdleThickness.veryThick,
        CuletSize.medium,
      ),
      CutGrade.poor => drift(
        11,
        -11,
        -4,
        GirdleThickness.extremelyThin,
        CuletSize.large,
      ),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is DiamondProportions &&
      other.tablePct == tablePct &&
      other.crownAngle == crownAngle &&
      other.pavilionAngle == pavilionAngle &&
      other.girdle == girdle &&
      other.culet == culet;

  @override
  int get hashCode =>
      Object.hash(tablePct, crownAngle, pavilionAngle, girdle, culet);
}
