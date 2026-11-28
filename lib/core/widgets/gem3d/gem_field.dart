import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'diamond_mesh.dart';
import 'diamond_models.dart';
import 'diamond_renderer.dart';
import 'gem_renderer.dart';
import '../../theme/luxe_tokens.dart';

/// Depth bands painted as separate layers so far and near stones can be
/// defocused (depth of field) without blurring the in-focus band.
enum _Band { far, focus, near }

class _FieldGem {
  _FieldGem({
    required this.slot,
    required this.band,
    required this.pick,
    required this.rank,
    required this.hz,
    required this.zLo,
    required this.zHi,
    required this.scale,
    required this.phase,
    required this.pathRadius,
    required this.pathPhase,
    required this.spiral,
    required this.roll,
    required this.offset,
    required this.fluor,
    required this.fluorColor,
  }) : pose = GemPose(z: hz, scale: scale)..basis = Float64List(9);

  /// Seeding order; staggers which frame each stone is re-shaded on.
  final int slot;
  final _Band band;

  /// Facet colours kept between re-shades.
  final DiamondShade shade = DiamondShade();

  /// 0..1 choice of cut, mapped onto however many models are loaded.
  final double pick;

  /// 0..1 draw order for adaptive quality: when the device cannot keep
  /// up, stones with the highest rank sit out first. Random, so the herd
  /// thins evenly.
  final double rank;

  /// Home depth; the stone never leaves its depth band [zLo]..[zHi], so
  /// it never jumps between a blurred and a sharp layer.
  final double hz, zLo, zHi;
  final double scale, phase;

  /// This stone's orbit around the stream's core, in path units: its
  /// radius, its phase and how fast it winds (0..2×).
  final double pathRadius, pathPhase, spiral;

  /// Slow roll about the direction of travel, rad/s, so facets glint.
  final double roll;

  /// Fixed random turn of the cut relative to its heading (x, y, z, w).
  final Float64List offset;

  /// Fluorescence strength (0 inert) and the colour the stone glows.
  final double fluor;
  final Color fluorColor;

  /// Unit quaternion turning local +y onto the direction of travel.
  final Float64List heading = Float64List(4)..[3] = 1;

  final GemPose pose;
  double vx = 0, vy = 0, vz = 0;

  /// 0..1 light reaching the stone from the light that rides the cursor.
  double lit = 0;
}

/// Second-order eased follower (frequency [f] Hz, damping [z], response
/// [r]): trails its target with a little anticipation and overshoot, so the
/// cursor body feels weighted rather than glued to the finger.
class _Eased {
  _Eased(double f, double z, double r)
    : _k1 = z / (math.pi * f),
      _k2 = 1 / ((2 * math.pi * f) * (2 * math.pi * f)),
      _k3 = r * z / (2 * math.pi * f);

  final double _k1, _k2, _k3;
  Offset value = Offset.zero;
  Offset _vel = Offset.zero;
  Offset _prevTarget = Offset.zero;
  bool ready = false;

  double get speed => _vel.distance;

  void reset(Offset at) {
    value = at;
    _vel = Offset.zero;
    _prevTarget = at;
    ready = true;
  }

  /// Moves the target without its jump counting as target velocity.
  void retarget(Offset at) => _prevTarget = at;

  void update(double t, Offset target) {
    if (!ready) return reset(target);
    if (t <= 0) return;
    final targetVel = (target - _prevTarget) / t;
    _prevTarget = target;
    final k2 = math.max(_k2, math.max(t * t / 2 + t * _k1 / 2, t * _k1));
    value += _vel * t;
    _vel += (target + targetVel * _k3 - value - _vel * _k1) * (t / k2);
  }
}

/// Physics for a dense herd of colourless 3D diamonds of every bundled cut
/// and many sizes, reverse engineered from the coffee-bean footer of
/// oryzo.ai (Lusion) and ported from its particle system:
///
/// * The herd streams from the top-left to the bottom-right corner along a
///   snaking path. Every stone orbits the path's core on its own spiral,
///   is pulled back toward its spot on that spiral by a weak spring, is
///   driven along the path at a set pace and damped; stones that leave
///   either end re-enter, unseen, at the other.
/// * The cursor (finger or mouse) is eased by a second-order follower and
///   carries a solid body: stones inside it are pushed out in proportion
///   to how deep they sit and dragged along by its motion.
/// * Stones never overlap: each step pairs of stones that touch are
///   separated, so the herd banks up around the body and jostles.
/// * Each stone faces its direction of travel, easing toward it over about
///   a second, so pushed stones swing round smoothly as they are shoved.
/// * A point light rides just in front of the cursor with an inverse
///   square falloff, so only stones near it shine out of the dark. It stays
///   where the cursor last was.
class GemFieldController extends ChangeNotifier {
  GemFieldController({required this.seed, required this.reduceMotion});

  final int seed;
  bool reduceMotion;

  final List<_FieldGem> _gems = [];
  final List<_FieldGem> _active = [];
  Size _size = Size.zero;
  double _time = 0;

  /// Stream geometry in world units: start point, start→end segment, its
  /// unit tangent, the across-stream axis, and world units per path unit.
  double _startX = 0, _startY = 0, _segX = 1, _segY = 0, _segLenSq = 1;
  double _tanX = 1, _tanY = 0, _perpX = 0, _perpY = -1, _k = 1;

  /// Widens the stream across the screen beyond the original's slim
  /// band, so it fills the empty corners on either side.
  double _spread = 1;
  double _tx = 0, _ty = 0, _tz = 0;

  Offset? _pointer;
  Offset? _rest;
  final _Eased _cursor = _Eased(1.35, 0.5, 1.25);
  Offset _cursorPrev = Offset.zero;

  /// 0..1 how solid the cursor's body is: rises on contact, fades after
  /// release (the light stays).
  double _presence = 0;

  /// After a touch lands far from the eased cursor, the body opens only
  /// as the cursor glides in, so it does not plough a trench on the way.
  bool _arriving = false;
  double _energy = 0;

  /// Baked cuts; nothing is drawn until they are set.
  List<DiamondModel>? models;

