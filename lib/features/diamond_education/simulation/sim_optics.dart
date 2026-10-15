import 'dart:math' as math;

import '../domain/diamond_grades.dart';
import '../domain/diamond_spec.dart';

/// Material inputs for the tracer, derived from a [DiamondSpec]: body
/// colour as absorption, fluorescence as emission, clarity as scatter.
class SimOptics {
  const SimOptics({
    required this.absorbR,
    required this.absorbG,
    required this.absorbB,
    required this.emitR,
    required this.emitG,
    required this.emitB,
    required this.haze,
    required this.milk,
    required this.lighting,
  });

  factory SimOptics.of(DiamondSpec spec, SimLighting lighting) {
    final a = spec.absorption;
    final f = spec.fluorescence.strength;
    final c = spec.fluorescenceColor;
    final uv = lighting == SimLighting.ultraviolet;
    // Under UV the glow is the whole show; in daylight its faint emission
    // offsets a little yellow and, when very strong, turns the stone milky.
    final emit = uv ? 0.085 * f : 0.032 * f;
    // Scale body absorption so D-Z warmth and fancy colours read vividly in
    // the bright white photography lightbox while D-F stay icy white.
    const bodyScale = 1.42;
    return SimOptics(
      absorbR: a.r * bodyScale,
      absorbG: a.g * bodyScale,
      absorbB: a.b * bodyScale,
      emitR: emit * c.r,
      emitG: emit * c.g,
      emitB: emit * c.b,
      haze: spec.clarity.haze,
      milk: !uv && f > 0.6 ? (f - 0.6) * 0.09 : 0,
      lighting: lighting,
    );
  }

  /// Body absorption per unit path, linear RGB.
  final double absorbR, absorbG, absorbB;

  /// Fluorescent emission per unit path, linear RGB.
  final double emitR, emitG, emitB;

  /// Cloud scatter per unit path (low clarity).
  final double haze;

  /// Milky veil from very strong fluorescence in daylight.
  final double milk;
  final SimLighting lighting;
}

/// Studio lighting environment for the simulated diamond, in world space
/// (x right, y up, z toward the viewer).
///
/// Built the way diamonds are lit for grading photography and jewellery
/// counters: a segmented light tent around the viewing axis for white
/// brilliance, the viewer's own head blocking the light straight behind
/// the eye (the obscuration that draws a round brilliant's dark arrows and
/// gives it contrast), a dim room below, and a handful of small, very
/// bright spots. Broad, even light washes a diamond out to glass; the
/// spots are what split into fire and flash as pinpoint sparkle.
class SimStudio {
  SimStudio(SimLighting lighting) : _uv = lighting == SimLighting.ultraviolet;

  final bool _uv;

  /// Average studio fill for multi-bounce rays still inside the crystal.
  double get ambientFill => _uv ? 0.02 : 0.36;

  /// Spot lights: unit direction, then linear RGB radiance.
  static final List<double> _spots = _normalizedSpots(const [
    -0.46, 0.66, 0.60, 19.0, 18.2, 16.8,
    0.50, 0.60, 0.62, 16.6, 17.6, 19.4,
    0.10, 0.98, 0.14, 18.0, 18.0, 18.0,
    -0.74, 0.22, 0.64, 15.0, 15.4, 16.2,
    0.76, 0.16, 0.63, 15.8, 15.2, 14.6,
    -0.24, 0.40, 0.88, 13.0, 13.2, 13.8,
    0.38, -0.24, 0.89, 11.0, 11.2, 11.6,
    0.62, 0.74, -0.26, 14.0, 14.2, 15.0,
    -0.58, 0.78, -0.22, 14.4, 14.0, 13.4,
    0.0, 0.42, -0.91, 9.0, 9.4, 10.2,
  ]);
  static const _spotOuter = 0.99756; // cos 4Â°
  static const _spotInner = 0.99905; // cos 2.5Â°

  static List<double> _normalizedSpots(List<double> raw) {
    final out = List<double>.of(raw);
    for (var i = 0; i < out.length; i += 6) {
      final l = math.sqrt(
        out[i] * out[i] + out[i + 1] * out[i + 1] + out[i + 2] * out[i + 2],
      );
      out[i] /= l;
      out[i + 1] /= l;
      out[i + 2] /= l;
    }
    return out;
  }

  /// Radiance seen along world direction (x, y, z), written to [r], [g],
  /// [b].
  double r = 0, g = 0, b = 0;

