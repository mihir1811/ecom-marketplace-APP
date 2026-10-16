import 'dart:math' as math;
import 'dart:typed_data';

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
    final emit = uv ? 0.075 * f : 0.03 * f;
    return SimOptics(
      absorbR: a.r,
      absorbG: a.g,
      absorbB: a.b,
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

/// The dark studio the stone sits in. Its light sources are never drawn:
/// they exist only as directions the stone can reflect, so all the viewer
/// sees is their effect, the flashes and fire inside the diamond, against
/// black. Camera-fixed: x right, y up, z toward the viewer, whose own head
/// blocks the light straight behind the camera.
class SimStudio {
  SimStudio(SimLighting lighting) {
    final uv = lighting == SimLighting.ultraviolet;
    final scale = uv ? 0.06 : 1.0;
    void light(
      double x,
      double y,
      double z,
      double outerDeg,
      double innerDeg,
      double r,
      double g,
      double b,
    ) {
      final l = math.sqrt(x * x + y * y + z * z);
      final co = math.cos(outerDeg * math.pi / 180);
      final ci = math.cos(innerDeg * math.pi / 180);
      _lights.addAll([
        x / l,
        y / l,
        z / l,
        co,
        1 / (ci - co),
        r * scale,
        (uv ? g * 0.4 : g) * scale,
        (uv ? b * 1.6 : b) * scale,
      ]);
    }

    // Overhead soft box, slightly toward the viewer.
    light(0, 0.75, 0.66, 26, 12, 2.6, 2.6, 2.5);
    // Side strips.
    light(-0.8, 0.42, 0.43, 9, 3, 3.4, 3.35, 3.2);
    light(0.82, 0.36, 0.44, 9, 3, 3.1, 3.15, 3.3);
    light(0.9, -0.15, 0.4, 16, 6, 0.9, 0.9, 0.95);
    light(-0.7, -0.35, 0.62, 18, 8, 0.8, 0.8, 0.8);
    // Overhead and faint rims behind: enough to model a side view, too
    // weak to brighten light that leaks out of the back of a poor cut.
    light(0, 0.95, -0.3, 18, 8, 1.1, 1.1, 1.1);
    light(-0.55, 0.62, -0.56, 14, 6, 0.55, 0.55, 0.55);
    light(0.6, 0.55, -0.58, 12, 5, 0.5, 0.5, 0.52);
    // Small, intense spots: the pin-point flashes that read as sparkle
    // and split into colour (fire) through the stone.
    const spots = [
      (-118.0, 46.0),
      (-92.0, 64.0),
      (-64.0, 36.0),
      (-38.0, 58.0),
      (-22.0, 30.0),
      (24.0, 40.0),
      (40.0, 66.0),
      (62.0, 32.0),
      (88.0, 54.0),
      (116.0, 42.0),
      (0.0, 78.0),
      (-48.0, 12.0),
      (52.0, 16.0),
      (170.0, 60.0),
    ];
    for (var i = 0; i < spots.length; i++) {
      final az = spots[i].$1 * math.pi / 180, el = spots[i].$2 * math.pi / 180;
      final warm = i.isEven;
      light(
        math.cos(el) * math.sin(az),
        math.sin(el),
        math.cos(el) * math.cos(az),
        2.6,
        0.8,
        warm ? 27 : 24,
        26,
        warm ? 24 : 27.5,
      );
    }
    _count = _lights.length ~/ 8;
    _packed = Float64List.fromList(_lights);
    _ambient = uv ? 0.0 : 1.0;
    _uv = uv;
  }

  final List<double> _lights = [];
  late final Float64List _packed;
  late final int _count;
  late final double _ambient;
  late final bool _uv;

  /// Radiance seen along world direction (x, y, z), written to [r], [g],
  /// [b].
  double r = 0, g = 0, b = 0;

  void sample(double x, double y, double z) {
    // A black room, a touch brighter overhead, darker toward the floor.
    final up = y > 0 ? y * y : 0.0;
    var base = (0.01 + 0.03 * up) * _ambient;
    // The room around the viewer: a soft tent of light that the stone
    // returns face up. Only the viewer's own head, straight behind the
    // camera, blocks it, which gives a well cut stone its contrast.
    if (z > 0.62) {
      final band = z > 0.975
          ? 0.0
          : z > 0.94
          ? (0.975 - z) / 0.035
          : 1.0;
      final edge = ((z - 0.62) / 0.2).clamp(0.0, 1.0);
      base += (0.34 + 0.3 * (y > 0 ? y : 0.3 * y)) * band * edge * _ambient;
    }
    var lr = base, lg = base, lb = base;
    if (_uv) {
      lr += 0.004;
      lg += 0.001;
      lb += 0.012;
    }
    final p = _packed;
    for (var i = 0, o = 0; i < _count; i++, o += 8) {
      final c = x * p[o] + y * p[o + 1] + z * p[o + 2];
      if (c <= p[o + 3]) continue;
      var w = (c - p[o + 3]) * p[o + 4];
      if (w > 1) {
        w = 1;
      } else {
        w = w * w * (3 - 2 * w);
      }
      lr += w * p[o + 5];
      lg += w * p[o + 6];
      lb += w * p[o + 7];
    }
    r = lr;
    g = lg;
    b = lb;
  }
}