  /// Quality tiers, best first. The tier is picked before the field is on
  /// screen ([GemFieldWarmup]) and never changes while it is visible, so
  /// no stone ever vanishes in front of the viewer. Cheaper tiers first
  /// drop the depth-of-field blur (the costliest GPU work) and refresh
  /// facet shading every `shadeEvery` frames instead of every frame (the
  /// costliest CPU work; outlines still move every frame), then a share of
  /// the stones and fine facets. Stones drawn at least `detail` pixels in
  /// radius use the full model; `clear` is the smallest radius drawn as
  /// see-through crystal (twice the facets). `fps` caps how often the
  /// field steps (0 = every vsync); the two low-end tiers run at 30 fps,
  /// draw every stone with its coarse model and skip see-through crystal.
  static const _tiers = [
    (
      blur: true,
      density: 1.0,
      detail: 22.0,
      shadeEvery: 1,
      clear: 12.0,
      fps: 0,
    ),
    (
      blur: false,
      density: 1.0,
      detail: 22.0,
      shadeEvery: 2,
      clear: 12.0,
      fps: 60,
    ),
    (
      blur: false,
      density: 0.85,
      detail: 30.0,
      shadeEvery: 2,
      clear: 14.0,
      fps: 60,
    ),
    (
      blur: false,
      density: 0.7,
      detail: 44.0,
      shadeEvery: 3,
      clear: 17.0,
      fps: 60,
    ),
    (
      blur: false,
      density: 0.55,
      detail: 60.0,
      shadeEvery: 3,
      clear: 20.0,
      fps: 60,
    ),
    (
      blur: false,
      density: 0.4,
      detail: double.infinity,
      shadeEvery: 4,
      clear: double.infinity,
      fps: 30,
    ),
    (
      blur: false,
      density: 0.28,
      detail: double.infinity,
      shadeEvery: 4,
      clear: double.infinity,
      fps: 30,
    ),
  ];
  static int get tierCount => _tiers.length;
  int _quality = 0;
  int _frame = 0;

  int get quality => _quality;
  bool get blur => _tiers[_quality].blur;

  /// Shortest gap between two steps at this tier (zero: every vsync).
  /// Below the best tier 90/120 Hz screens do not multiply the work, and
  /// the low-end tiers step at 30 fps.
  Duration get minFrameInterval {
    final fps = _tiers[_quality].fps;
    // A little under the frame period, so vsync jitter does not skip a
    // frame that is due.
    return fps <= 0
        ? Duration.zero
        : Duration(microseconds: (1e6 / fps * 0.9).round());
  }

  /// Drops to the next cheaper tier; false when already at the cheapest.
  bool lowerQuality() {
    if (_quality == _tiers.length - 1) return false;
    _quality++;
    return true;
  }

  /// Never runs better than [tier]; false when nothing changed.
  bool capQuality(int tier) {
    final next = tier.clamp(0, _tiers.length - 1);
    if (next <= _quality) return false;
    _quality = next;
    return true;
  }

  final List<List<_FieldGem>> _bands = [for (final _ in _Band.values) []];
  final List<DiamondBatch> _batches = [
    for (final _ in _Band.values) DiamondBatch(),
  ];

  /// World units across the field width.
  static const worldWidth = 6.4;

  /// Camera distance from the z = 0 plane.
  static const _eye = 9.0;

  /// Depth slab the stones live in: back edge and thickness.
  static const _zNear = -1.4;
  static const _zDepth = 2.5;

  /// Depth-of-field band edges.
  static const _zFar = -0.95, _zFront = 0.65;

  /// Depth-of-field blur radius of the far and near bands.
  static const _blurFar = 3.2, _blurNear = 1.8;

  static double _blurOf(_Band band) => switch (band) {
    _Band.far => _blurFar,
    _Band.focus => 0,
    _Band.near => _blurNear,
  };

  // Constants of the original particle system, in its path units (its
  // path runs 1.118 units); [_k] scales them onto this field.
  static const _pathLength = 1.118033988749895;
  static const _pathRadius = 0.05;
  // Snake and spiral wound far looser than the original (8, 0.25, 8), so
  // stones sway gently while they fall instead of whirling in circles.
  static const _curveFrequency = 3.0;
  static const _curveAmplitude = 0.05;
  static const _curvePhaseSpeed = 0.1;
  static const _spiralFrequency = 1.5;
  static const _driftSpeed = 0.1;
  static const _driftRate = 2.0;
  static const _attractionRate = 0.5;
  static const _dampingRate = 1.0;
  static const _mouseRadius = 0.1;
  static const _mousePushForce = 0.25;
  static const _lightLift = 0.1;

  /// How fast a stone turns to face its direction of travel, 1/s.
  static const _turnRate = 2.5;

  /// Stones overlap by up to 30% of their size before they are separated.
  static const _contact = 0.7;

  /// Share of a stone's spiral that moves it in depth (the rest moves it
  /// across the stream), so it stays inside its depth band.
  static const _depthShare = 0.3;

  /// Light reaching the darkest stones, so the herd never fully vanishes.
  static const _ambient = 0.08;

  double get unit => _size.width / worldWidth;

  /// Radius of the cursor's body, in world units on the z = 0 plane.
  double get _bodyRadius =>
      (_mouseRadius * _k * unit).clamp(64.0, 130.0) / unit;

  /// Radius of the faint light pool painted under the cursor, in pixels.
  double get lightRadius => _bodyRadius * unit * 2.3;

  GemCamera get camera =>
      GemCamera(center: _size.center(Offset.zero), unit: unit, distance: _eye);

  bool get settled =>
      _pointer == null &&
      _presence == 0 &&
      _energy < 0.002 &&
      _cursor.speed < 0.5;

