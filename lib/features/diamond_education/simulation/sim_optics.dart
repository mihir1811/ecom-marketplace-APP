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

/// Studio lighting environment for the simulated diamond.
///
/// Models a luxury dark-field gemological studio with large rectangular
/// glass-diffuser softboxes, linear overhead and rim strip panels, and
/// structured geometric contrast baffles. Avoids small circular spot cones
/// (which project round bubble artifacts onto facets) in favour of flat
/// planar window panels and linear light strips that produce authentic
/// glass-like sheet reflections and sharp geometric virtual facets.
class SimStudio {
  SimStudio(SimLighting lighting) : _uv = lighting == SimLighting.ultraviolet;

  final bool _uv;

  /// Average studio fill for multi-bounce rays still inside the crystal.
  double get ambientFill => _uv ? 0.02 : 0.42;

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

    // Soft dark studio environment with luminous glass-reflection panels:
    // 1. Base crystal ambient so internal facets stay silvery-translucent
    //    like real optical glass/diamond, never pitch-black.
    final up = (0.5 + 0.5 * y).clamp(0.0, 1.0);
    var lr = 0.12 + 0.14 * up;
    var lg = 0.125 + 0.145 * up;
    var lb = 0.14 + 0.16 * up;

    // 2. Large overhead rectangular studio softbox (main glass reflection).
    final mainBox = _windowPanel(
      x, y, z,
      0.0, 0.76, 0.65,
      1.0, 0.0, 0.0,
      0.0, 0.65, -0.76,
      0.72, 0.34, 0.06,
    );
    lr += mainBox * 2.45;
    lg += mainBox * 2.48;
    lb += mainBox * 2.55;

    // 3. Left & right vertical glass strip softboxes (warm/cool key & fill).
    final leftStrip = _windowPanel(
      x, y, z,
      -0.78, 0.32, 0.54,
      0.57, 0.0, 0.82,
      -0.26, 0.95, 0.18,
      0.24, 0.58, 0.05,
    );
    lr += leftStrip * 2.75;
    lg += leftStrip * 2.68;
    lb += leftStrip * 2.55;

    final rightStrip = _windowPanel(
      x, y, z,
      0.80, 0.28, 0.53,
      -0.55, 0.0, 0.83,
      -0.23, 0.96, -0.16,
      0.24, 0.56, 0.05,
    );
    lr += rightStrip * 2.50;
    lg += rightStrip * 2.62;
    lb += rightStrip * 2.82;

    // 4. Front upper & lower glass reflector cards near the viewing axis.
    final upperCard = _windowPanel(
      x, y, z,
      0.0, 0.38, 0.925,
      1.0, 0.0, 0.0,
      0.0, 0.925, -0.38,
      0.52, 0.16, 0.04,
    );
    lr += upperCard * 2.10;
    lg += upperCard * 2.14;
    lb += upperCard * 2.22;

    final lowerCard = _windowPanel(
      x, y, z,
      0.0, -0.46, 0.888,
      1.0, 0.0, 0.0,
      0.0, 0.888, 0.46,
      0.48, 0.14, 0.04,
    );
    lr += lowerCard * 1.65;
    lg += lowerCard * 1.68;
    lb += lowerCard * 1.76;

    // 5. Rear rim & profile strip lights for crystal edge & pavilion depth.
    final rearTop = _windowPanel(
      x, y, z,
      0.0, 0.88, -0.47,
      1.0, 0.0, 0.0,
      0.0, 0.47, 0.88,
      0.64, 0.22, 0.06,
    );
    lr += rearTop * 1.45;
    lg += rearTop * 1.48;
    lb += rearTop * 1.55;

    // 6. Structured angular facet-reflection bands in the front hemisphere:
    //    Sharp geometric sector steps (8-fold symmetric studio louvers) that
    //    give internal pavilion reflections crisp triangular/kite glass
    //    contrast and strong chromatic dispersion fire without round blobs.
    if (z > 0.15) {
      final az = math.atan2(x, y);
      // Crisp 8-fold and 16-fold angular louver steps.
      final s8 = math.cos(az * 8);
      final s16 = math.cos(az * 16 + z * 6.0);
      final elevBand = math.sin(z * 11.0);
      final louver = _smoothstep(0.15, 0.55, s8 * 0.55 + s16 * 0.45) *
          _smoothstep(-0.2, 0.4, elevBand);
      final frontWeight = _smoothstep(0.15, 0.55, z) *
          (1.0 - 0.78 * _smoothstep(0.955, 0.988, z));
      final intensity = louver * frontWeight * 3.8;
      // Narrow high-contrast linear louver edges drive dispersion fire when
      // RGB rays exit at slightly different angles near critical angle.
      final fireEdge = _smoothstep(0.72, 0.92, s16 * elevBand) *
          frontWeight *
          8.5;
      lr += intensity * 0.98 + fireEdge * 1.04;
      lg += intensity * 1.00 + fireEdge * 0.98;
      lb += intensity * 1.04 + fireEdge * 1.06;
    } else if (z < 0) {
      // Soft dark studio backdrop seen through tilted/windowed facets:
      // translucent smoky glass tone rather than opaque black.
      final back = (-z).clamp(0.0, 1.0);
      lr += 0.10 * (1 - 0.4 * back);
      lg += 0.11 * (1 - 0.4 * back);
      lb += 0.13 * (1 - 0.4 * back);
    }

    r = lr;
    g = lg;
    b = lb;
  }
}
