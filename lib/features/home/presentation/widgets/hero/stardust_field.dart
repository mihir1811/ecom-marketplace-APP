import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'diamond_mesh.dart';

/// Shapes the hero stardust can gather into, in cycle order.
enum StarForm { glyph, gem, galaxy }

/// Normalised point cloud of a glyph: [fill] covers the strokes, [edge] the
/// outline. Coordinates are centred and roughly within -1..1.
class GlyphCloud {
  const GlyphCloud({required this.fill, required this.edge});

  final List<Offset> fill;
  final List<Offset> edge;
}

/// CPU particle system behind the hero.
///
/// Every star springs toward a target that blends between two formations.
/// Morphs are staggered per star and swirl around the centre, so shapes
/// dissolve and re-gather like a swarm instead of cross-fading. A finger
/// pushes and stirs nearby stars; taps send a shockwave. All state lives in
/// flat typed arrays that are reused every frame.
class StardustField extends ChangeNotifier {
  StardustField({this.count = 2600, int seed = 11})
    : _rng = math.Random(seed),
      px = Float32List(count),
      py = Float32List(count),
      _vx = Float32List(count),
      _vy = Float32List(count),
      size = Float32List(count),
      twinkleSpeed = Float32List(count),
      twinklePhase = Float32List(count),
      rgb = Int32List(count),
      _delay = Float32List(count),
      _swirl = Float32List(count),
      _galR = Float32List(count),
      _galA = Float32List(count),
      _galW = Float32List(count),
      _gx = Float32List(count),
      _gy = Float32List(count),
      _edge = Int32List(count),
      _edgeT = Float32List(count),
      _jx = Float32List(count),
      _jy = Float32List(count),
      _ambient = Uint8List(count) {
    _seed();
  }

  final int count;
  final math.Random _rng;

  /// Current positions in painter-local pixels.
  final Float32List px;
  final Float32List py;
  final Float32List _vx;
  final Float32List _vy;

  /// Star radius in logical pixels.
  final Float32List size;
  final Float32List twinkleSpeed;
  final Float32List twinklePhase;

  /// Base colour as 0xRRGGBB.
  final Int32List rgb;

  final Float32List _delay;
  final Float32List _swirl;
  final Float32List _galR;
  final Float32List _galA;
  final Float32List _galW;
  final Float32List _gx;
  final Float32List _gy;
  final Int32List _edge;
  final Float32List _edgeT;
  final Float32List _jx;
  final Float32List _jy;
  final Uint8List _ambient;

  static const _morph = 2.4;
  static const _hold = {
    StarForm.glyph: 5.5,
    StarForm.gem: 7.0,
    StarForm.galaxy: 7.5,
  };

  late final List<int> _edges = _meshEdges();
  late final Float32List _projX = Float32List(
    DiamondMesh.roundBrilliant.vertices.length,
  );
  late final Float32List _projY = Float32List(
    DiamondMesh.roundBrilliant.vertices.length,
  );

  /// The formation the stars are travelling to (or holding).
  final ValueNotifier<StarForm> form = ValueNotifier(StarForm.glyph);

  StarForm _from = StarForm.galaxy;
  double time = 0;
  double _morphStart = 0.35;
  bool _placed = false;
  Offset? _pointer;
  Offset? _lastPointer;
  double _pointerPower = 0;

  /// 0..1 strength of the warm core glow for the current blend.
  double get coreGlow {
    final w = _morphWeight(_morph * 0.5);
    double glow(StarForm f) => switch (f) {
      StarForm.glyph => 0.75,
      StarForm.gem => 0.45,
      StarForm.galaxy => 1.0,
    };
    return glow(_from) + (glow(form.value) - glow(_from)) * w;
  }