  /// Seeds stones for [size]; keeps them when the size barely changes.
  void layout(Size size) {
    if (size.isEmpty) return;
    if (_gems.isNotEmpty &&
        (size.width - _size.width).abs() < 1 &&
        (size.height - _size.height).abs() < 1) {
      return;
    }
    _size = size;
    _gems.clear();
    for (final b in _bands) {
      b.clear();
    }
    final rng = math.Random(seed);
    const halfW = worldWidth / 2;
    final halfH = size.height / unit / 2;

    // The stream runs along the screen diagonal, top-left → bottom-right,
    // overshooting both corners far enough that even the farthest
    // (smallest-looking) stones wrap out of sight.
    final diag = math.sqrt(halfW * halfW + halfH * halfH);
    _tanX = halfW / diag;
    _tanY = -halfH / diag;
    // Across-stream axis: tangent × (0, 0, 1).
    _perpX = _tanY;
    _perpY = -_tanX;
    final half = diag * 1.16 + 0.5;
    _startX = -_tanX * half;
    _startY = -_tanY * half;
    _segX = 2 * half * _tanX;
    _segY = 2 * half * _tanY;
    _segLenSq = 4 * half * half;
    _k = 2 * half / _pathLength;
    // The widest orbit plus the snake reaches 0.15 path units off the
    // core; stretch that to most of the way to the side corners.
    final corner = 2 * halfW * halfH / diag;
    _spread = math.max(1, corner * 0.8 / (0.15 * _k));

    // Loosely scattered rather than packed, so single stones read on their
    // own; capped for frame budget. A wider stream holds more stones at the
    // same spacing.
    final count = (size.width * size.height / 1100).round().clamp(90, 240);
    for (var i = 0; i < count; i++) {
      final z = _zNear + rng.nextDouble() * _zDepth;
      final band = z < _zFar
          ? _Band.far
          : z > _zFront
          ? _Band.near
          : _Band.focus;
      final (lo, hi) = switch (band) {
        _Band.far => (_zNear, _zFar),
        _Band.focus => (_zFar, _zFront),
        _Band.near => (_zFront, _zNear + _zDepth),
      };
      final fluor = _fluorescence(rng);
      final axis = _unit3(
        rng.nextDouble() * 2 - 1,
        rng.nextDouble() * 2 - 1,
        rng.nextDouble() * 2 - 1,
      );
      final g = _FieldGem(
        slot: i,
        band: band,
        pick: rng.nextDouble(),
        rank: rng.nextDouble(),
        hz: z,
        zLo: lo,
        zHi: hi,
        // Mostly small stones with the odd big one, like a real pour.
        scale: 0.1 + 0.26 * math.pow(rng.nextDouble(), 1.8),
        phase: rng.nextDouble(),
        // Denser toward the core, yet reaching well out to the sides.
        pathRadius: 2 * math.pow(rng.nextDouble(), 0.75) * _pathRadius,
        pathPhase: 2 * math.pi * rng.nextDouble(),
        spiral: 2 * rng.nextDouble(),
        roll: (0.06 + rng.nextDouble() * 0.16) * (rng.nextBool() ? 1 : -1),
        offset: _axisAngle(axis, (rng.nextDouble() - 0.5) * 2 * math.pi),
        fluor: fluor.strength,
        fluorColor: fluor.color,
      );
      _target(rng.nextDouble(), g);
      g.pose
        ..x = _tx
        ..y = _ty
        ..z = _tz;
      g
        ..vx = _tanX * _driftSpeed * _k
        ..vy = _tanY * _driftSpeed * _k;
      _headingTarget(g.vx, g.vy, 0, g.heading);
      _writeBasis(g);
      _gems.add(g);
      _bands[band.index].add(g);
    }
    _rest = Offset(size.width * 0.5, size.height * 0.6);
    if (!_cursor.ready) _cursor.reset(_rest!);
    _cursorPrev = _cursor.value;
    _energy = 1;
  }

  /// Fluorescence as graded on real diamonds: about a third of stones
  /// fluoresce, nearly all of them blue, a few yellow, green or orange;
  /// strength runs faint, medium, strong, very strong.
  static ({double strength, Color color}) _fluorescence(math.Random rng) {
    const blue = [Color(0xFF4F7DFF), Color(0xFF5B8CFF), Color(0xFF6E9BFF)];
    final has = rng.nextDouble() < 0.32;
    final hue = rng.nextDouble();
    final grade = rng.nextDouble();
    final pick = rng.nextInt(blue.length);
    if (!has) return (strength: 0, color: blue[pick]);
    final strength = grade < 0.4
        ? 0.3
        : grade < 0.72
        ? 0.5
        : grade < 0.92
        ? 0.75
        : 1.0;
    final color = hue < 0.88
        ? blue[pick]
        : hue < 0.94
        ? const Color(0xFFF2E26A) // yellow
        : hue < 0.98
        ? const Color(0xFF7FF0A0) // green
        : const Color(0xFFFFA45C); // orange
    return (strength: strength, color: color);
  }

  /// Where stone [g] belongs at path position [u] (0 start, 1 end), into
  /// [_tx], [_ty], [_tz]: the path snakes as a whole, and the stone winds
  /// around it on its own spiral.
  void _target(double u, _FieldGem g) {
    final a = _curveFrequency * u * _pathLength + _time * _curvePhaseSpeed;
    final b = _spiralFrequency * g.spiral * u * _pathLength + g.pathPhase;
    final amp = _curveAmplitude * _k, r = g.pathRadius * _k;
    final across = (amp * math.sin(a) + r * math.cos(b)) * _spread;
    final depth = amp * math.cos(a) + r * math.sin(b);
    _tx = _startX + _segX * u + _perpX * across;
    _ty = _startY + _segY * u + _perpY * across;
    _tz = (g.hz + depth * _depthShare).clamp(g.zLo, g.zHi);
  }

  double _along(GemPose p) =>
      (_segX * (p.x - _startX) + _segY * (p.y - _startY)) / _segLenSq;

