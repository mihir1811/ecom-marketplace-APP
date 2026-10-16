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

/// The jeweller's studio the stone sits in, camera-fixed: x right, y up,
/// z toward the viewer. Modelled on how diamonds are judged and filmed: a
/// diffuse light tent around the viewer returns most of the light face
/// up, the viewer's own head straight behind the camera gives the dark
/// contrast pattern every real stone shows, rectangular soft boxes add
/// broad flashes and small intense spots split into fire as the stone
/// moves. Floor and walls are dim grey, never pure black, so light leaking
/// out of a poor cut reads as dull rather than void.
///
/// Must stay in step with `studio()` in `shaders/diamond_trace.frag`.
class SimStudio {
  SimStudio(SimLighting lighting) {
    final uv = lighting == SimLighting.ultraviolet;
    final scale = uv ? 0.06 : 1.0;
    final boxes = <double>[], spots = <double>[];
    List<double> tint(double r, double g, double b) => [
      r * scale,
      (uv ? g * 0.4 : g) * scale,
      (uv ? b * 1.6 : b) * scale,
    ];

    /// A rectangular soft box centred on (x, y, z), [wDeg] × [hDeg] half
    /// extents, level with the floor.
    void box(
      double x,
      double y,
      double z,
      double wDeg,
      double hDeg,
      double r,
      double g,
      double b,
    ) {
      final l = math.sqrt(x * x + y * y + z * z);
      x /= l;
      y /= l;
      z /= l;
      // Right = up × centre.
      final rl = math.sqrt(z * z + x * x);
      boxes.addAll([
        x,
        y,
        z,
        0,
        z / rl,
        0,
        -x / rl,
        math.tan(wDeg * math.pi / 180),
        ...tint(r, g, b),
        math.tan(hDeg * math.pi / 180),
      ]);
    }

    // Overhead key, a wide strip leaning toward the viewer.
    box(0, 0.8, 0.6, 26, 12, 2.2, 2.2, 2.15);
    // Tall side boxes, one a touch warm, one a touch cool.
    box(-0.78, 0.35, 0.52, 9, 17, 2.8, 2.76, 2.68);
    box(0.78, 0.3, 0.55, 9, 17, 2.6, 2.66, 2.78);
    // Overhead strip and rims behind: they model a side view, too weak to
    // brighten light that leaks out of the back of a poor cut.
    box(0, 0.93, -0.36, 24, 7, 1.3, 1.3, 1.3);
    box(-0.6, 0.5, -0.62, 7, 12, 0.7, 0.7, 0.7);
    box(0.62, 0.45, -0.64, 7, 12, 0.65, 0.66, 0.68);

    // Small, intense spots: the pin-point flashes that read as sparkle
    // and split into colour (fire) through the stone. Most sit in the
    // half of the room a face-up stone returns to the viewer.
    const at = [
      (-120.0, 40.0),
      (-85.0, 58.0),
      (-60.0, 28.0),
      (-40.0, 48.0),
      (-24.0, 20.0),
      (-12.0, 36.0),
      (8.0, 26.0),
      (20.0, 50.0),
      (34.0, 18.0),
      (46.0, 40.0),
      (68.0, 30.0),
      (92.0, 52.0),
      (118.0, 38.0),
      (0.0, 70.0),
      (-150.0, 55.0),
      (150.0, 45.0),
    ];
    final co = math.cos(2.0 * math.pi / 180);
    final ci = math.cos(0.6 * math.pi / 180);
    for (var i = 0; i < at.length; i++) {
      final az = at[i].$1 * math.pi / 180, el = at[i].$2 * math.pi / 180;
      final warm = i.isEven;
      spots.addAll([
        math.cos(el) * math.sin(az),
        math.sin(el),
        math.cos(el) * math.cos(az),
        co,
        ...tint(warm ? 29 : 26, 28, warm ? 26 : 30),
        1 / (ci - co),
      ]);
    }
    assert(boxes.length <= maxBoxes * 12 && spots.length <= maxSpots * 8);
    _boxCount = boxes.length ~/ 12;
    _spotCount = spots.length ~/ 8;
    _boxes = Float64List.fromList(boxes);
    _spots = Float64List.fromList(spots);
    packedBoxes = Float32List(maxBoxes * 12)..setAll(0, boxes);
    packedSpots = Float32List(maxSpots * 8)..setAll(0, spots);
    ambient = uv ? 0.0 : 1.0;
    _uv = uv;
  }

