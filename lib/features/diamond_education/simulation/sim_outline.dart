import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/diamond_shape.dart';

/// 2D point on the girdle plane (model x, z).
typedef SimPoint = ({double x, double z});

/// Girdle outline of a brilliant shape in half-width units: the stone's
/// width (across its narrow axis) is 2, its length runs along x.
///
/// `at(u)` walks the outline once for u in 0..1 so the eight pavilion and
/// crown mains (u = k / 8) land on the shape's tips, corners and cleft.
abstract final class SimOutline {
  static final Map<SimShape, Float64List> _arc = {};

  /// Like [at], but evenly spaced along the outline's length, so girdle
  /// samples are spread fairly round curves of changing pace. Tips and
  /// clefts stay at u = 0 and 0.5 by symmetry. Polygonal outlines keep
  /// their own spacing, which already lands nodes on every corner.
  static SimPoint even(SimShape shape, double u) {
    switch (shape) {
      case SimShape.princess:
      case SimShape.radiant:
      case SimShape.emerald:
      case SimShape.asscher:
      case SimShape.round:
        return at(shape, u);
      default:
        final table = _arc.putIfAbsent(shape, () => _arcTable(shape));
        final n = table.length - 1;
        final x = (u % 1) * n;
        final i = x.floor().clamp(0, n - 1);
        final f = x - i;
        return at(shape, table[i] + (table[i + 1] - table[i]) * f);
    }
  }

  /// Raw parameter at each 1/n of the outline's arc length.
  static Float64List _arcTable(SimShape shape) {
    const fine = 4096, n = 512;
    final cumulative = Float64List(fine + 1);
    var prev = at(shape, 0);
    for (var j = 1; j <= fine; j++) {
      final p = at(shape, j / fine);
      final dx = p.x - prev.x, dz = p.z - prev.z;
      cumulative[j] = cumulative[j - 1] + math.sqrt(dx * dx + dz * dz);
      prev = p;
    }
    final total = cumulative[fine];
    final out = Float64List(n + 1);
    var j = 0;
    for (var i = 0; i <= n; i++) {
      final target = total * i / n;
      while (j < fine - 1 && cumulative[j + 1] < target) {
        j++;
      }
      final span = cumulative[j + 1] - cumulative[j];
      final f = span <= 0 ? 0.0 : (target - cumulative[j]) / span;
      out[i] = (j + f.clamp(0.0, 1.0)) / fine;
    }
    return out;
  }

  static SimPoint at(SimShape shape, double u) {
    final a = 2 * math.pi * u;
    switch (shape) {
      case SimShape.round:
        return (x: math.cos(a), z: math.sin(a));
      case SimShape.oval:
        return (x: shape.ratio * math.cos(a), z: math.sin(a));
      case SimShape.cushion:
        // Superellipse: a square with pillowed sides and rounded corners.
        double se(double v) => v.sign * math.pow(v.abs(), 2 / 3.4).toDouble();
        return (x: shape.ratio * se(math.cos(a)), z: se(math.sin(a)));
      case SimShape.princess:
        return _square(u);
      case SimShape.radiant:
        return _octagon(u, shape.ratio, 0.3);
      case SimShape.marquise:
        return _lens(a, shape.ratio, both: true);
      case SimShape.pear:
        // Round end of radius 1 at the origin, tapering to a tip at
        // x = 2 * ratio - 1.
        if (math.cos(a) <= 0) return (x: math.cos(a), z: math.sin(a));
        return _lens(a, shape.ratio * 2 - 1, both: false);
      case SimShape.heart:
        final s = math.sin(a);
        const k = 1 / 16;
        // Classic heart curve: cleft at u = 0, tip at u = 0.5.
        return (
          x: 16 * s * s * s * k,
          z:
              -(13 * math.cos(a) -
                  5 * math.cos(2 * a) -
                  2 * math.cos(3 * a) -
                  math.cos(4 * a)) *
              k,
        );
      case SimShape.emerald:
      case SimShape.asscher:
        // Step cuts are built from [StepOutline]; this is its silhouette.
        final o = StepOutline.of(shape);
        return _octagon(u, o.halfLength, o.corner);
    }
  }

  /// Pointed lens with tips at (±[tip], 0) and half width 1. Arcs pass
  /// through (0, ±1) with a level tangent there, so a round end meets
  /// them smoothly. Only the +x half when not [both].
  static SimPoint _lens(double a, double tip, {required bool both}) {
    final c = math.cos(a), s = math.sin(a);
    // Arc radius R = (tip² + 1) / 2, centred at (0, ∓(R - 1)); solve for
    // the ray length r along direction a.
    final b = (tip * tip - 1) * s.abs();
    final r = (-b + math.sqrt(b * b + 4 * tip * tip)) / 2;
    if (!both && c < 0) return (x: c, z: s);
    return (x: r * c, z: r * s);
  }

  /// Square of half-size 1; corners at u = 1/8 + k/4.
  static SimPoint _square(double u) {
    const corners = [
      (x: 1.0, z: -1.0),
      (x: 1.0, z: 1.0),
      (x: -1.0, z: 1.0),
      (x: -1.0, z: -1.0),
    ];
    final t = (u * 4 + 0.5) % 4;
    final e = t.floor() % 4;
    final f = t - t.floor();
    final p = corners[e], q = corners[(e + 1) % 4];
    return (x: p.x + (q.x - p.x) * f, z: p.z + (q.z - p.z) * f);
  }

  /// Cut-corner rectangle of half-length [a], half-width 1 and corner cut
  /// [c]; its vertices sit at u = 1/16 + k/8.
  static SimPoint _octagon(double u, double a, double c) {
    final v = StepOutline.ring(a, c, 0);
    final t = (u * 8 + 0.5) % 8;
    final e = t.floor() % 8;
    final f = t - t.floor();
    final p = v[e], q = v[(e + 1) % 8];
    return (x: p.x + (q.x - p.x) * f, z: p.z + (q.z - p.z) * f);
  }
}

/// Cut-corner rectangle outline of the step cuts.
class StepOutline {
  const StepOutline(this.halfLength, this.corner);

  final double halfLength;

  /// Corner cut, in half-width units along each axis.
  final double corner;

  static StepOutline of(SimShape shape) => shape == SimShape.asscher
      ? const StepOutline(1, 0.42)
      : StepOutline(shape.ratio, 0.3);

  /// The outline inset by [d] on every side: each edge moves inward by
  /// [d], so every facet between two rings shares one slope. Corners
  /// vanish as they are overtaken; at d = 1 the ring collapses to the
  /// keel line (a point for a square).
  static List<SimPoint> ring(double a, double c, double d) {
    const k = math.sqrt2 - 1; // corner edges shrink at tan(22.5°) per side
    final x = math.max(0.0, a - d), z = math.max(0.0, 1 - d);
    final zc = math.max(0.0, math.min(1 - c - k * d, z));
    final xc = math.max(0.0, math.min(a - c - k * d, x));
    return [
      (x: x, z: -zc),
      (x: x, z: zc),
      (x: xc, z: z),
      (x: -xc, z: z),
      (x: -x, z: zc),
      (x: -x, z: -zc),
      (x: -xc, z: -z),
      (x: xc, z: -z),
    ];
  }
}
