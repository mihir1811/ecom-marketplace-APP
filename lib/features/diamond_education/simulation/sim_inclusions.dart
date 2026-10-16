import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_grades.dart';
import 'sim_mesh.dart';

/// Kinds of clarity characteristics the simulator traces; [code] is how
/// `shaders/diamond_trace.frag` tells them apart.
enum SimInclusionKind {
  /// A speck too small to resolve: a single sparkling white point.
  pinpoint(1),

  /// A dark included mineral (graphite, sulphide): absorbs light.
  darkCrystal(2),

  /// A transparent included mineral (olivine, garnet, diamond): bends
  /// and mirrors light at its faces.
  clearCrystal(3),

  /// A thin fracture: mirrors light past diamond's critical angle, frosty
  /// and broken at its edges.
  feather(4),

  /// A hazy drift of countless pinpoints.
  cloud(5),

  /// A thin rod-like crystal, bright white.
  needle(6);

  const SimInclusionKind(this.code);

  final int code;
}

/// One clarity characteristic inside the stone, model space.
class SimInclusion {
  const SimInclusion({
    required this.kind,
    required this.x,
    required this.y,
    required this.z,
    required this.size,
    this.ax = 0,
    this.ay = 1,
    this.az = 0,
    this.seed = 0,
  });

  final SimInclusionKind kind;
  final double x, y, z;

  /// Radius (crystals, pinpoints, feathers, clouds) or half length
  /// (needles), model units.
  final double size;

  /// Unit axis: a feather's plane normal, a crystal's or needle's long
  /// axis, the axis a cloud is flattened along.
  final double ax, ay, az;

  /// 0..1; varies outline, habit and tint between inclusions.
  final double seed;
}

/// Places inclusions for a clarity grade. Deterministic per grade, so
/// stepping between grades reads as the stone getting cleaner or more
/// included, and placement follows the stone through proportion changes.
///
/// Sizes follow how graders see them in a one carat stone (the stone is
/// two units wide, so a unit is about 3.2 mm): VVS points of a few
/// hundredths of a millimetre, VS crystals and feathers around a tenth,
/// SI ones up to half a millimetre, I grades millimetre-scale crystals
/// and fractures with clouds that dull the stone.
abstract final class SimInclusions {
  /// Inclusion slots in the shader.
  static const maxCount = 12;

