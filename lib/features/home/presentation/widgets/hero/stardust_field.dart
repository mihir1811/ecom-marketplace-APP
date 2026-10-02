import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'diamond_mesh.dart';

/// Shapes the hero stardust can gather into, in cycle order.
enum StarForm { glyph, gem, galaxy }

/// Normalised point cloud of a glyph: [fill] covers the strokes, [edge] the
/// outline. Coordinates are centred, y-down, roughly within -1..1.
class GlyphCloud {
  const GlyphCloud({required this.fill, required this.edge});

  final List<Offset> fill;
  final List<Offset> edge;
}

/// 3D particle system behind the hero, viewed through an orbit camera.
///
/// Stars live in model space (formation radius ≈ 1) and drift toward a
/// target that blends between two formations. Soft, slightly underdamped
/// springs plus a per-star wandering offset make them meander and settle
/// slowly instead of snapping. The camera can be orbited a full 360° by
/// dragging, with gentle inertia; when idle it resumes a slow automatic
/// orbit. Screen positions are projected once per step for the painter.
class StardustField extends ChangeNotifier {
  StardustField({this.count = 2600, int seed = 11})
    : _rng = math.Random(seed),
      _x = Float32List(count),
      _y = Float32List(count),
      _z = Float32List(count),
      _vx = Float32List(count),
      _vy = Float32List(count),
      _vz = Float32List(count),
      sx = Float32List(count),
      sy = Float32List(count),
      depth = Float32List(count),
      size = Float32List(count),
      twinkleSpeed = Float32List(count),
      twinklePhase = Float32List(count),
      rgb = Int32List(count),
      _delay = Float32List(count),
      _swirl = Float32List(count),
      _wf = Float32List(count * 3),
      _wp = Float32List(count * 3),
      _galR = Float32List(count),
      _galA = Float32List(count),
      _galW = Float32List(count),
      _galH = Float32List(count),
      _gx = Float32List(count),
      _gy = Float32List(count),
      _gz = Float32List(count),
      _edge = Int32List(count),
      _edgeT = Float32List(count),
      _jx = Float32List(count),
      _jy = Float32List(count),
      _jz = Float32List(count),
      _ambient = Uint8List(count) {
    _seed();
  }

  final int count;
  final math.Random _rng;

  final Float32List _x, _y, _z, _vx, _vy, _vz;

  /// Projected screen positions (painter-local pixels) and perspective
  /// factor (>1 is nearer the viewer), refreshed every [step].
  final Float32List sx, sy, depth;

  /// Star radius in logical pixels at unit depth.
  final Float32List size;
  final Float32List twinkleSpeed;
  final Float32List twinklePhase;

  /// Base colour as 0xRRGGBB.
  final Int32List rgb;

  final Float32List _delay, _swirl, _wf, _wp;
  final Float32List _galR, _galA, _galW, _galH;
  final Float32List _gx, _gy, _gz;
  final Int32List _edge;
  final Float32List _edgeT, _jx, _jy, _jz;
  final Uint8List _ambient;

  static const _morph = 4.2;
  static const _maxDelay = 1.6;
  static const _hold = {
    StarForm.glyph: 6.0,
    StarForm.gem: 7.0,
    StarForm.galaxy: 8.0,
  };

  // Spring constants: ζ ≈ 0.85 — a calm settle with a whisper of overshoot.
  static const _k = 2.6;
  static const _c = 2.75;
  static const _camDistance = 4.2;
  static const _homePitch = 0.3;
  static const _galaxyTilt = 0.55;

  late final List<int> _edges = _meshEdges();

  /// The formation the stars are travelling to (or holding).
  final ValueNotifier<StarForm> form = ValueNotifier(StarForm.glyph);

  StarForm _from = StarForm.galaxy;
  double time = 0;
  double _morphStart = 0.2;
  bool _placed = false;

  // Orbit camera.
  double yaw = -0.5;
  double pitch = _homePitch;
  double _yawVel = 0;
  double _pitchVel = 0;
  bool _dragging = false;
  double _idle = 10;

  Offset? _pointer;
  Offset? _lastPointer;
  double _pointerPower = 0;