  void step(double dt) {
    if (_gems.isEmpty) return;
    final motion = reduceMotion ? 0.0 : 1.0;
    _time += dt * motion;
    _frame++;
    final density = _tiers[_quality].density;
    final unit = this.unit;
    final pointer = _pointer;

    // The cursor glides after the finger, or rests where it last was.
    _cursorPrev = _cursor.value;
    _cursor.update(dt, pointer ?? _rest ?? _size.center(Offset.zero));
    final cur = _cursor.value;
    final radius = _bodyRadius;
    if (pointer != null) {
      if (_arriving && (cur - pointer).distance < radius * unit) {
        _arriving = false;
      }
      // The body grows in once the cursor has arrived.
      _presence = _arriving ? 0 : math.min(1, _presence + dt * 7);
    } else {
      _presence = math.max(0, _presence - dt * 3.2);
    }
    final body = _arriving ? 0.0 : _presence * _presence * (3 - 2 * _presence);

    // Cursor on the z = 0 plane, in world units.
    final cx = _size.width / 2, cy = _size.height / 2;
    final mx = (cur.dx - cx) / unit, my = -(cur.dy - cy) / unit;
    // The body drags what it sweeps through by its own motion.
    final fling = math.exp(-dt * 10) * body;
    final dragX = (cur.dx - _cursorPrev.dx) / unit * fling;
    final dragY = -(cur.dy - _cursorPrev.dy) / unit * fling;
    final push = _mousePushForce * 60 * dt * body;
    final lightZ = _lightLift * _k;

    final attract = 1 - math.exp(-dt * _attractionRate);
    final drift = 1 - math.exp(-dt * _driftRate);
    final damp = math.exp(-dt * _dampingRate);
    final pace = _driftSpeed * _k * motion;
    // Eases toward the heading over about a second, so stones turn
    // smoothly rather than snapping round with every sway.
    final turn = 1 - math.exp(-dt * _turnRate);
    var energy = 0.0;

    _active.clear();
    for (final g in _gems) {
      // Stones sitting out at this quality tier cost nothing.
      if (g.rank >= density) continue;
      _active.add(g);
      final p = g.pose;

      // Weak spring back toward the stone's spot on its spiral.
      _target(_along(p), g);
      g.vx -= (p.x - _tx) * attract;
      g.vy -= (p.y - _ty) * attract;
      g.vz -= (p.z - _tz) * attract;
      // Driven along the stream at the herd's pace, then damped.
      final along = g.vx * _tanX + g.vy * _tanY;
      g.vx += _tanX * (pace - along) * drift;
      g.vy += _tanY * (pace - along) * drift;
      g.vx *= damp;
      g.vy *= damp;
      g.vz *= damp;
      p.x += g.vx * dt;
      p.y += g.vy * dt;
      p.z += g.vz * dt;

      // Off one end, back in at the other, out of sight.
      final u = _along(p);
      if (u > 1 || u < 0) {
        _target(u > 1 ? 0 : 1, g);
        p
          ..x = _tx
          ..y = _ty
          ..z = _tz;
      }

      // The cursor's body, as seen through the camera: shove out what sits
      // inside it, deeper means harder, and drag it along.
      if (body > 0) {
        final ds = _eye / math.max(0.5, _eye - p.z);
        final dx = p.x * ds - mx, dy = p.y * ds - my;
        final d = math.sqrt(dx * dx + dy * dy);
        final reach = radius + g.scale * _contact;
        if (d < reach && d > 0.001) {
          final f = push * (reach - d) / d;
          g.vx += dx * f + dragX;
          g.vy += dy * f + dragY;
        }
      }

      // Inverse-square light from just in front of the cursor, gamma
      // encoded, never quite black.
      final lx = (p.x - mx) / _k, ly = (p.y - my) / _k;
      final lz = (p.z - lightZ) / _k;
      final att = 1 / (30 * (lx * lx + ly * ly + lz * lz) + 0.01);
      g.lit = math.max(
        _ambient,
        math.pow(math.min(1.0, att * 0.12), 0.45).toDouble(),
      );

      // Face the direction of travel, turning toward it smoothly.
      final sp = math.sqrt(g.vx * g.vx + g.vy * g.vy + g.vz * g.vz);
      if (sp > 0.001) {
        _headingTarget(g.vx, g.vy, g.vz, _q);
        _nlerp(g.heading, _q, turn);
      }
      _writeBasis(g);

      final ex = g.vx - _tanX * pace, ey = g.vy - _tanY * pace;
      energy += ex * ex + ey * ey + g.vz * g.vz;
    }

    // Stones never overlap: separate every touching pair, half each.
    _separate();
    for (final g in _active) {
      g.pose.z = g.pose.z.clamp(g.zLo, g.zHi);
    }

    final n = _active.length;
    _energy = n == 0 ? 0 : energy / n;
    notifyListeners();
  }

  // Uniform grid over the active stones (x, y only; the slab is thin),
  // as linked lists: first stone per cell, next stone in the same cell.
  Int32List _cellHead = Int32List(0);
  Int32List _cellNext = Int32List(0);
  Int32List _cellX = Int32List(0), _cellY = Int32List(0);

  /// Separates every touching pair of active stones. Stones are bucketed
  /// into cells at least as wide as the largest contact reach, so a stone
  /// only tests the stones in its own and the 8 neighbouring cells: about
  /// linear in the stone count instead of testing every pair.
  void _separate() {
    final n = _active.length;
    if (n < 2) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    var maxScale = 0.0;
    for (final g in _active) {
      final p = g.pose;
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
      if (g.scale > maxScale) maxScale = g.scale;
    }
    var cell = 2 * maxScale * _contact;
    if (cell <= 0 || !minX.isFinite || !minY.isFinite) return;
    int cols() => ((maxX - minX) / cell).floor() + 1;
    int rows() => ((maxY - minY) / cell).floor() + 1;
    // Cap the grid; larger cells stay correct, only less selective.
    while (cols() * rows() > 8192) {
      cell *= 2;
    }
    final w = cols(), h = rows(), cells = w * h;
    if (_cellHead.length < cells) _cellHead = Int32List(cells);
    _cellHead.fillRange(0, cells, -1);
    if (_cellNext.length < n) {
      _cellNext = Int32List(n);
      _cellX = Int32List(n);
      _cellY = Int32List(n);
    }
    for (var i = 0; i < n; i++) {
      final p = _active[i].pose;
      final cx = ((p.x - minX) / cell).floor().clamp(0, w - 1);
      final cy = ((p.y - minY) / cell).floor().clamp(0, h - 1);
      _cellX[i] = cx;
      _cellY[i] = cy;
      final c = cy * w + cx;
      _cellNext[i] = _cellHead[c];
      _cellHead[c] = i;
    }
    for (var i = 0; i < n; i++) {
      final a = _active[i];
      final cx = _cellX[i], cy = _cellY[i];
      for (var y = math.max(0, cy - 1); y <= math.min(h - 1, cy + 1); y++) {
        for (var x = math.max(0, cx - 1); x <= math.min(w - 1, cx + 1); x++) {
          // Each pair once: only partners later in the active list.
          for (var j = _cellHead[y * w + x]; j >= 0; j = _cellNext[j]) {
            if (j > i) _collide(a, _active[j]);
          }
        }
      }
    }
  }

