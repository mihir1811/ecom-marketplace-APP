import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../haptics/app_haptics.dart';
import 'diamond_mesh.dart';
import 'diamond_models.dart';
import 'diamond_renderer.dart';
import 'gem_renderer.dart';

/// Depth bands painted as separate layers so far and near stones can be
/// defocused (depth of field) without blurring the in-focus band.
enum _Band { far, focus, near }

class _FieldGem {
  _FieldGem({
    required this.band,
    required this.pick,
    required this.rank,
    required this.s,
    required this.q,
    required this.hz,
    required this.limS,
    required this.speed,
    required this.surge,
    required this.surgeRate,
    required this.scale,
    required this.phase,
    required this.bob,
    required this.spinX,
    required this.spinY,
    required this.spinZ,
  }) : pose = GemPose(z: hz, scale: scale);

  final _Band band;

  /// 0..1 choice of cut, mapped onto however many models are loaded.
  final double pick;

  /// 0..1 draw order for adaptive quality: when the device cannot keep
  /// up, stones with the highest rank sit out first. Random, so the herd
  /// thins evenly.
  final double rank;

  /// Rest position in flow coordinates: [s] runs along the flow and wraps
  /// inside ±[limS], [q] is the lane across it.
  double s;
  final double q, hz;
  final double limS, speed;

  /// Each stone's pace swells and eases by up to ±[surge] of [speed],
  /// [surgeRate] radians per second, so it drifts, catches up and falls
  /// back instead of gliding at a constant rate.
  final double surge, surgeRate;
  double hx = 0, hy = 0;
  final double scale, phase, bob;
  final double spinX, spinY, spinZ;
  final GemPose pose;
  double vx = 0, vy = 0, vz = 0;
  double wx = 0, wy = 0, wz = 0;
  double flash = 0;

  /// 0..1 light from the finger; rises fast near it, lingers after.
  double lit = 0;
}

/// Physics for a dense herd of colourless 3D diamonds of every bundled cut
/// and many sizes, streaming together from the top-left to the
/// bottom-right corner through deep darkness, modelled on the Lusion /
/// Oryzo coffee-bean footer.
///
/// The finger (or mouse) is a solid body moving through the cloud: it
/// carves a clean round void, stones bank up into a ring around its edge,
/// a swipe drags and flings the stones it sweeps through and sets them
/// tumbling, and they flow back to fill the wake once it passes. A warm
/// light rides with the finger so the stones around it catch fire. A tap
/// sends a shockwave through the cloud.
class GemFieldController extends ChangeNotifier {
  GemFieldController({required this.seed, required this.reduceMotion});

  final int seed;
  bool reduceMotion;

  final List<_FieldGem> _gems = [];
  Size _size = Size.zero;
  double _time = 0;
  double _flowX = 0, _flowY = 0;

  Offset? _pointer;
  Offset _cursor = Offset.zero;
  double _presence = 0;
  Offset _pointerVelocity = Offset.zero;
  Duration? _lastMove;
  Offset _downAt = Offset.zero;
  Duration _downTime = Duration.zero;
  Offset _glowAt = Offset.zero;
  double _glow = 0;
  double _eyeX = 0, _eyeY = 0;
  double _energy = 0;

  /// 1 while nobody touches the field: stones shine in the studio light
  /// with sparkles and little fog. Drops fast on touch so the finger-lit
  /// look takes over, and eases back after release.
  double _calm = 1;

  Offset _waveAt = Offset.zero;
  double _waveAge = -1;

  /// Baked cuts; nothing is drawn until they are set.
  List<DiamondModel>? models;

  /// Quality tiers, best first. The widget steps down one tier whenever
  /// frames run long: first the depth-of-field blur goes (the costliest
  /// GPU work), then a share of the stones, then fine facets. Stones drawn
  /// at least `detail` pixels in radius use the full model.
  static const _tiers = [
    (blur: true, density: 1.0, detail: 22.0),
    (blur: false, density: 1.0, detail: 22.0),
    (blur: false, density: 0.75, detail: 36.0),
    (blur: false, density: 0.55, detail: double.infinity),
  ];
  int _quality = 0;

  bool get blur => _tiers[_quality].blur;