  /// Light slots in the shader.
  static const maxBoxes = 6, maxSpots = 16;

  late final Float64List _boxes, _spots;
  late final int _boxCount, _spotCount;
  late final bool _uv;

  /// Soft boxes as the shader reads them, [maxBoxes] × (centre, 0; right
  /// axis, tan half width; rgb, tan half height); unused slots are dark.
  late final Float32List packedBoxes;

  /// Spots as the shader reads them, [maxSpots] × (direction, cos outer
  /// edge; rgb, 1 / (cos inner − cos outer)).
  late final Float32List packedSpots;

  /// Room brightness: 1 in daylight, 0 under ultraviolet.
  late final double ambient;

  /// Radiance seen along world direction (x, y, z), written to [r], [g],
  /// [b].
  double r = 0, g = 0, b = 0;

  static double _smooth(double e0, double e1, double x) {
    final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  void sample(double x, double y, double z) {
    // Dark floor, dim walls brightening toward the ceiling.
    final room = y < 0 ? 0.02 + 0.04 * (1 + y) : 0.06 + 0.22 * y * (2 - y);
    // The light tent around the viewer, dimmer below eye level.
    final tent =
        0.4 * _smooth(0.15, 0.55, z) * (0.5 + 0.5 * _smooth(-0.5, 0.4, y));
    // The viewer's head blocks it straight behind the camera.
    final head = _smooth(0.968, 0.986, z);
    final base = (room + tent) * (1 - 0.9 * head) * ambient;
    var lr = base, lg = base, lb = base;
    if (_uv) {
      lr += 0.004;
      lg += 0.001;
      lb += 0.012;
    }
    final bx = _boxes;
    for (var i = 0, o = 0; i < _boxCount; i++, o += 12) {
      final k = x * bx[o] + y * bx[o + 1] + z * bx[o + 2];
      if (k <= 0.2) continue;
      // Up = centre × right.
      final ux = bx[o + 1] * bx[o + 6] - bx[o + 2] * bx[o + 5];
      final uy = bx[o + 2] * bx[o + 4] - bx[o] * bx[o + 6];
      final uz = bx[o] * bx[o + 5] - bx[o + 1] * bx[o + 4];
      final qx =
          (x * bx[o + 4] + y * bx[o + 5] + z * bx[o + 6]) / k / bx[o + 7];
      final qy = (x * ux + y * uy + z * uz) / k / bx[o + 11];
      final w =
          (1 - _smooth(0.82, 1, qx.abs())) *
          (1 - _smooth(0.82, 1, qy.abs())) *
          (1 - 0.25 * (qx * qx + qy * qy));
      if (w <= 0) continue;
      lr += w * bx[o + 8];
      lg += w * bx[o + 9];
      lb += w * bx[o + 10];
    }
    final p = _spots;
    for (var i = 0, o = 0; i < _spotCount; i++, o += 8) {
      final c = x * p[o] + y * p[o + 1] + z * p[o + 2];
      if (c <= p[o + 3]) continue;
      var w = (c - p[o + 3]) * p[o + 7];
      if (w > 1) {
        w = 1;
      } else {
        w = w * w * (3 - 2 * w);
      }
      lr += w * p[o + 4];
      lg += w * p[o + 5];
      lb += w * p[o + 6];
    }
    r = lr;
    g = lg;
    b = lb;
  }
}
