import 'dart:math' as math;

import '../../diamond_education/application/diamond_simulator_controller.dart';
import '../../diamond_education/domain/diamond_grades.dart';
import '../../diamond_education/domain/diamond_proportions.dart';
import '../../diamond_education/domain/diamond_shape.dart';
import '../../diamond_education/domain/diamond_spec.dart';
import '../../diamond_education/simulation/sim_inclusions.dart';
import '../../diamond_education/simulation/sim_mesh.dart';
import '../../diamond_education/simulation/sim_optics.dart';
import '../../diamond_education/simulation/sim_outline.dart';
import 'jmath.dart';

/// A traced diamond as the jewelry needs it: the diamond simulator's own
/// cut model, inclusions and optics, plus its real size in millimetres
/// and its girdle outline for seating prongs, bezels and halos.
///
/// Stone frame: millimetres, table up (+y), length along x, centred on
/// the stone's bounding box, exactly as [SimMesh] but scaled.
class JewelryStone {
  JewelryStone._(
    this.spec,
    this.mesh,
    this.inclusions,
    this.optics,
    this.mmPerUnit,
    this._centreX,
    this._centreZ,
  );

  factory JewelryStone.of(DiamondSpec spec) {
    final mesh = SimMesh.build(spec.shape, spec.proportions);
    final mmPerUnit =
        math
            .pow(
              spec.carat * DiamondSimulatorState.mm3PerCarat / mesh.volume,
              1 / 3,
            )
            .toDouble() *
        DiamondSimulatorState.spreadCalibration;
    // The outline as drawn may sit off centre (a pear's round end is at
    // its origin); the mesh is centred on its bounding box.
    var lo = double.infinity, hi = -double.infinity;
    var loZ = double.infinity, hiZ = -double.infinity;
    for (var i = 0; i < 256; i++) {
      final p = SimOutline.even(spec.shape, i / 256);
      lo = math.min(lo, p.x);
      hi = math.max(hi, p.x);
      loZ = math.min(loZ, p.z);
      hiZ = math.max(hiZ, p.z);
    }
    return JewelryStone._(
      spec,
      mesh,
      SimInclusions.generate(
        mesh,
        spec.clarity,
        only: spec.inclusionTypes,
        enhancement: spec.enhancement,
      ),
      SimOptics.of(spec, SimLighting.daylight),
      mmPerUnit,
      (lo + hi) / 2,
      (loZ + hiZ) / 2,
    );
  }

  /// A round accent of [carat] matching [like]'s colour and clarity, e.g.
  /// the side stones of a three-stone ring.
  factory JewelryStone.side(DiamondSpec like, double carat) => JewelryStone.of(
    like.copyWith(
      shape: SimShape.round,
      proportions: DiamondProportions.ideal(SimShape.round),
      carat: carat,
    ),
  );

  final DiamondSpec spec;
  final SimMesh mesh;
  final List<SimInclusion> inclusions;
  final SimOptics optics;
  final double mmPerUnit;
  final double _centreX, _centreZ;

  double get lengthMm => mesh.length * mmPerUnit;
  double get widthMm => mesh.width * mmPerUnit;
  double get crownMm => mesh.crownHeight * mmPerUnit;
  double get pavilionMm => mesh.pavilionDepth * mmPerUnit;
  double get girdleMm => mesh.girdleThickness * mmPerUnit;
  double get depthMm => mesh.totalDepth * mmPerUnit;
  double get radiusMm => mesh.radius * mmPerUnit;

  /// Height of the table, girdle centre and culet in the stone frame.
  double get tableY => depthMm / 2;
  double get girdleY => depthMm / 2 - crownMm - girdleMm / 2;
  double get culetY => -depthMm / 2;

  /// Girdle outline point at [u] (0..1 once round), in the stone frame's
  /// x–z plane at girdle height. Tips, corners and clefts fall on the
  /// same u as in [SimOutline].
  V3 outline(double u) {
    final p = SimOutline.even(spec.shape, u);
    return V3(
      (p.x - _centreX) * mmPerUnit,
      girdleY,
      (p.z - _centreZ) * mmPerUnit,
    );
  }

  /// Outward unit normal of the outline at [u], in the x–z plane.
  V3 outlineNormal(double u) {
    const e = 1 / 512;
    final a = outline(u - e), b = outline(u + e);
    final t = b - a;
    var n = V3(t.z, 0, -t.x).normalized;
    final p = outline(u);
    // Outward: away from the stone's centre (the cleft of a heart points
    // inward, where only the neighbours' average tells which way is out).
    final c = V3(0, girdleY, 0);
    final mid = (a + b) * 0.5;
    if (n.dot(p - c) < 0 && n.dot(mid - c) < 0) n = -n;
    return n;
  }

  /// Girdle perimeter, mm.
  double get perimeterMm {
    var len = 0.0;
    var prev = outline(0);
    for (var i = 1; i <= 128; i++) {
      final p = outline(i / 128);
      len += (p - prev).length;
      prev = p;
    }
    return len;
  }

  /// Where the prongs sit around the outline (0..1), for [count] prongs:
  /// on the points of pointed shapes, the corners of square ones,
  /// evenly round the rest.
  List<double> prongStops(int count) {
    final six = count >= 6;
    switch (spec.shape) {
      case SimShape.round:
      case SimShape.oval:
      case SimShape.cushion:
        return six
            ? [for (var k = 0; k < 6; k++) k / 6 + 1 / 12]
            : const [1 / 8, 3 / 8, 5 / 8, 7 / 8];
      case SimShape.princess:
      case SimShape.asscher:
        return const [1 / 8, 3 / 8, 5 / 8, 7 / 8];
      case SimShape.radiant:
      case SimShape.emerald:
        return six
            ? const [0, 1 / 8, 3 / 8, 0.5, 5 / 8, 7 / 8]
            : const [1 / 8, 3 / 8, 5 / 8, 7 / 8];
      case SimShape.pear:
        return six
            ? const [0, 0.2, 0.36, 0.5, 0.64, 0.8]
            : const [0, 0.3, 0.5, 0.7];
      case SimShape.marquise:
        return six
            ? const [0, 0.18, 0.32, 0.5, 0.68, 0.82]
            : const [0, 0.25, 0.5, 0.75];
      case SimShape.heart:
        return six
            ? const [0, 0.14, 0.3, 0.5, 0.7, 0.86]
            : const [0, 0.2, 0.5, 0.8];
    }
  }

  /// Weight of a round brilliant [diameterMm] across, carats.
  static double roundCarat(double diameterMm) =>
      0.00364 * diameterMm * diameterMm * diameterMm;
}