  /// Drops to the next cheaper tier; false when already at the cheapest.
  bool lowerQuality() {
    if (_quality == _tiers.length - 1) return false;
    _quality++;
    return true;
  }

  final List<List<_FieldGem>> _bands = [for (final _ in _Band.values) []];
  final List<DiamondBatch> _batches = [
    for (final _ in _Band.values) DiamondBatch(),
  ];

  /// World units across the field width.
  static const worldWidth = 6.4;

  /// Herd pace multiplier (2× the original drift).
  static const _flowSpeed = 2.0;

  /// Depth slab the stones live in: back edge and thickness. Shallow and
  /// pulled toward the viewer so the herd reads close and packed.
  static const _zNear = -1.4;
  static const _zDepth = 2.5;

  /// Depth-of-field band edges.
  static const _zFar = -0.95, _zFront = 0.65;

  /// Radius of the void carved around the finger, in logical pixels.
  double get voidRadius => (_size.shortestSide * 0.2).clamp(64.0, 130.0);

  /// Radius of the light carried by the finger, in logical pixels.
  double get lightRadius => voidRadius * 2.3;

  double get unit => _size.width / worldWidth;

  GemCamera get camera => GemCamera(
    center: _size.center(Offset.zero),
    unit: unit,
    distance: 9,
    eyeX: _eyeX,
    eyeY: _eyeY,
  );

  bool get settled =>
      _calm == 1 &&
      _pointer == null &&
      _presence == 0 &&
      _energy < 0.002 &&
      _glow == 0 &&
      _waveAge < 0;

  /// Seeds stones for [size]; keeps them when the size barely changes.
  void layout(Size size) {
    if (size.isEmpty) return;
    if (_gems.isNotEmpty &&
        (size.width - _size.width).abs() < 1 &&
        (size.height - _size.height).abs() < 1) {
      return;
    }
    final first = _gems.isEmpty;
    _size = size;
    _gems.clear();
    for (final b in _bands) {
      b.clear();
    }
    final rng = math.Random(seed);
    const halfW = worldWidth / 2;
    final halfH = size.height / unit / 2;
    // Packed like a pour of beans, capped for frame budget.
    final count = (size.width * size.height / 560).round().clamp(160, 420);

    // Flow along the screen diagonal: top-left → bottom-right.
    final len = math.sqrt(halfW * halfW + halfH * halfH);
    _flowX = halfW / len;
    _flowY = -halfH / len;
    // Half the screen's extent across the flow.
    final across = 2 * halfW * halfH / len;

    for (var i = 0; i < count; i++) {
      // A shallow depth slab, pulled toward the viewer, keeps the herd
      // close and tightly packed.
      final z = _zNear + rng.nextDouble() * _zDepth;
      final band = z < _zFar
          ? _Band.far
          : z > _zFront
          ? _Band.near
          : _Band.focus;
      // Wider bounds at depth so the frame stays filled under perspective;
      // the margin lets stones enter and leave fully off screen.
      final spread = 9 / (9 - z);
      final limS = (len + 0.8) / spread;
      // Stratified along the flow so the herd has no gaps; lanes bunch
      // toward the middle of the stream so it reads as one body.
      final s0 = -limS + (i + 0.2 + rng.nextDouble() * 0.6) * 2 * limS / count;
      final q0 =
          (rng.nextDouble() + rng.nextDouble() - 1) * (across + 0.5) / spread;
      final x = s0 * _flowX - q0 * _flowY;
      final y = s0 * _flowY + q0 * _flowX;
      final g = _FieldGem(
        band: band,
        pick: rng.nextDouble(),
        rank: rng.nextDouble(),
        s: s0,
        q: q0,
        hz: z,
        limS: limS,
        // Every stone keeps its own pace: most drift, some dawdle, a few
        // dart through the herd. Nearer stones are a touch faster for depth
        // parallax; the herd's average pace stays the same.
        speed:
            _flowSpeed * (0.72 + 0.16 * ((z - _zNear) / _zDepth)) * _pace(rng),
        surge: 0.15 + rng.nextDouble() * 0.3,
        surgeRate: 0.25 + rng.nextDouble() * 0.9,
        // Mostly small stones with the odd big one, like a real pour.
        scale: 0.1 + 0.26 * math.pow(rng.nextDouble(), 1.8),
        phase: rng.nextDouble(),
        bob: 0.02 + rng.nextDouble() * 0.03,
        spinX: (rng.nextDouble() - 0.5) * 0.5,
        spinY: (0.15 + rng.nextDouble() * 0.35) * (rng.nextBool() ? 1 : -1),
        spinZ: (rng.nextDouble() - 0.5) * 0.3,
      );
      g
        ..hx = x
        ..hy = y
        ..pose.x = x
        ..pose.y = y;
      g.pose
        ..rx = rng.nextDouble() * math.pi * 2
        ..ry = rng.nextDouble() * math.pi * 2
        ..rz = rng.nextDouble() * math.pi * 2;
      if (first && !reduceMotion) {
        // Entrance: stones pour in from the top-left and settle.
        g.pose
          ..x = x - 1.5
          ..y = y + 1.5;
      }
      _gems.add(g);
      _bands[band.index].add(g);
    }
    _energy = 1;
  }