  double _morphWeight(double delay) {
    final t = ((time - _morphStart - delay) / _morph).clamp(0.0, 1.0);
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  void _seed() {
    const palette = [
      (0xE6EEFF, 52),
      (0xFFFFFF, 18),
      (0xFFD39A, 12),
      (0xFFA866, 5),
      (0x9FE6FF, 7),
      (0xFFB3CF, 3),
      (0xB6FFD8, 3),
    ];
    final total = palette.fold<int>(0, (s, p) => s + p.$2);
    final weights = _edgeWeights();

    for (var i = 0; i < count; i++) {
      var pick = _rng.nextInt(total);
      for (final (color, w) in palette) {
        if (pick < w) {
          rgb[i] = color;
          break;
        }
        pick -= w;
      }
      final r = _rng.nextDouble();
      size[i] = 0.45 + math.pow(r, 7) * 3.4;
      twinkleSpeed[i] = 0.8 + _rng.nextDouble() * 2.6;
      twinklePhase[i] = _rng.nextDouble() * math.pi * 2;
      _delay[i] = _rng.nextDouble() * 0.7;
      _swirl[i] = _rng.nextBool() ? 1 : -1;
      _ambient[i] = _rng.nextDouble() < 0.1 ? 1 : 0;

      // Two-armed spiral: dense bulge, tightly wound arms, faint disk dust.
      final kind = _rng.nextDouble();
      if (kind < 0.22) {
        _galR[i] = (_gauss() * 0.12).abs();
        _galA[i] = _rng.nextDouble() * math.pi * 2;
      } else if (kind < 0.36) {
        _galR[i] = 0.1 + _rng.nextDouble() * 0.95;
        _galA[i] = _rng.nextDouble() * math.pi * 2;
      } else {
        final rad = 0.08 + math.pow(_rng.nextDouble(), 1.15) * 0.98;
        final arm = _rng.nextBool() ? 0.0 : math.pi;
        _galR[i] = rad + _gauss() * 0.025;
        _galA[i] = arm + rad * 7.2 + _gauss() * 0.22 * (1.3 - rad * 0.6);
      }
      _galW[i] = 0.2 / (math.sqrt(_galR[i]) + 0.22);

      // Length-weighted edge pick keeps the wireframe evenly lit.
      var e = _rng.nextDouble() * weights.last;
      var lo = 0;
      while (lo < weights.length - 1 && weights[lo] < e) {
        lo++;
      }
      _edge[i] = lo;
      _edgeT[i] = _rng.nextDouble();
      _jx[i] = _gauss() * 0.6;
      _jy[i] = _gauss() * 0.6;

      // Placeholder glyph (a ring) until the real one is sampled.
      final a = _rng.nextDouble() * math.pi * 2;
      _gx[i] = math.cos(a) * 0.7;
      _gy[i] = math.sin(a) * 0.7;
    }
  }

  double _gauss() {
    final u = 1 - _rng.nextDouble();
    final v = _rng.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
  }

  static List<int> _meshEdges() {
    final seen = <int>{};
    final out = <int>[];
    final n = DiamondMesh.roundBrilliant.vertices.length;
    for (final f in DiamondMesh.roundBrilliant.facets) {
      final idx = f.indices;
      for (var k = 0; k < idx.length; k++) {
        final a = idx[k], b = idx[(k + 1) % idx.length];
        final key = (a < b ? a : b) * n + (a < b ? b : a);
        if (seen.add(key)) out.addAll([a, b]);
      }
    }
    return out;
  }

  List<double> _edgeWeights() {
    final v = DiamondMesh.roundBrilliant.vertices;
    final cumulative = <double>[];
    var sum = 0.0;
    for (var e = 0; e < _edges.length; e += 2) {
      sum += (v[_edges[e]] - v[_edges[e + 1]]).length;
      cumulative.add(sum);
    }
    return cumulative;
  }

  /// Assigns stars to the sampled glyph; ~35% trace the outline for a crisp
  /// silhouette, the rest fill the strokes.
  void setGlyph(GlyphCloud cloud) {
    if (cloud.fill.isEmpty) return;
    for (var i = 0; i < count; i++) {
      final useEdge = cloud.edge.isNotEmpty && _rng.nextDouble() < 0.35;
      final source = useEdge ? cloud.edge : cloud.fill;
      final p = source[_rng.nextInt(source.length)];
      _gx[i] = p.dx;
      _gy[i] = p.dy;
    }
  }

  /// Starts the morph toward [next] (or the next form in the cycle).
  void advance([StarForm? next]) {
    final target =
        next ??
        StarForm.values[(form.value.index + 1) % StarForm.values.length];
    if (target == form.value) return;
    _from = form.value;
    _morphStart = time;
    form.value = target;
  }

  void setPointer(Offset? local) {
    _pointer = local;
    if (local != null) _lastPointer = local;
  }

  /// Outward kick from [at], used for taps.
  void shockwave(Offset at, {double radius = 280, double power = 1100}) {
    for (var i = 0; i < count; i++) {
      final dx = px[i] - at.dx, dy = py[i] - at.dy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > radius || d < 0.001) continue;
      final f = (1 - d / radius) * power;
      _vx[i] += dx / d * f;
      _vy[i] += dy / d * f;
    }
  }

  /// Places every star on its target instantly (reduced motion / first frame).
  void settle(Offset center, double scale) {
    _placed = true;
    _morphStart = -100;
    _project(center, scale);
    for (var i = 0; i < count; i++) {
      final (x, y) = _target(form.value, i, center, scale);
      px[i] = x;
      py[i] = y;
      _vx[i] = 0;
      _vy[i] = 0;
    }
    notifyListeners();
  }