  static double _smoothstep(double e0, double e1, double x) {
    final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  /// Rectangular studio softbox window centred at unit direction (cx, cy, cz)
  /// with local tangent axes and half-extents (wx, wy), returning a crisp
  /// planar glass-window intensity with a linear gradient across the panel.
  static double _windowPanel(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double cz,
    double ux,
    double uy,
    double uz,
    double vx,
    double vy,
    double vz,
    double halfU,
    double halfV,
    double bevel,
  ) {
    final dot = x * cx + y * cy + z * cz;
    if (dot <= 0.1) return 0;
    // Project onto the window's tangent plane.
    final u = (x * ux + y * uy + z * uz) / dot;
    final v = (x * vx + y * vy + z * vz) / dot;
    final du = u.abs() - halfU;
    final dv = v.abs() - halfV;
    if (du > bevel || dv > bevel) return 0;
    final wu = 1.0 - _smoothstep(-bevel, bevel, du);
    final wv = 1.0 - _smoothstep(-bevel, bevel, dv);
    // Subtle linear glass gradient across the diffuser panel.
    final sheen = 0.85 + 0.30 * (u / (halfU + 1e-6)).clamp(-1.0, 1.0);
    return wu * wv * sheen;
  }

  void sample(double x, double y, double z) {
    if (_uv) {
      // Deep ultraviolet inspection chamber with linear UV tube banks.
      final up = y.clamp(0.0, 1.0);
      var lr = 0.006 + 0.012 * up;
      var lg = 0.003 + 0.006 * up;
      var lb = 0.022 + 0.045 * up;
      final topTube = _windowPanel(
        x, y, z,
        0.0, 0.80, 0.60,
        1.0, 0.0, 0.0,
        0.0, 0.60, -0.80,
        0.65, 0.22, 0.08,
      );
      final sideTube = _windowPanel(
        x, y, z,
        -0.76, 0.42, 0.49,
        0.54, 0.0, 0.84,
        -0.35, 0.91, 0.23,
        0.35, 0.18, 0.07,
      );
      final tube = topTube * 0.22 + sideTube * 0.16;
      lr += tube * 0.45;
      lg += tube * 0.35;
      lb += tube * 1.65;
      r = lr;
      g = lg;
      b = lb;
      return;
    }

    // Dim room: a near-black floor rising to soft grey walls and ceiling.
    final room = 0.05 + 0.12 * _smoothstep(-0.45, 0.75, y);
    var lr = room, lg = room * 1.02, lb = room * 1.07;

    // Light tent around the viewing axis: twelve diffuser panels split by
    // dark seams and two seam rings, so each virtual facet catches light
    // or shadow and the mosaic breaks up and re-forms as the stone turns.
    var light = 0.0;
    if (z > 0.18 && z < 0.94) {
      final ring =
          _smoothstep(0.18, 0.24, z) * (1 - _smoothstep(0.915, 0.93, z));
      final seams =
          _smoothstep(-0.55, -0.38, math.cos(12 * math.atan2(y, x))) *
          _smoothstep(0.03, 0.045, (z - 0.4).abs()) *
          _smoothstep(0.025, 0.04, (z - 0.62).abs()) *
          _smoothstep(0.018, 0.028, (z - 0.8).abs());
      light += ring * seams * (0.62 + 0.7 * _smoothstep(-0.7, 0.75, y));
    }

    // Overhead strip bank, so a stone seen side-on still has its crown lit.
    if (y > 0.72) {
      light +=
          _smoothstep(0.72, 0.8, y) *
          _smoothstep(0.1, 0.35, math.cos(x * 22)) *
          0.6;
    }

    // Rear rim strip for the pavilion in profile.
    light += _windowPanel(
      x, y, z,
      0.0, 0.88, -0.47,
      1.0, 0.0, 0.0,
      0.0, 0.47, 0.88,
      0.64, 0.22, 0.06,
    ) * 0.8;

    lr += light;
    lg += light;
    lb += light * 1.03;

    // The viewer's head blocks the light straight behind the eye.
    if (z > 0.94) {
      final head = _smoothstep(0.945, 0.968, z);
      lr += (0.032 - lr) * head;
      lg += (0.034 - lg) * head;
      lb += (0.038 - lb) * head;
    }

    // Compact spots: whole virtual facets flash on and off as they line
    // up, and their small size lets red, green and blue exits separate.
    final spots = _spots;
    for (var i = 0; i < spots.length; i += 6) {
      final d = x * spots[i] + y * spots[i + 1] + z * spots[i + 2];
      if (d <= _spotOuter) continue;
      final w = _smoothstep(_spotOuter, _spotInner, d);
      lr += spots[i + 3] * w;
      lg += spots[i + 4] * w;
      lb += spots[i + 5] * w;
    }

    r = lr;
    g = lg;
    b = lb;
  }
}