  /// Pace multiplier, averaging about 1: 15% slow stones (0.35–0.6×),
  /// 70% around the herd's pace (0.7–1.25×) and 15% fast ones (1.5–2.3×).
  static double _pace(math.Random rng) {
    final kind = rng.nextDouble();
    final r = rng.nextDouble();
    if (kind < 0.15) return 0.35 + r * 0.25;
    if (kind < 0.85) return 0.7 + r * 0.55;
    return 1.5 + r * 0.8;
  }

  void step(double dt) {
    if (_gems.isEmpty) return;
    _time += dt;
    final cam = camera;
    final pointer = _pointer;
    final idle = reduceMotion ? 0.0 : 1.0;
    final density = _tiers[_quality].density;
    var energy = 0.0;

    // The body follows the finger tightly; it fades in on contact and out
    // on release so the void opens and closes instead of popping.
    if (pointer != null) {
      _cursor = _presence == 0
          ? pointer
          : Offset.lerp(_cursor, pointer, 1 - math.exp(-38 * dt))!;
      _presence = math.min(1, _presence + dt * 7);
    } else {
      _presence = math.max(0, _presence - dt * 3.2);
    }
    final presence = _presence * _presence * (3 - 2 * _presence);

    // Camera parallax follows the finger, gently.
    final targetEyeX = pointer == null || reduceMotion
        ? 0.0
        : (pointer.dx / _size.width - 0.5) * 0.3;
    final targetEyeY = pointer == null || reduceMotion
        ? 0.0
        : -(pointer.dy / _size.height - 0.5) * 0.2;
    final ease = 1 - math.exp(-3 * dt);
    _eyeX += (targetEyeX - _eyeX) * ease;
    _eyeY += (targetEyeY - _eyeY) * ease;

    // Warm light carried by the finger, trailing it slightly.
    if (pointer != null) {
      _glowAt = _glow == 0
          ? pointer
          : Offset.lerp(_glowAt, pointer, 1 - math.exp(-14 * dt))!;
      _glow = math.min(1, _glow + dt * 4);
    } else {
      _glow = math.max(0, _glow - dt * 1.6);
    }

    if (pointer != null || _waveAge >= 0) {
      _calm = math.max(0, _calm - dt * 5);
    } else {
      _calm = math.min(1, _calm + dt * 1.1);
    }

    // Shockwave from a tap: a ring that expands and fades.
    double waveR = 0, waveStrength = 0;
    if (_waveAge >= 0) {
      _waveAge += dt;
      const life = 0.7;
      if (_waveAge > life) {
        _waveAge = -1;
      } else {
        final t = _waveAge / life;
        waveR = voidRadius * (0.4 + 3.2 * (1 - (1 - t) * (1 - t)));
        waveStrength = (1 - t) * (1 - t);
      }
    }

    final r0 = voidRadius;
    final reach = r0 * 1.45;
    final lightR = lightRadius;
    final cursor = _cursor;
    final vel = _pointerVelocity;

    for (final g in _gems) {
      // Stones sitting out at this quality tier cost nothing.
      if (g.rank >= density) continue;
      final p = g.pose;

      // The herd streams along the diagonal and wraps along the flow,
      // teleporting the pose with its rest point so wraps happen off
      // screen, unseen.
      if (idle > 0) {
        final swell = math.sin(_time * g.surgeRate + g.phase * 6.283);
        g.s += g.speed * (1 + g.surge * swell) * dt;
        if (g.s > g.limS) {
          g.s -= 2 * g.limS;
          p.x -= 2 * g.limS * _flowX;
          p.y -= 2 * g.limS * _flowY;
        }
      }
      // Each stone keeps its lane: the stream runs straight along the
      // diagonal.
      final lane = g.q;
      g.hx = g.s * _flowX - lane * _flowY;
      g.hy = g.s * _flowY + lane * _flowX;

      // Soft, slightly under-damped spring home: stones swing back into
      // the wake with a little give, like beans settling.
      final ty = g.hy + math.sin(_time * 0.7 + g.phase * 6.283) * g.bob * idle;
      var ax = (g.hx - p.x) * 6.5 - g.vx * 3.4;
      var ay = (ty - p.y) * 6.5 - g.vy * 3.4;
      var az = (g.hz - p.z) * 6.5 - g.vz * 3.4;

      var lightTarget = 0.0;
      if (presence > 0 || waveStrength > 0) {
        final sp = cam.project(p.x, p.y, p.z);
        // Pixels → world at this stone's depth.
        final toWorld = 1 / (unit * cam.depthScale(p.z));
        var pushX = 0.0, pushY = 0.0;

        if (presence > 0) {
          final dx = sp.dx - cursor.dx, dy = sp.dy - cursor.dy;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < reach) {
            final ux = dist < 0.001 ? 0.0 : dx / dist;
            final uy = dist < 0.001 ? -1.0 : dy / dist;
            // Stiff contact inside the void, a soft cushion just outside
            // it: stones are shoved clear and bank up into a ring.
            var push = dist < r0 ? (r0 - dist) * 62 + 30 : 0.0;
            push += (reach - math.max(dist, r0)) * 14;
            push *= presence * toWorld;
            pushX = ux * push;
            pushY = -uy * push;
            // Squeezed in depth too, so the void reads as a solid body.
            az += (p.z >= 0 ? 1 : -1) * push * 0.18;

            // Entrainment: stones the finger sweeps through are dragged
            // toward its velocity, then flung on as it passes.
            final f = 1 - dist / reach;
            final drag = f * f * 7 * presence;
            ax += (vel.dx * toWorld - g.vx) * drag;
            ay += (-vel.dy * toWorld - g.vy) * drag;
          }
          if (dist < lightR) {
            final f = 1 - dist / lightR;
            lightTarget = math.sqrt(f * f * (3 - 2 * f)) * presence;
          }
        }

        if (waveStrength > 0) {
          final dx = sp.dx - _waveAt.dx, dy = sp.dy - _waveAt.dy;
          final dist = math.sqrt(dx * dx + dy * dy);
          const width = 46.0;
          final band = (dist - waveR).abs();
          if (band < width) {
            final f = 1 - band / width;
            final ux = dist < 0.001 ? 0.0 : dx / dist;
            final uy = dist < 0.001 ? -1.0 : dy / dist;
            final push = f * f * waveStrength * 900 * toWorld;
            pushX += ux * push;
            pushY -= uy * push;
            lightTarget = math.max(lightTarget, f * waveStrength);
          }
        }

        // Shoved stones tumble: torque from the push across each axis.
        if (pushX != 0 || pushY != 0) {
          ax += pushX;
          ay += pushY;
          g.wx -= pushY * dt * 0.45;
          g.wy += pushX * dt * 0.45;
          g.wz += (pushX - pushY) * dt * 0.12 * (g.spinY >= 0 ? 1 : -1);
        }
      }

      if (lightTarget > g.lit) {
        g.lit += (lightTarget - g.lit) * math.min(1.0, dt * 12);
      } else {
        // Light lingers on stones the finger has passed.
        g.lit = math.max(lightTarget, g.lit - dt * 0.9);
      }

      g.vx += ax * dt;
      g.vy += ay * dt;
      g.vz += az * dt;
      p.x += g.vx * dt;
      p.y += g.vy * dt;
      p.z += g.vz * dt;

      // Tumble is capped, then bleeds back to the idle spin.
      const maxSpin = 13.0;
      g.wx = g.wx.clamp(-maxSpin, maxSpin);
      g.wy = g.wy.clamp(-maxSpin, maxSpin);
      g.wz = g.wz.clamp(-maxSpin, maxSpin);
      final spinEase = 1 - math.exp(-0.95 * dt);
      g.wx += (g.spinX * idle - g.wx) * spinEase;
      g.wy += (g.spinY * idle - g.wy) * spinEase;
      g.wz += (g.spinZ * idle - g.wz) * spinEase;
      p.rx += g.wx * dt;
      p.ry += g.wy * dt;
      p.rz += g.wz * dt;
      g.flash = math.max(0, g.flash - dt * 1.4);

      energy +=
          g.vx * g.vx +
          g.vy * g.vy +
          g.vz * g.vz +
          (g.wx - g.spinX * idle).abs() +
          (g.wy - g.spinY * idle).abs() +
          g.flash +
          g.lit;
    }
    _energy = energy / _gems.length;

