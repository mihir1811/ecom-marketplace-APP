import 'dart:math' as math;

import '../domain/diamond_grades.dart';
import 'sim_mesh.dart';

/// Kinds of clarity characteristics the simulator draws.
enum SimInclusionKind { pinpoint, crystal, feather, cloud }

/// One clarity characteristic inside the stone, model space.
class SimInclusion {
  const SimInclusion({
    required this.kind,
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    this.ex = 0,
    this.ey = 0,
    this.ez = 0,
    this.mirrors = const [],
    this.seed = 0,
  });

  final SimInclusionKind kind;
  final double x, y, z;

  /// Radius (crystals, pinpoints, clouds) in model units.
  final double size;

  /// Far end of a feather.
  final double ex, ey, ez;

  /// Mirror images in the nearest pavilion facets, xyz (and the far end
  /// for feathers): a diamond's pavilion acts as a mirror, so a crystal is
  /// often seen two or three times.
  final List<double> mirrors;
  final double seed;
}

/// Places inclusions for a clarity grade. Deterministic per grade, so
/// stepping between grades reads as the stone getting cleaner or more
/// included, and placement follows the stone through proportion changes.
abstract final class SimInclusions {
  static List<SimInclusion> generate(SimMesh mesh, ClarityGrade grade) {
    final recipe = switch (grade) {
      ClarityGrade.fl || ClarityGrade.internallyFlawless => null,
      ClarityGrade.vvs1 => (pin: 1, crystal: 0, feather: 0, cloud: 0, s: 0.6),
      ClarityGrade.vvs2 => (pin: 2, crystal: 1, feather: 0, cloud: 0, s: 0.7),
      ClarityGrade.vs1 => (pin: 2, crystal: 1, feather: 1, cloud: 0, s: 0.9),
      ClarityGrade.vs2 => (pin: 3, crystal: 2, feather: 1, cloud: 0, s: 1.0),
      ClarityGrade.si1 => (pin: 3, crystal: 3, feather: 1, cloud: 1, s: 1.3),
      ClarityGrade.si2 => (pin: 4, crystal: 4, feather: 2, cloud: 1, s: 1.6),
      ClarityGrade.i1 => (pin: 4, crystal: 5, feather: 2, cloud: 1, s: 2.1),
      ClarityGrade.i2 => (pin: 5, crystal: 7, feather: 3, cloud: 2, s: 2.6),
      ClarityGrade.i3 => (pin: 6, crystal: 10, feather: 4, cloud: 3, s: 3.1),
    };
    if (recipe == null) return const [];

    final rng = math.Random(31 + grade.index * 7);
    final out = <SimInclusion>[];
    final half = mesh.length / 2;
    final low = grade.index >= ClarityGrade.si1.index;

    // A random point inside the stone, clear of its surface. Lower
    // grades crowd under the table where they are easy to see; higher
    // grades hide near the girdle.
    (double, double, double)? inside({required bool central}) {
      for (var attempt = 0; attempt < 60; attempt++) {
        final reach = central ? 0.42 : 0.92;
        final x = (rng.nextDouble() * 2 - 1) * half * reach;
        final z = (rng.nextDouble() * 2 - 1) * reach;
        final y = (rng.nextDouble() * 2 - 1) * mesh.totalDepth * 0.42;
        if (!central && !low && x * x / (half * half) + z * z < 0.45) {
          continue;
        }
        if (_margin(mesh, x, y, z) > 0.05) return (x, y, z);
      }
      return null;
    }

    List<double> mirrorsOf(double x, double y, double z, [List<double>? e]) {
      // Two nearest pavilion planes reflect it.
      final planes = mesh.planes;
      final best = <(double, int)>[];
      for (var f = 0; f < mesh.facetCount; f++) {
        if (mesh.kinds[f] != SimFacetKind.pavilion.index) continue;
        final ny = planes[f * 4 + 1];
        if (ny > -0.3) continue;
        final dist =
            planes[f * 4 + 3] -
            (planes[f * 4] * x + ny * y + planes[f * 4 + 2] * z);
        best.add((dist, f));
      }
      best.sort((a, b) => a.$1.compareTo(b.$1));
      final out = <double>[];
      for (final (_, f) in best.take(2)) {
        final nx = planes[f * 4], ny = planes[f * 4 + 1];
        final nz = planes[f * 4 + 2], d = planes[f * 4 + 3];
        void reflect(double px, double py, double pz) {
          final s = 2 * (nx * px + ny * py + nz * pz - d);
          out.addAll([px - s * nx, py - s * ny, pz - s * nz]);
        }

        reflect(x, y, z);
        if (e != null) reflect(e[0], e[1], e[2]);
      }
      return out;
    }

    for (var i = 0; i < recipe.pin; i++) {
      final p = inside(central: false);
      if (p == null) continue;
      out.add(
        SimInclusion(
          kind: SimInclusionKind.pinpoint,
          x: p.$1,
          y: p.$2,
          z: p.$3,
          size: 0.006 + rng.nextDouble() * 0.005 * recipe.s,
          seed: rng.nextDouble(),
        ),
      );
    }
    for (var i = 0; i < recipe.crystal; i++) {
      // The first crystal of an included stone sits right under the table.
      final p = inside(central: low && i < 2);
      if (p == null) continue;
      final size =
          (0.011 + rng.nextDouble() * 0.016) *
          recipe.s *
          (low && i == 0 ? 1.8 : 1);
      out.add(
        SimInclusion(
          kind: SimInclusionKind.crystal,
          x: p.$1,
          y: p.$2,
          z: p.$3,
          size: size,
          mirrors: mirrorsOf(p.$1, p.$2, p.$3),
          seed: rng.nextDouble(),
        ),
      );
    }
    for (var i = 0; i < recipe.feather; i++) {
      final p = inside(central: low && i == 0);
      if (p == null) continue;
      final len = (0.07 + rng.nextDouble() * 0.08) * recipe.s;
      final a = rng.nextDouble() * math.pi * 2;
      final tilt = (rng.nextDouble() - 0.5) * 0.8;
      var ex = p.$1 + math.cos(a) * len, ez = p.$3 + math.sin(a) * len;
      var ey = p.$2 + tilt * len;
      // Keep the far end inside too.
      for (
        var shrink = 0;
        shrink < 4 && _margin(mesh, ex, ey, ez) < 0.02;
        shrink++
      ) {
        ex = (ex + p.$1) / 2;
        ey = (ey + p.$2) / 2;
        ez = (ez + p.$3) / 2;
      }
      out.add(
        SimInclusion(
          kind: SimInclusionKind.feather,
          x: p.$1,
          y: p.$2,
          z: p.$3,
          ex: ex,
          ey: ey,
          ez: ez,
          size: len,
          mirrors: mirrorsOf(p.$1, p.$2, p.$3, [ex, ey, ez]),
          seed: rng.nextDouble(),
        ),
      );
    }
    for (var i = 0; i < recipe.cloud; i++) {
      final p = inside(central: false);
      if (p == null) continue;
      out.add(
        SimInclusion(
          kind: SimInclusionKind.cloud,
          x: p.$1,
          y: p.$2,
          z: p.$3,
          size: (0.04 + rng.nextDouble() * 0.04) * recipe.s,
          seed: rng.nextDouble(),
        ),
      );
    }
    return out;
  }

  /// Smallest distance from (x, y, z) to any facet plane; negative when
  /// outside the stone.
  static double _margin(SimMesh mesh, double x, double y, double z) {
    final p = mesh.planes;
    var best = double.infinity;
    for (var f = 0; f < mesh.facetCount; f++) {
      final d =
          p[f * 4 + 3] - (p[f * 4] * x + p[f * 4 + 1] * y + p[f * 4 + 2] * z);
      if (d < best) best = d;
    }
    return best;
  }
}
