import 'diamond_grades.dart';
import 'diamond_proportions.dart';
import 'diamond_shape.dart';

/// Estimates a cut grade from proportions, grading-lab style: each
/// proportion is scored against the shape's ideal window and the stone
/// takes its weakest score. Step cuts tolerate wider angles than
/// brilliants because their broad facets are less sensitive to them.
abstract final class CutGradeEstimator {
  /// Upper bound of each band (Excellent, Very good, Good, Fair) as an
  /// absolute deviation from ideal; anything beyond is Poor.
  static const _table = [4.0, 7.0, 10.0, 13.0];
  static const _crown = [2.0, 4.5, 7.5, 10.5];
  static const _pavilion = [0.7, 1.4, 2.4, 4.2];
  static const _depth = [2.5, 4.0, 6.0, 9.0];

  static CutGrade estimate(SimShape shape, DiamondProportions p) {
    final ideal = DiamondProportions.ideal(shape);
    final lenient = shape.family == SimCutFamily.step ? 1.6 : 1.0;
    int band(double deviation, List<double> limits, [double scale = 1]) {
      for (var i = 0; i < limits.length; i++) {
        if (deviation.abs() <= limits[i] * scale) return i;
      }
      return limits.length;
    }

    final scores = [
      band(p.tablePct - ideal.tablePct, _table, lenient),
      band(p.crownAngle - ideal.crownAngle, _crown, lenient),
      band(p.pavilionAngle - ideal.pavilionAngle, _pavilion, lenient),
      band(
        p.approxDepthPct(shape.family) - ideal.approxDepthPct(shape.family),
        _depth,
        lenient,
      ),
      _girdleScore(p.girdle),
      _culetScore(p.culet),
    ];
    var worst = 0;
    for (final s in scores) {
      if (s > worst) worst = s;
    }
    return CutGrade.values[worst];
  }

  /// The Excellent window around [shape]'s ideal, for slider hints.
  static ({
    (double, double) table,
    (double, double) crownAngle,
    (double, double) pavilionAngle,
    (double, double) depth,
  })
  idealWindow(SimShape shape) {
    final i = DiamondProportions.ideal(shape);
    final k = shape.family == SimCutFamily.step ? 1.6 : 1.0;
    (double, double) around(double v, double d) => (v - d * k, v + d * k);
    return (
      table: around(i.tablePct, _table[0]),
      crownAngle: around(i.crownAngle, _crown[0]),
      pavilionAngle: around(i.pavilionAngle, _pavilion[0]),
      depth: around(i.approxDepthPct(shape.family), _depth[0]),
    );
  }

  static int _girdleScore(GirdleThickness g) => switch (g) {
    GirdleThickness.thin ||
    GirdleThickness.medium ||
    GirdleThickness.slightlyThick => 0,
    GirdleThickness.veryThin || GirdleThickness.thick => 1,
    GirdleThickness.extremelyThin || GirdleThickness.veryThick => 2,
    GirdleThickness.extremelyThick => 3,
  };

  static int _culetScore(CuletSize c) => switch (c) {
    CuletSize.none || CuletSize.verySmall || CuletSize.small => 0,
    CuletSize.medium => 1,
    CuletSize.slightlyLarge => 2,
    CuletSize.large => 3,
    CuletSize.veryLarge || CuletSize.extremelyLarge => 4,
  };
}