    _pointerVelocity *= math.exp(-6 * dt);
    notifyListeners();
  }

  void pointerDown(Offset at, Duration stamp) {
    _pointer = at;
    _downAt = at;
    _downTime = stamp;
    _lastMove = stamp;
    _pointerVelocity = Offset.zero;
  }

  void pointerMove(Offset at, Offset delta, Duration stamp) {
    _pointer = at;
    // Smoothed px/s from event timing, capped so a flick stays graceful.
    final last = _lastMove;
    _lastMove = stamp;
    final secs = last == null
        ? 1 / 60
        : ((stamp - last).inMicroseconds / 1e6).clamp(1 / 240, 1 / 20);
    var v = delta / secs;
    if (v.distance > 4200) v = v / v.distance * 4200;
    _pointerVelocity = Offset.lerp(_pointerVelocity, v, 0.45)!;
  }

  void pointerUp(Duration stamp) {
    final tap =
        _pointer != null &&
        (_pointer! - _downAt).distance < 12 &&
        stamp - _downTime < const Duration(milliseconds: 300);
    if (tap) _tapPulse(_downAt);
    _pointer = null;
    _lastMove = null;
  }

  void pointerCancel() {
    _pointer = null;
    _lastMove = null;
  }

  /// A tap sends a shockwave through the cloud and flares the nearest
  /// stone.
  void _tapPulse(Offset at) {
    final cam = camera;
    _FieldGem? nearest;
    var nearestD = double.infinity;
    final density = _tiers[_quality].density;
    for (final g in _gems) {
      if (g.rank >= density) continue;
      final p = g.pose;
      final d = (cam.project(p.x, p.y, p.z) - at).distance;
      if (d < nearestD) {
        nearestD = d;
        nearest = g;
      }
    }
    if (nearest != null && nearestD < voidRadius) {
      nearest
        ..flash = 1
        ..lit = 1
        ..wy += 10;
    }
    _waveAt = at;
    _waveAge = 0;
    AppHaptics.light();
  }

  void _paintBand(Canvas canvas, _Band band, Color fog) {
    final models = this.models;
    if (models == null) return;
    final cam = camera;
    final tier = _tiers[_quality];
    final detailScale = tier.detail / unit;
    final sparkle = DiamondSparkle.image;
    final sparkleWidth = sparkle.width.toDouble();
    // Back to front. The list is reused and stays nearly sorted from frame
    // to frame, so this is cheap.
    final items = _bands[band.index]
      ..sort((a, b) => a.pose.z.compareTo(b.pose.z));
    final batch = _batches[band.index]..reset();
    for (final g in items) {
      if (g.rank >= tier.density) continue;
      final model = models[(g.pick * models.length).floor() % models.length];
      // Idle, stones shine as cut diamonds, dimming with distance. Under
      // the finger they rest deep in the dark and surface only where its
      // light reaches them.
      final depth = ((0.9 - g.pose.z) / 3.3).clamp(0.0, 1.0);
      final dark = (0.6 + 0.28 * depth) * (1 - g.lit * 0.95);
      final idle = 0.06 + 0.4 * depth;
      final fog01 = (dark + (idle - dark) * _calm).clamp(0.0, 0.9);
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
        fog: fog01,
        fogColor: fog,
        flash: g.flash,
        light: g.lit,
        lightFrom: g.lit > 0
            ? _glowAt - cam.project(g.pose.x, g.pose.y, g.pose.z)
            : Offset.zero,
        phase: g.phase,
        sparkle:
            g.lit > 0.15 || g.flash > 0 || (_calm > 0.3 && band != _Band.far),
        sparkleWidth: sparkleWidth,
        // Clear-crystal shading for every cut but pear, whose many small
        // facets already read as a diamond. Blurred far stones skip it.
        seeThrough: band != _Band.far && model.name != 'pear',
      );
    }
    batch.paint(canvas, sparkle: sparkle);
  }

  /// A faint white pool under the finger; the stones carry the light.
  void _paintLight(Canvas canvas) {
    if (_glow <= 0) return;
    final r = lightRadius;
    canvas.drawCircle(
      _glowAt,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          _glowAt,
          r,
          [
            Color.fromRGBO(255, 255, 255, 0.05 * _glow),
            Color.fromRGBO(255, 255, 255, 0.018 * _glow),
            const Color(0x00000000),
          ],
          const [0, 0.4, 1],
        ),
    );
  }
}