  /// Pushes [a] and [b] apart, half each, when they overlap.
  static void _collide(_FieldGem a, _FieldGem b) {
    final pa = a.pose, pb = b.pose;
    final reach = (a.scale + b.scale) * _contact;
    final dx = pb.x - pa.x;
    if (dx >= reach || dx <= -reach) return;
    final dy = pb.y - pa.y;
    if (dy >= reach || dy <= -reach) return;
    final dz = pb.z - pa.z;
    final d2 = dx * dx + dy * dy + dz * dz;
    if (d2 >= reach * reach || d2 < 1e-12) return;
    final d = math.sqrt(d2);
    final s = (reach - d) * 0.5 / d;
    pa
      ..x -= dx * s
      ..y -= dy * s
      ..z -= dz * s;
    pb
      ..x += dx * s
      ..y += dy * s
      ..z += dz * s;
  }

  void pointerDown(Offset at) {
    if (_pointer == null) {
      _arriving = (_cursor.value - at).distance > _bodyRadius * unit;
      _cursor.retarget(at);
    }
    _pointer = at;
    _rest = at;
  }

  void pointerMove(Offset at) {
    if (_pointer == null) _cursor.retarget(at);
    _pointer = at;
    _rest = at;
  }

  void pointerUp() {
    _pointer = null;
    _arriving = false;
  }

  // Scratch quaternions.
  static final Float64List _q = Float64List(4);
  static final Float64List _r = Float64List(4);
  static final Float64List _h = Float64List(4);

  static ({double x, double y, double z}) _unit3(double x, double y, double z) {
    final l = math.sqrt(x * x + y * y + z * z);
    if (l < 1e-9) return (x: 0, y: 1, z: 0);
    return (x: x / l, y: y / l, z: z / l);
  }

  static Float64List _axisAngle(({double x, double y, double z}) a, double t) {
    final s = math.sin(t / 2);
    return Float64List.fromList([a.x * s, a.y * s, a.z * s, math.cos(t / 2)]);
  }

  /// Rotation whose columns are (side, travel, side × travel): local +y
  /// points along the velocity, written into [out] as a quaternion.
  static void _headingTarget(double vx, double vy, double vz, Float64List out) {
    final dir = _unit3(vx, vy, vz);
    var ux = 0.0, uy = 0.0, uz = 1.0;
    if (dir.z.abs() > 0.99) {
      ux = 1;
      uz = 0;
    }
    final side = _unit3(
      dir.y * uz - dir.z * uy,
      dir.z * ux - dir.x * uz,
      dir.x * uy - dir.y * ux,
    );
    final third = _unit3(
      side.y * dir.z - side.z * dir.y,
      side.z * dir.x - side.x * dir.z,
      side.x * dir.y - side.y * dir.x,
    );
    _fromBasis(
      side.x,
      dir.x,
      third.x,
      side.y,
      dir.y,
      third.y,
      side.z,
      dir.z,
      third.z,
      out,
    );
  }

  /// Quaternion of a row-major rotation matrix.
  static void _fromBasis(
    double m00,
    double m01,
    double m02,
    double m10,
    double m11,
    double m12,
    double m20,
    double m21,
    double m22,
    Float64List out,
  ) {
    final trace = m00 + m11 + m22;
    if (trace > 0) {
      final s = 0.5 / math.sqrt(trace + 1);
      out[3] = 0.25 / s;
      out[0] = (m21 - m12) * s;
      out[1] = (m02 - m20) * s;
      out[2] = (m10 - m01) * s;
    } else if (m00 > m11 && m00 > m22) {
      final s = 2 * math.sqrt(1 + m00 - m11 - m22);
      out[3] = (m21 - m12) / s;
      out[0] = 0.25 * s;
      out[1] = (m01 + m10) / s;
      out[2] = (m02 + m20) / s;
    } else if (m11 > m22) {
      final s = 2 * math.sqrt(1 + m11 - m00 - m22);
      out[3] = (m02 - m20) / s;
      out[0] = (m01 + m10) / s;
      out[1] = 0.25 * s;
      out[2] = (m12 + m21) / s;
    } else {
      final s = 2 * math.sqrt(1 + m22 - m00 - m11);
      out[3] = (m10 - m01) / s;
      out[0] = (m02 + m20) / s;
      out[1] = (m12 + m21) / s;
      out[2] = 0.25 * s;
    }
  }

  /// Moves [q] a fraction [t] of the way to [to], along the short arc.
  static void _nlerp(Float64List q, Float64List to, double t) {
    final dot = q[0] * to[0] + q[1] * to[1] + q[2] * to[2] + q[3] * to[3];
    final sign = dot < 0 ? -1.0 : 1.0;
    var l = 0.0;
    for (var i = 0; i < 4; i++) {
      q[i] += (to[i] * sign - q[i]) * t;
      l += q[i] * q[i];
    }
    l = math.sqrt(l);
    for (var i = 0; i < 4; i++) {
      q[i] /= l;
    }
  }

  /// a · b into [out].
  static void _mul(Float64List a, Float64List b, Float64List out) {
    final ax = a[0], ay = a[1], az = a[2], aw = a[3];
    final bx = b[0], by = b[1], bz = b[2], bw = b[3];
    out[0] = aw * bx + ax * bw + ay * bz - az * by;
    out[1] = aw * by - ax * bz + ay * bw + az * bx;
    out[2] = aw * bz + ax * by - ay * bx + az * bw;
    out[3] = aw * bw - ax * bx - ay * by - az * bz;
  }