  /// Advances physics by [dt] seconds around [center] at [scale] pixels.
  void step(double dt, Offset center, double scale) {
    time += dt;
    if (!_placed) _bigBang(center, scale);
    if (time - _morphStart > _morph + 0.7 + _hold[form.value]!) advance();

    _project(center, scale);
    final pointer = _pointer;
    _pointerPower +=
        ((pointer == null ? 0 : 1) - _pointerPower) * math.min(1.0, dt * 6);
    final reach = scale * 0.55;
    const k = 24.0, c = 7.2;

    for (var i = 0; i < count; i++) {
      final raw = (time - _morphStart - _delay[i]) / _morph;
      final w = raw <= 0
          ? 0.0
          : raw >= 1
          ? 1.0
          : (raw < 0.5
                    ? 4 * raw * raw * raw
                    : 1 - math.pow(-2 * raw + 2, 3) / 2)
                .toDouble();

      var (tx, ty) = _target(form.value, i, center, scale);
      if (w < 1) {
        final (fx, fy) = _target(_from, i, center, scale);
        tx = fx + (tx - fx) * w;
        ty = fy + (ty - fy) * w;
        // Swirl around the centre mid-flight.
        final a = math.sin(math.pi * w) * 0.9 * _swirl[i];
        final ox = tx - center.dx, oy = ty - center.dy;
        final ca = math.cos(a), sa = math.sin(a);
        tx = center.dx + ox * ca - oy * sa;
        ty = center.dy + ox * sa + oy * ca;
      }

      var ax = (tx - px[i]) * k - _vx[i] * c;
      var ay = (ty - py[i]) * k - _vy[i] * c;

      final p = pointer ?? _lastPointer;
      if (p != null && _pointerPower > 0.01) {
        final dx = px[i] - p.dx, dy = py[i] - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < reach * reach && d2 > 0.01) {
          final d = math.sqrt(d2);
          final f = math.pow(1 - d / reach, 2) * _pointerPower;
          ax += dx / d * f * 5200 - dy / d * f * 2600;
          ay += dy / d * f * 5200 + dx / d * f * 2600;
        }
      }

      _vx[i] += ax * dt;
      _vy[i] += ay * dt;
      px[i] += _vx[i] * dt;
      py[i] += _vy[i] * dt;
    }
    notifyListeners();
  }

  void _bigBang(Offset center, double scale) {
    _placed = true;
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final r = _rng.nextDouble() * 6;
      px[i] = center.dx + math.cos(a) * r;
      py[i] = center.dy + math.sin(a) * r;
      final speed = scale * (1.5 + _rng.nextDouble() * 3.5);
      _vx[i] = math.cos(a) * speed;
      _vy[i] = math.sin(a) * speed;
    }
  }

  void _project(Offset center, double scale) {
    final v = DiamondMesh.roundBrilliant.vertices;
    // Near-profile view so the classic crown-over-pavilion outline reads.
    final yaw = time * 0.42, pitch = 0.2;
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final s = scale * 0.9;
    for (var i = 0; i < v.length; i++) {
      final p = v[i];
      final x1 = p.x * cy + p.z * sy;
      final z1 = -p.x * sy + p.z * cy;
      final y2 = p.y * cp - z1 * sp;
      final z2 = p.y * sp + z1 * cp;
      final f = 6 / (6 - z2);
      _projX[i] = center.dx + x1 * s * f;
      _projY[i] = center.dy - y2 * s * f;
    }
  }

  (double, double) _target(StarForm f, int i, Offset center, double scale) {
    if (f == StarForm.galaxy || _ambient[i] == 1) {
      final outer = f == StarForm.galaxy ? 1.0 : 1.75;
      final a = _galA[i] + time * _galW[i] * (outer == 1 ? 1 : 0.35);
      final r = _galR[i] * scale * outer;
      final x = r * math.cos(a);
      final y = r * math.sin(a) * 0.6;
      const ct = 0.956, st = -0.292; // ~ -17° tilt
      return (center.dx + x * ct - y * st, center.dy + x * st + y * ct);
    }
    if (f == StarForm.glyph) {
      final breathe = math.sin(time * 1.6 + twinklePhase[i]) * 0.9;
      return (
        center.dx + _gx[i] * scale * 0.86 + breathe,
        center.dy + _gy[i] * scale * 0.86,
      );
    }
    final e = _edge[i] * 2;
    final a = _edges[e], b = _edges[e + 1];
    final t = _edgeT[i];
    return (
      _projX[a] + (_projX[b] - _projX[a]) * t + _jx[i],
      _projY[a] + (_projY[b] - _projY[a]) * t + _jy[i],
    );
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }
}