/// Full-bleed field of colourless 3D diamonds in every bundled cut
/// ([DiamondModels]) streaming diagonally that part around the finger,
/// tumble when swept and catch its light. Pauses while scrolled off
/// screen, honours reduced motion, and lowers its own quality when the
/// device cannot keep up.
///
/// Touches below [touchTopInset] are claimed eagerly so the page does not
/// scroll while a finger plays with the stones; above it, scrolling works
/// as usual (so the page can always be scrolled back up).
class GemField extends StatefulWidget {
  const GemField({
    super.key,
    this.background = const Color(0xFF070709),
    this.seed = 7,
    this.touchTopInset = 0,
  });

  final Color background;
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

  @override
  void initState() {
    super.initState();
    // The herd waits for the models, so its entrance plays once they are in.
    DiamondModels.load()
        .catchError((Object _) => DiamondModels.fallback())
        .then((models) {
          if (!mounted) return;
          _field.models = models;
          _syncTicker();
        });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  /// Watches real frame cost (UI and raster threads) while the field
  /// animates, and steps quality down when frames run long for about a
  /// second, so slow devices still show a steady herd.
  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || !_ticker.isActive) return;
    for (final t in timings) {
      final ms =
          math.max(
            t.buildDuration.inMicroseconds,
            t.rasterDuration.inMicroseconds,
          ) /
          1000;
      _frameCost = _frameSamples == 0 ? ms : _frameCost * 0.85 + ms * 0.15;
      _frameSamples++;
    }
    if (_frameSamples >= 50 && _frameCost > 20 && _field.lowerQuality()) {
      _frameSamples = 0;
      setState(() {});
    }
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
    final bg = widget.background;
    final inset = Offset(0, widget.touchTopInset);
    Widget band(_Band b, double blur) {
      if (!_field.blur) blur = 0;
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
                    band(_Band.far, 3.2),
                    band(_Band.focus, 0),
                    band(_Band.near, 1.8),
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
                    _field.pointerDown(e.localPosition + inset, e.timeStamp);
                    _wake();
                  },
                  onPointerMove: (e) {
                    _field.pointerMove(
                      e.localPosition + inset,
                      e.delta,
                      e.timeStamp,
                    );
                    _wake();
                  },
                  onPointerUp: (e) => _field.pointerUp(e.timeStamp),
                  onPointerCancel: (_) => _field.pointerCancel(),
                  child: MouseRegion(
                    onHover: (e) {
                      // Desktop / web: hover behaves like a resting finger.
                      _field.pointerMove(
                        e.localPosition + inset,
                        e.delta,
                        e.timeStamp,
                      );
                      _wake();
                    },
                    onExit: (_) => _field.pointerCancel(),
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