  /// Pose rotation: heading, then a slow roll about the direction of
  /// travel, then the stone's fixed random turn.
  void _writeBasis(_FieldGem g) {
    final angle = (g.phase * 2 * math.pi + g.roll * _time) / 2;
    final roll = _r
      ..[0] = 0
      ..[1] = math.sin(angle)
      ..[2] = 0
      ..[3] = math.cos(angle);
    _mul(g.heading, roll, _h);
    _mul(_h, g.offset, _q);
    final x = _q[0], y = _q[1], z = _q[2], w = _q[3];
    g.pose.basis!
      ..[0] = 1 - 2 * (y * y + z * z)
      ..[1] = 2 * (x * y - z * w)
      ..[2] = 2 * (x * z + y * w)
      ..[3] = 2 * (x * y + z * w)
      ..[4] = 1 - 2 * (x * x + z * z)
      ..[5] = 2 * (y * z - x * w)
      ..[6] = 2 * (x * z - y * w)
      ..[7] = 2 * (y * z + x * w)
      ..[8] = 1 - 2 * (x * x + y * y);
  }

  void _paintBand(Canvas canvas, _Band band, Color fog) {
    final models = this.models;
    if (models == null) return;
    final cam = camera;
    final tier = _tiers[_quality];
    final detailScale = tier.detail / unit;
    final every = tier.shadeEvery;
    final sparkle = DiamondSparkle.image;
    final sparkleWidth = sparkle.width.toDouble();
    final light = _cursor.value;
    // Back to front. The list is reused and stays nearly sorted from frame
    // to frame, so this is cheap.
    final items = _bands[band.index]
      ..sort((a, b) => a.pose.z.compareTo(b.pose.z));
    final batch = _batches[band.index]..reset();
    for (final g in items) {
      if (g.rank >= tier.density) continue;
      final model = models[(g.pick * models.length).floor() % models.length];
      final glow = g.lit * g.lit;
      // Fluorescence answers the light riding the cursor, as a stone does
      // under a UV torch, with a trace left in the dark.
      final fluor = g.fluor * (0.3 + 0.7 * g.lit);
      if (fluor > 0.04) {
        final at = cam.project(g.pose.x, g.pose.y, g.pose.z);
        _addHalo(
          at,
          g.scale * cam.depthScale(g.pose.z) * unit * 1.9,
          g.fluorColor,
          fluor * g.lit * 0.3,
        );
      }
      batch.add(
        // Small and defocused stones skip sub-pixel facets.
        mesh:
            band != _Band.far &&
                g.pose.scale * cam.depthScale(g.pose.z) >= detailScale
            ? model.detail
            : model.coarse,
        pose: g.pose,
        camera: cam,
        viewport: _size,
        time: _time,
        // Unlit stones sink into the dark, as in the original.
        fog: (1 - g.lit).clamp(0.0, 0.94),
        fogColor: fog,
        light: glow,
        lightFrom: light - cam.project(g.pose.x, g.pose.y, g.pose.z),
        phase: g.phase,
        sparkle: g.lit > 0.4,
        sparkleWidth: sparkleWidth,
        // Clear-crystal shading for every cut but pear, whose many small
        // facets already read as a diamond. Blurred far stones skip it.
        seeThrough: band != _Band.far && model.name != 'pear',
        seeThroughMin: tier.clear,
        shade: g.shade,
        // Each frame re-shades its share of the stones; stones in the
        // light are always fresh.
        reshade: every == 1 || (g.slot + _frame) % every == 0 || g.lit > 0.3,
        glowColor: g.fluorColor,
        glow: fluor,
      );
    }
    batch.paint(canvas, sparkle: sparkle);
    _paintHalos(canvas);
  }

  // Fluorescent halos of the band being painted, drawn in one atlas call.
  Float32List _haloXform = Float32List(0);
  Float32List _haloRects = Float32List(0);
  Int32List _haloColor = Int32List(0);
  int _halos = 0;

  void _addHalo(Offset at, double radius, Color color, double strength) {
    if (strength <= 0.003) return;
    if (_haloColor.length <= _halos) {
      final cap = math.max(32, _haloColor.length * 2);
      _haloXform = Float32List(cap * 4)..setRange(0, _halos * 4, _haloXform);
      _haloRects = Float32List(cap * 4)..setRange(0, _halos * 4, _haloRects);
      _haloColor = Int32List(cap)..setRange(0, _halos, _haloColor);
    }
    const w = _FluorHalo.size;
    final scale = radius * 2 / w;
    final i = _halos * 4;
    _haloXform
      ..[i] = scale
      ..[i + 1] = 0
      ..[i + 2] = at.dx - radius
      ..[i + 3] = at.dy - radius;
    _haloRects
      ..[i] = 0
      ..[i + 1] = 0
      ..[i + 2] = w
      ..[i + 3] = w;
    // Premultiplied for the additive blend.
    final a = strength.clamp(0.0, 1.0);
    int ch(double v) => (v * a * 255).round();
    _haloColor[_halos] =
        (a * 255).round() << 24 |
        ch(color.r) << 16 |
        ch(color.g) << 8 |
        ch(color.b);
    _halos++;
  }

  void _paintHalos(Canvas canvas) {
    if (_halos == 0) return;
    canvas.drawRawAtlas(
      _FluorHalo.image,
      Float32List.sublistView(_haloXform, 0, _halos * 4),
      Float32List.sublistView(_haloRects, 0, _halos * 4),
      Int32List.sublistView(_haloColor, 0, _halos),
      BlendMode.modulate,
      null,
      Paint()..blendMode = BlendMode.plus,
    );
    _halos = 0;
  }

  /// One whole frame onto [canvas] as the widget would show it, blur
  /// included; used to time a tier off screen.
  void _paintFrame(Canvas canvas, Color background) {
    final bounds = Offset.zero & _size;
    canvas.drawRect(bounds, Paint()..color = background);
    for (final band in _Band.values) {
      final sigma = blur ? _blurOf(band) : 0.0;
      if (sigma > 0) {
        canvas.saveLayer(
          bounds,
          Paint()
            ..imageFilter = ui.ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
        );
      }
      _paintBand(canvas, band, background);
      if (sigma > 0) canvas.restore();
    }
    _paintLight(canvas);
  }

  /// A faint pool of light around the cursor; the stones carry the light.
  void _paintLight(Canvas canvas) {
    if (_size.isEmpty) return;
    final at = _cursor.value;
    final r = lightRadius;
    final a = 0.02 + 0.025 * _presence;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          at,
          r,
          [
            Color.fromRGBO(255, 255, 255, a),
            Color.fromRGBO(255, 255, 255, a * 0.36),
            const Color(0x00000000),
          ],
          const [0, 0.4, 1],
        ),
    );
  }
}