  /// 0..1 strength of the warm core glow for the current blend.
  double get coreGlow {
    final t = ((time - _morphStart - _maxDelay / 2) / _morph).clamp(0.0, 1.0);
    double glow(StarForm f) => switch (f) {
      StarForm.glyph => 0.75,
      StarForm.gem => 0.45,
      StarForm.galaxy => 1.0,
    };
    return glow(_from) + (glow(form.value) - glow(_from)) * _ease(t);
  }

  static double _ease(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

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
      size[i] = 0.45 + math.pow(_rng.nextDouble(), 7) * 3.4;
      twinkleSpeed[i] = 0.6 + _rng.nextDouble() * 2.0;
      twinklePhase[i] = _rng.nextDouble() * math.pi * 2;
      _delay[i] = _rng.nextDouble() * _maxDelay;
      _swirl[i] = _rng.nextBool() ? 1 : -1;
      _ambient[i] = _rng.nextDouble() < 0.1 ? 1 : 0;
      for (var k = 0; k < 3; k++) {
        _wf[i * 3 + k] = 0.25 + _rng.nextDouble() * 0.6;
        _wp[i * 3 + k] = _rng.nextDouble() * math.pi * 2;
      }

      // Two-armed spiral: dense bulge, tightly wound arms, faint disk dust.
      final kind = _rng.nextDouble();
      if (kind < 0.22) {
        _galR[i] = (_gauss() * 0.12).abs();
        _galA[i] = _rng.nextDouble() * math.pi * 2;
        _galH[i] = _gauss() * 0.06;
      } else if (kind < 0.36) {
        _galR[i] = 0.1 + _rng.nextDouble() * 0.95;
        _galA[i] = _rng.nextDouble() * math.pi * 2;
        _galH[i] = _gauss() * 0.025;
      } else {
        final rad = 0.08 + math.pow(_rng.nextDouble(), 1.15) * 0.98;
        final arm = _rng.nextBool() ? 0.0 : math.pi;
        _galR[i] = rad + _gauss() * 0.025;
        _galA[i] = arm + rad * 7.2 + _gauss() * 0.22 * (1.3 - rad * 0.6);
        _galH[i] = _gauss() * 0.02;
      }
      _galW[i] = 0.12 / (math.sqrt(_galR[i]) + 0.22);

      // Length-weighted edge pick keeps the wireframe evenly lit.
      final e = _rng.nextDouble() * weights.last;
      var lo = 0;
      while (lo < weights.length - 1 && weights[lo] < e) {
        lo++;
      }
      _edge[i] = lo;
      _edgeT[i] = _rng.nextDouble();
      _jx[i] = _gauss() * 0.006;
      _jy[i] = _gauss() * 0.006;
      _jz[i] = _gauss() * 0.006;

      // Placeholder glyph (a ring) until the real one is sampled.
      final a = _rng.nextDouble() * math.pi * 2;
      _gx[i] = math.cos(a) * 0.7;
      _gy[i] = math.sin(a) * 0.7;
      _gz[i] = 0;
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
  /// silhouette, the rest fill the strokes. A shallow z spread gives the
  /// letter body when orbited.
  void setGlyph(GlyphCloud cloud) {
    if (cloud.fill.isEmpty) return;
    for (var i = 0; i < count; i++) {
      final useEdge = cloud.edge.isNotEmpty && _rng.nextDouble() < 0.35;
      final source = useEdge ? cloud.edge : cloud.fill;
      final p = source[_rng.nextInt(source.length)];
      _gx[i] = p.dx;
      _gy[i] = p.dy;
      _gz[i] = (_rng.nextDouble() - 0.5) * 0.16;
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

  // ---- Camera ----------------------------------------------------------

  static const _yawPerPx = 0.0055; // ≈ 360° per 1140 px: calm, precise.
  static const _pitchPerPx = 0.0045;

  void beginDrag() {
    _dragging = true;
    _idle = 0;
    _yawVel = 0;
    _pitchVel = 0;
  }

  void dragBy(Offset delta) {
    yaw += delta.dx * _yawPerPx;
    pitch = (pitch + delta.dy * _pitchPerPx).clamp(-1.35, 1.35);
    _idle = 0;
  }

  /// Releases the camera with a soft glide from the finger's [velocity].
  void endDrag(Offset velocity) {
    _dragging = false;
    _yawVel = (velocity.dx * _yawPerPx * 0.3).clamp(-2.2, 2.2);
    _pitchVel = (velocity.dy * _pitchPerPx * 0.3).clamp(-1.6, 1.6);
  }

  void _stepCamera(double dt) {
    if (_dragging) return;
    _idle += dt;
    yaw += _yawVel * dt;
    pitch = (pitch + _pitchVel * dt).clamp(-1.35, 1.35);
    final decay = math.pow(0.22, dt).toDouble();
    _yawVel *= decay;
    _pitchVel *= decay;

    // Automatic motion fades back in a few seconds after the user lets go.
    final auto = ((_idle - 2.5) / 3).clamp(0.0, 1.0);
    if (auto == 0) return;
    if (form.value == StarForm.glyph) {
      // Keep the mark legible: ease to the nearest front view and sway.
      final home = (yaw / (math.pi * 2)).roundToDouble() * math.pi * 2;
      final target = home + 0.42 * math.sin(time * 0.32);
      yaw += (target - yaw) * math.min(1.0, dt * 0.55) * auto;
    } else {
      yaw += 0.15 * dt * auto;
    }
    final pitchTarget = _homePitch + 0.07 * math.sin(time * 0.23);
    pitch += (pitchTarget - pitch) * math.min(1.0, dt * 0.45) * auto;
  }

  // ---- Interaction -----------------------------------------------------

  /// Hover / touch position in painter-local pixels (null when lifted).
  void setPointer(Offset? local) {
    _pointer = local;
    if (local != null) _lastPointer = local;
  }

  /// Soft outward kick from a tapped screen point.
  void shockwave(Offset at, double radiusPx) {
    final cy = math.cos(yaw), syw = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    for (var i = 0; i < count; i++) {
      final dx = sx[i] - at.dx, dy = sy[i] - at.dy;
      final d = math.sqrt(dx * dx + dy * dy);
      if (d > radiusPx || d < 0.001) continue;
      final f = (1 - d / radiusPx) * 1.1;
      _addCameraVector(i, dx / d * f, -dy / d * f, cy, syw, cp, sp);
    }
  }

  /// Adds a camera-space (x right, y up) velocity to star [i] in model space.
  void _addCameraVector(
    int i,
    double fx,
    double fy,
    double cy,
    double sy,
    double cp,
    double sp,
  ) {
    final y1 = fy * cp;
    final z1 = -fy * sp;
    _vx[i] += fx * cy - z1 * sy;
    _vy[i] += y1;
    _vz[i] += fx * sy + z1 * cy;
  }

  // ---- Simulation ------------------------------------------------------

  /// Places every star on its target instantly (reduced motion).
  void settle(Offset center, double scale) {
    _placed = true;
    _morphStart = -100;
    for (var i = 0; i < count; i++) {
      final (x, y, z) = _target(form.value, i);
      _x[i] = x;
      _y[i] = y;
      _z[i] = z;
      _vx[i] = _vy[i] = _vz[i] = 0;
    }
    _project(center, scale);
    notifyListeners();
  }

  /// Re-projects without simulating (camera moved while paused).
  void reproject(Offset center, double scale) {
    _project(center, scale);
    notifyListeners();
  }

  /// Advances physics by [dt] seconds; projects around [center] at [scale].
  void step(double dt, Offset center, double scale) {
    time += dt;
    if (!_placed) _bigBang();
    if (time - _morphStart > _morph + _maxDelay + _hold[form.value]!) {
      advance();
    }
    _stepCamera(dt);

    final pointer = _pointer;
    _pointerPower +=
        ((pointer == null ? 0 : 1) - _pointerPower) * math.min(1.0, dt * 3);
    final p = pointer ?? _lastPointer;
    final reach = scale * 0.38;
    final touching = p != null && _pointerPower > 0.01;
    final cy = math.cos(yaw), syw = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);

    for (var i = 0; i < count; i++) {
      final raw = (time - _morphStart - _delay[i]) / _morph;
      final w = raw <= 0 ? 0.0 : (raw >= 1 ? 1.0 : _ease(raw));

      var (tx, ty, tz) = _target(form.value, i);
      var wander = 0.016;
      if (w < 1) {
        final (fx, fy, fz) = _target(_from, i);
        tx = fx + (tx - fx) * w;
        ty = fy + (ty - fy) * w;
        tz = fz + (tz - fz) * w;
        final arc = math.sin(math.pi * w);
        // Swirl about the vertical axis mid-flight.
        final a = arc * 0.8 * _swirl[i];
        final ca = math.cos(a), sa = math.sin(a);
        final rx = tx * ca + tz * sa;
        tz = -tx * sa + tz * ca;
        tx = rx;
        wander += arc * 0.12;
      }
      // Each star meanders on its own slow Lissajous path.
      final b = i * 3;
      tx += math.sin(time * _wf[b] + _wp[b]) * wander;
      ty += math.sin(time * _wf[b + 1] + _wp[b + 1]) * wander;
      tz += math.sin(time * _wf[b + 2] + _wp[b + 2]) * wander;

      var ax = (tx - _x[i]) * _k - _vx[i] * _c;
      var ay = (ty - _y[i]) * _k - _vy[i] * _c;
      var az = (tz - _z[i]) * _k - _vz[i] * _c;

      if (touching) {
        final dx = sx[i] - p.dx, dy = sy[i] - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < reach * reach && d2 > 0.01) {
          final d = math.sqrt(d2);
          final f = math.pow(1 - d / reach, 2) * _pointerPower * dt;
          // Gentle push plus a lazy curl around the finger (camera space).
          final fx = (dx / d * 0.9 - dy / d * 0.45) * f;
          final fy = -(dy / d * 0.9 + dx / d * 0.45) * f;
          _addCameraVector(i, fx, fy, cy, syw, cp, sp);
        }
      }

      _vx[i] += ax * dt;
      _vy[i] += ay * dt;
      _vz[i] += az * dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      _z[i] += _vz[i] * dt;
    }
    _project(center, scale);
    notifyListeners();
  }

  void _bigBang() {
    _placed = true;
    for (var i = 0; i < count; i++) {
      final u = _rng.nextDouble() * 2 - 1;
      final a = _rng.nextDouble() * math.pi * 2;
      final r = math.sqrt(1 - u * u);
      final dx = r * math.cos(a), dy = u, dz = r * math.sin(a);
      _x[i] = dx * 0.02;
      _y[i] = dy * 0.02;
      _z[i] = dz * 0.02;
      final speed = 0.5 + _rng.nextDouble() * 1.3;
      _vx[i] = dx * speed;
      _vy[i] = dy * speed;
      _vz[i] = dz * speed;
    }
  }

  void _project(Offset center, double scale) {
    final cy = math.cos(yaw), syw = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    for (var i = 0; i < count; i++) {
      final x = _x[i], y = _y[i], z = _z[i];
      final x1 = x * cy + z * syw;
      final z1 = -x * syw + z * cy;
      final yc = y * cp - z1 * sp;
      final zc = y * sp + z1 * cp;
      final f = _camDistance / math.max(0.6, _camDistance - zc);
      sx[i] = center.dx + x1 * scale * f;
      sy[i] = center.dy - yc * scale * f;
      depth[i] = f;
    }
  }

  (double, double, double) _target(StarForm f, int i) {
    if (f == StarForm.galaxy || _ambient[i] == 1) {
      final outer = f == StarForm.galaxy ? 1.0 : 1.75;
      final a = _galA[i] + time * _galW[i] * (outer == 1 ? 1 : 0.35);
      final r = _galR[i] * outer;
      final lx = r * math.cos(a);
      final ly = _galH[i];
      final lz = r * math.sin(a);
      const ct = 0.8525, st = 0.5227; // cos/sin of _galaxyTilt
      assert((math.cos(_galaxyTilt) - ct).abs() < 1e-3);
      // Tilt the disk toward the camera so the spiral opens up.
      return (lx, ly * ct + lz * st, -ly * st + lz * ct);
    }
    if (f == StarForm.glyph) {
      return (_gx[i] * 0.86, -_gy[i] * 0.86, _gz[i]);
    }
    final v = DiamondMesh.roundBrilliant.vertices;
    final e = _edge[i] * 2;
    final a = v[_edges[e]], b = v[_edges[e + 1]];
    final t = _edgeT[i];
    const s = 0.95;
    return (
      (a.x + (b.x - a.x) * t) * s + _jx[i],
      (a.y + (b.y - a.y) * t) * s + _jy[i],
      (a.z + (b.z - a.z) * t) * s + _jz[i],
    );
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }
}