  static List<SimInclusion> generate(SimMesh mesh, ClarityGrade grade) {
    final r = switch (grade) {
      ClarityGrade.fl || ClarityGrade.internallyFlawless => null,
      ClarityGrade.vvs1 => (
        pin: 1,
        needle: 0,
        dark: 0,
        clear: 0,
        feather: 0,
        cloud: 0,
        s: 0.5,
      ),
      ClarityGrade.vvs2 => (
        pin: 2,
        needle: 1,
        dark: 0,
        clear: 0,
        feather: 0,
        cloud: 0,
        s: 0.6,
      ),
      ClarityGrade.vs1 => (
        pin: 2,
        needle: 0,
        dark: 0,
        clear: 1,
        feather: 1,
        cloud: 0,
        s: 0.9,
      ),
      ClarityGrade.vs2 => (
        pin: 2,
        needle: 1,
        dark: 1,
        clear: 1,
        feather: 1,
        cloud: 1,
        s: 1.15,
      ),
      ClarityGrade.si1 => (
        pin: 2,
        needle: 1,
        dark: 2,
        clear: 1,
        feather: 1,
        cloud: 1,
        s: 1.4,
      ),
      ClarityGrade.si2 => (
        pin: 2,
        needle: 1,
        dark: 3,
        clear: 1,
        feather: 2,
        cloud: 1,
        s: 1.8,
      ),
      ClarityGrade.i1 => (
        pin: 2,
        needle: 1,
        dark: 3,
        clear: 1,
        feather: 2,
        cloud: 2,
        s: 2.6,
      ),
      ClarityGrade.i2 => (
        pin: 1,
        needle: 1,
        dark: 4,
        clear: 1,
        feather: 3,
        cloud: 2,
        s: 3.4,
      ),
      ClarityGrade.i3 => (
        pin: 1,
        needle: 0,
        dark: 4,
        clear: 0,
        feather: 4,
        cloud: 3,
        s: 4.2,
      ),
    };
    if (r == null) return const [];

    final rng = math.Random(31 + grade.index * 7);
    final out = <SimInclusion>[];
    final half = mesh.length / 2;
    final low = grade.index >= ClarityGrade.si1.index;
    double vary() => 0.7 + rng.nextDouble() * 0.6;

    // A random point inside the stone, [margin] clear of its surface.
    // Lower grades crowd under the table where they are easy to see;
    // higher grades hide out toward the girdle.
    (double, double, double)? inside({
      required bool central,
      double margin = 0.03,
    }) {
      for (var attempt = 0; attempt < 80; attempt++) {
        final reach = central ? 0.4 : 0.9;
        final x = (rng.nextDouble() * 2 - 1) * half * reach;
        final z = (rng.nextDouble() * 2 - 1) * reach;
        final y = (rng.nextDouble() * 2 - 1) * mesh.totalDepth * 0.4;
        if (!central && !low && x * x / (half * half) + z * z < 0.4) {
          continue;
        }
        if (_margin(mesh, x, y, z) > margin) return (x, y, z);
      }
      return null;
    }

    // A random unit vector; [flat] keeps it away from straight up so a
    // plane through it faces the viewer obliquely.
    (double, double, double) axis({double flat = 1}) {
      final a = rng.nextDouble() * math.pi * 2;
      final y = (rng.nextDouble() * 2 - 1) * flat;
      final h = math.sqrt(1 - y * y);
      return (math.cos(a) * h, y, math.sin(a) * h);
    }

    void add(
      SimInclusionKind kind,
      (double, double, double)? at,
      double size, [
      (double, double, double)? dir,
    ]) {
      if (at == null || out.length >= maxCount) return;
      final d = dir ?? axis();
      out.add(
        SimInclusion(
          kind: kind,
          x: at.$1,
          y: at.$2,
          z: at.$3,
          size: size,
          ax: d.$1,
          ay: d.$2,
          az: d.$3,
          seed: rng.nextDouble() * 0.999,
        ),
      );
    }

    // The defining inclusion first: lower grades show it under the table.
    for (var i = 0; i < r.dark; i++) {
      final big = low && i == 0;
      final size = 0.011 * r.s * vary() * (big ? 1.6 : 1);
      final at = inside(central: low && i < 2, margin: size * 2);
      add(SimInclusionKind.darkCrystal, at, size);
      // Large crystals strain the stone around them: a tension feather.
      if (big && grade.index >= ClarityGrade.i1.index && at != null) {
        add(SimInclusionKind.feather, at, size * 3.2, axis(flat: 0.7));
      }
    }
    for (var i = 0; i < r.feather; i++) {
      // Feathers commonly run in from the girdle.
      final edge = i.isOdd || !low;
      final size = 0.04 * r.s * vary();
      final at = edge
          ? _nearGirdle(mesh, rng, size * 0.4)
          : inside(central: true, margin: size * 0.2);
      add(SimInclusionKind.feather, at, size, axis(flat: 0.75));
    }
    for (var i = 0; i < r.clear; i++) {
      final size = 0.012 * r.s * vary();
      add(
        SimInclusionKind.clearCrystal,
        inside(central: low, margin: size * 2),
        size,
      );
    }
    for (var i = 0; i < r.cloud; i++) {
      final size = 0.035 * r.s * vary();
      add(
        SimInclusionKind.cloud,
        inside(central: false, margin: size * 0.5),
        size,
        axis(flat: 0.4),
      );
    }
    for (var i = 0; i < r.needle; i++) {
      final size = 0.03 * math.min(r.s, 2.0) * vary();
      add(
        SimInclusionKind.needle,
        inside(central: false, margin: size),
        size,
        axis(flat: 0.6),
      );
    }
    for (var i = 0; i < r.pin; i++) {
      add(
        SimInclusionKind.pinpoint,
        inside(central: false),
        0.004 + rng.nextDouble() * 0.003,
      );
    }
    return out;
  }

  /// Packs [inclusions] the way the shader reads them: per inclusion,
  /// centre and size, then axis and `kind + seed`.
  static Float32List pack(List<SimInclusion> inclusions) {
    final out = Float32List(maxCount * 8);
    final n = math.min(inclusions.length, maxCount);
    for (var i = 0; i < n; i++) {
      final c = inclusions[i];
      out.setAll(i * 8, [
        c.x,
        c.y,
        c.z,
        c.size,
        c.ax,
        c.ay,
        c.az,
        c.kind.code + c.seed.clamp(0.0, 0.999),
      ]);
    }
    return out;
  }

  /// A point just inside the girdle, [margin] clear of the surface.
  static (double, double, double)? _nearGirdle(
    SimMesh mesh,
    math.Random rng,
    double margin,
  ) {
    final half = mesh.length / 2;
    for (var attempt = 0; attempt < 60; attempt++) {
      final a = rng.nextDouble() * math.pi * 2;
      final reach = 0.72 + rng.nextDouble() * 0.18;
      final x = math.cos(a) * half * reach, z = math.sin(a) * reach;
      final y = (rng.nextDouble() - 0.6) * mesh.totalDepth * 0.25;
      if (_margin(mesh, x, y, z) > margin) return (x, y, z);
    }
    return null;
  }

  /// Smallest distance from (x, y, z) to any facet plane; negative when
  /// outside the stone.
  static double _margin(SimMesh mesh, double x, double y, double z) =>
      mesh.inset(x, y, z);
}