/// Decides the gem field's quality tier before the field is on screen,
/// once per app run: loads the models, starts from the device's memory
/// class, then draws whole frames off screen and steps down until a frame
/// fits the budget. The field shows nothing until this is done, so it never
/// starts rich and thins out in front of the viewer.
///
/// Screens that end in a gem field call [prepare] early (home does it
/// shortly after it opens); the field itself calls it as a fallback.
abstract final class GemFieldWarmup {
  static Future<({List<DiamondModel> models, int tier})>? _ready;

  /// Cheapest tier the field has had to fall back to while running; a
  /// field mounted later starts there.
  static int _floor = 0;

  /// Frame budget, in ms, for the UI-thread work (physics plus shading) and
  /// for the GPU work of one field frame.
  static const _uiBudget = 11.0, _rasterBudget = 12.0;

  /// Models plus the tier to draw them at; starts the work on first call.
  static Future<({List<DiamondModel> models, int tier})> prepare({
    required Size size,
    required double pixelRatio,
    required Color background,
  }) => _ready ??= _run(size, pixelRatio, background);

  /// Tier a newly mounted field should use given what the warmup picked.
  static int startTier(int picked) => math.max(picked, _floor);

  /// Records that a running field had to go down to [tier].
  static void lowerTo(int tier) => _floor = math.max(_floor, tier);

  static Future<({List<DiamondModel> models, int tier})> _run(
    Size size,
    double pixelRatio,
    Color background,
  ) async {
    final models = await DiamondModels.load().catchError(
      (Object _) => DiamondModels.fallback(),
    );
    var tier = await _deviceTier();
    // Debug and test builds run far slower than release ones; timing them
    // would only ever pick the cheapest tier.
    if (!kReleaseMode || size.isEmpty) return (models: models, tier: tier);
    final field = GemFieldController(seed: 7, reduceMotion: false)
      ..models = models
      ..layout(size)
      ..capQuality(tier);
    try {
      while (field.quality < GemFieldController.tierCount - 1) {
        if (await _fits(field, size, pixelRatio, background)) break;
        field.lowerQuality();
      }
      tier = field.quality;
    } catch (_) {
      // Timing failed; the memory-class tier stands.
    } finally {
      field.dispose();
    }
    return (models: models, tier: tier);
  }

  /// Times a few whole frames of [field] at its current tier, one per
  /// scheduler slot so the screen above keeps scrolling smoothly. The
  /// fastest of three (after one warm-up frame) is compared with the
  /// budget, since noise only ever adds time.
  static Future<bool> _fits(
    GemFieldController field,
    Size size,
    double pixelRatio,
    Color background,
  ) async {
    var cpuMs = double.infinity, gpuMs = double.infinity;
    final width = (size.width * pixelRatio).ceil();
    final height = (size.height * pixelRatio).ceil();
    for (var i = 0; i < 4; i++) {
      final picture = await SchedulerBinding.instance.scheduleTask(() {
        final watch = Stopwatch()..start();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..scale(pixelRatio);
        field
          ..step(1 / 60)
          .._paintFrame(canvas, background);
        final picture = recorder.endRecording();
        if (i > 0) cpuMs = math.min(cpuMs, watch.elapsedMicroseconds / 1000);
        return picture;
      }, Priority.animation);
      final watch = Stopwatch()..start();
      final image = await picture.toImage(width, height);
      if (i > 0) gpuMs = math.min(gpuMs, watch.elapsedMicroseconds / 1000);
      image.dispose();
      picture.dispose();
      await SchedulerBinding.instance.endOfFrame;
    }
    return cpuMs <= _uiBudget && gpuMs <= _rasterBudget;
  }

  /// Starting tier from the device's memory, a fair proxy for its CPU and
  /// GPU class. Unknown devices start on the best tier.
  static Future<int> _deviceTier() async {
    if (kIsWeb) return 0;
    try {
      final cheapest = GemFieldController.tierCount - 1;
      int tierFor(int ramMb, {bool lowRam = false}) {
        if (ramMb <= 0) return lowRam ? cheapest : 0;
        if (lowRam || ramMb < 2 * 1024 + 512) return cheapest;
        if (ramMb < 3 * 1024 + 512) return cheapest - 1;
        if (ramMb < 4 * 1024 + 512) return 3;
        if (ramMb < 6 * 1024 + 512) return 1;
        return 0;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await DeviceInfoPlugin().androidInfo;
          return tierFor(info.physicalRamSize, lowRam: info.isLowRamDevice);
        case TargetPlatform.iOS:
          // iPhones run this well with less memory than Android phones.
          final info = await DeviceInfoPlugin().iosInfo;
          final ram = info.physicalRamSize;
          if (ram <= 0) return 0;
          if (ram < 1536) return GemFieldController.tierCount - 2;
          if (ram < 2560) return 2;
          if (ram < 3584) return 1;
          return 0;
        default:
          return 0;
      }
    } catch (_) {
      return 0;
    }
  }
}

/// Full-bleed field of colourless 3D diamonds in every bundled cut
/// ([DiamondModels]) streaming diagonally that part around the finger,
/// tumble when swept and catch its light. Pauses while scrolled off
/// screen and honours reduced motion. Its quality tier is settled before
/// it shows ([GemFieldWarmup]) and only ever lowered while it is off
/// screen, so stones never vanish in view.
///
/// Touches below [touchTopInset] are claimed eagerly so the page does not
/// scroll while a finger plays with the stones; above it, scrolling works
/// as usual (so the page can always be scrolled back up).
class GemField extends StatefulWidget {
  const GemField({
    super.key,
    this.background,
    this.seed = 7,
    this.touchTopInset = 0,
  });

  /// Stage colour; defaults to [LuxeStage.obsidian].
  final Color? background;
  final int seed;
  final double touchTopInset;

  @override
  State<GemField> createState() => _GemFieldState();
}

class _GemFieldState extends State<GemField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final GemFieldController _field = GemFieldController(
    seed: widget.seed,
    reduceMotion: false,
  );
  ScrollPosition? _scroll;
  Duration _last = Duration.zero;
  bool _visible = false;
  double _frameCost = 0;
  int _frameSamples = 0;

  /// Tiers to drop the next time the field is off screen.
  int _pendingDrop = 0;

  Color get _background => widget.background ?? LuxeStage.obsidian;

  @override
  void initState() {
    super.initState();
    // Nothing is drawn until the warmup has settled models and tier
    // (usually long before, started by the screen); the herd's entrance
    // plays once they are in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = context.size ?? MediaQuery.sizeOf(context);
      GemFieldWarmup.prepare(
        size: size,
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
        background: _background,
      ).then((ready) {
        if (!mounted) return;
        _field
          ..capQuality(GemFieldWarmup.startTier(ready.tier))
          ..models = ready.models;
        setState(() {});
        _syncTicker();
      });
    });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Watches real frame cost (UI and raster threads) while the field
  /// animates. If frames run long for about half a second, a cheaper tier
  /// (two when far over budget) is queued and applied only once the field
  /// is off screen; nothing changes in front of the viewer.
  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || !_ticker.isActive || _pendingDrop > 0) return;
    for (final t in timings) {
      final build = t.buildDuration.inMicroseconds;
      final raster = t.rasterDuration.inMicroseconds;
      // Frames skipped by the 60 fps cap do no work; they would hide the
      // cost of the frames that do.
      if (build < 1200 && raster < 2500) continue;
      final ms = math.max(build, raster) / 1000;
      _frameCost = _frameSamples == 0 ? ms : _frameCost * 0.85 + ms * 0.15;
      _frameSamples++;
    }
    if (_frameSamples < 30 || _frameCost <= 19) return;
    _pendingDrop = _frameCost > 32 ? 2 : 1;
    _frameSamples = 0;
    GemFieldWarmup.lowerTo(_field.quality + _pendingDrop);
  }

  /// Applies a queued tier drop; only called while the field is hidden.
  void _applyPendingDrop() {
    if (_pendingDrop == 0) return;
    var changed = false;
    for (var i = 0; i < _pendingDrop; i++) {
      if (_field.lowerQuality()) changed = true;
    }
    _pendingDrop = 0;
    _frameCost = 0;
    _frameSamples = 0;
    if (changed) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _field.reduceMotion = MediaQuery.disableAnimationsOf(context);
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_checkVisible);
      _scroll = next?..addListener(_checkVisible);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisible());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _scroll?.removeListener(_checkVisible);
    _ticker.dispose();
    _field.dispose();
    super.dispose();
  }

  void _checkVisible() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screen = MediaQuery.sizeOf(context).height;
    _visible = top < screen && top + box.size.height > 0;
    if (!_visible) _applyPendingDrop();
    _syncTicker();
  }

  void _syncTicker() {
    final run =
        _visible &&
        _field.models != null &&
        !(_field.reduceMotion && _field.settled);
    if (run && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    // A degraded field steps at its tier's capped rate, not every vsync.
    final interval = _field.minFrameInterval;
    if (interval > Duration.zero &&
        _last != Duration.zero &&
        elapsed - _last < interval) {
      return;
    }
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 24);
    _last = elapsed;
    _field.step(dt);
    if (_field.reduceMotion && _field.settled) _syncTicker();
  }

  void _wake() {
    if (!_ticker.isActive && _visible && _field.models != null) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _background;
    final inset = Offset(0, widget.touchTopInset);
    Widget band(_Band b) {
      final blur = _field.blur ? GemFieldController._blurOf(b) : 0.0;
      Widget layer = CustomPaint(
        painter: _BandPainter(_field, b, bg),
        size: Size.infinite,
      );
      if (blur > 0) {
        layer = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blur,
            sigmaY: blur,
            tileMode: TileMode.decal,
          ),
          child: layer,
        );
      }
      return Positioned.fill(child: layer);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _field.layout(constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: bg),
                    for (final b in _Band.values) band(b),
                    Positioned.fill(
                      child: CustomPaint(painter: _LightPainter(_field)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              top: widget.touchTopInset,
              // The eager recognizer wins the gesture arena on touch-down,
              // so the page does not scroll while a finger plays with the
              // stones (same as the home hero).
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  EagerGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        EagerGestureRecognizer
                      >(EagerGestureRecognizer.new, (_) {}),
                },
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    _field.pointerDown(e.localPosition + inset);
                    _wake();
                  },
                  onPointerMove: (e) {
                    _field.pointerMove(e.localPosition + inset);
                    _wake();
                  },
                  onPointerUp: (_) => _field.pointerUp(),
                  onPointerCancel: (_) => _field.pointerUp(),
                  child: MouseRegion(
                    onHover: (e) {
                      // Desktop / web: hovering is the cursor, as on the
                      // original site.
                      _field.pointerMove(e.localPosition + inset);
                      _wake();
                    },
                    onExit: (_) => _field.pointerUp(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.field, this.band, this.fog) : super(repaint: field);

  final GemFieldController field;
  final _Band band;
  final Color fog;

  @override
  void paint(Canvas canvas, Size size) => field._paintBand(canvas, band, fog);

  @override
  bool shouldRepaint(covariant _BandPainter old) =>
      old.field != field || old.band != band || old.fog != fog;
}

class _LightPainter extends CustomPainter {
  _LightPainter(this.field) : super(repaint: field);

  final GemFieldController field;

  @override
  void paint(Canvas canvas, Size size) => field._paintLight(canvas);

  @override
  bool shouldRepaint(covariant _LightPainter old) => old.field != field;
}

/// Lazily rendered soft white disc, tinted per stone for the glow a
/// fluorescent diamond throws around itself.
abstract final class _FluorHalo {
  static const size = 64.0;
  static ui.Image? _image;

  static ui.Image get image => _image ??= _render();

  static ui.Image _render() {
    final recorder = ui.PictureRecorder();
    const c = Offset(size / 2, size / 2);
    Canvas(recorder).drawCircle(
      c,
      size / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          size / 2,
          const [Color(0xFFFFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
          const [0, 0.35, 1],
        ),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.toInt(), size.toInt());
    picture.dispose();
    return image;
  }
}
