import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../haptics/app_haptics.dart';
import 'gem_mesh.dart';
import 'gem_renderer.dart';

/// Depth bands painted as separate layers so far and near stones can be
/// defocused (depth of field) without blurring the in-focus band.
enum _Band { far, focus, near }

class _FieldGem {
  _FieldGem({
    required this.cut,
    required this.look,
    required this.band,
    required this.s,
    required this.q,
    required this.hz,
    required this.limS,
    required this.speed,
    required this.scale,
    required this.phase,
    required this.bob,
    required this.spinX,
    required this.spinY,
    required this.spinZ,
  }) : pose = GemPose(z: hz, scale: scale);

  final GemCut cut;
  final GemLook look;
  final _Band band;

  /// Rest position in flow coordinates: [s] runs along the flow and wraps
  /// inside ±[limS], [q] is the lane across it.
  double s;
  final double q, hz;
  final double limS, speed;
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

/// Physics for a dense herd of 3D stones streaming together from the
/// top-left to the bottom-right corner through deep darkness, modelled on
/// the Lusion / Oryzo coffee-bean footer.
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

  Offset _waveAt = Offset.zero;
  double _waveAge = -1;

  static const _cuts = GemCut.values;

  /// World units across the field width.
  static const worldWidth = 6.4;

  /// Herd pace multiplier (2× the original drift).
  static const _flowSpeed = 2.0;

  /// Depth slab the stones live in: back edge and thickness.
  static const _zNear = -1.9;
  static const _zDepth = 2.8;

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
    final rng = math.Random(seed);
    const halfW = worldWidth / 2;
    final halfH = size.height / unit / 2;
    // Dense like a pour of beans, capped for frame budget.
    final count = (size.width * size.height / 1100).round().clamp(90, 250);

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
      final band = z < -1.4
          ? _Band.far
          : z > 0.45
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
      final pick = rng.nextDouble();
      final look = pick < 0.12
          ? GemLook.champagne
          : pick < 0.2
          ? GemLook.ice
          : GemLook.white;
      final g = _FieldGem(
        cut: _cuts[rng.nextInt(_cuts.length)],
        look: look,
        band: band,
        s: s0,
        q: q0,
        hz: z,
        limS: limS,
        // One pace for the whole herd; nearer stones a touch faster for
        // depth parallax.
        speed:
            _flowSpeed *
            (0.72 + 0.16 * ((z - _zNear) / _zDepth)) *
            (0.97 + rng.nextDouble() * 0.06),
        scale: 0.16 + rng.nextDouble() * 0.16,
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
    }
    _energy = 1;
  }

  void step(double dt) {
    if (_gems.isEmpty) return;
    _time += dt;
    final cam = camera;
    final pointer = _pointer;
    final idle = reduceMotion ? 0.0 : 1.0;
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
      final p = g.pose;

      // The herd streams along the diagonal and wraps along the flow,
      // teleporting the pose with its rest point so wraps happen off
      // screen, unseen.
      if (idle > 0) {
        g.s += g.speed * dt;
        if (g.s > g.limS) {
          g.s -= 2 * g.limS;
          p.x -= 2 * g.limS * _flowX;
          p.y -= 2 * g.limS * _flowY;
        }
      }
      // One shared ripple travels down the stream, so neighbours sway
      // together like a herd instead of wandering on their own.
      final lane = g.q + 0.16 * math.sin(g.s * 0.85 - _time * 1.3) * idle;
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
    for (final g in _gems) {
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

  void _paintBand(Canvas canvas, _Band band, GemBatch batch, Color fog) {
    final cam = camera;
    final items = [
      for (final g in _gems)
        if (g.band == band) g,
    ]..sort((a, b) => a.pose.z.compareTo(b.pose.z));
    batch.reset();
    for (final g in items) {
      // Stones rest deep in the dark, deeper with distance, and surface
      // only where the finger's light reaches them.
      final depth = ((0.9 - g.pose.z) / 3.3).clamp(0.0, 1.0);
      final fog01 = ((0.6 + 0.28 * depth) * (1 - g.lit * 0.95)).clamp(0.0, 0.9);
      batch.addGem(
        mesh: GemMesh.of(g.cut),
        pose: g.pose,
        camera: cam,
        look: g.look,
        time: _time,
        fog: fog01,
        fogColor: fog,
        flash: g.flash,
        light: g.lit,
        lightFrom: g.lit > 0
            ? _glowAt - cam.project(g.pose.x, g.pose.y, g.pose.z)
            : Offset.zero,
        phase: g.phase,
        glint: g.lit > 0.15 || g.flash > 0,
        flat: band == _Band.far,
      );
    }
    batch.paint(canvas, glintSprite: GemGlintSprite.image);
  }

  /// A faint warm pool under the finger; the stones carry the light.
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
            Color.fromRGBO(255, 226, 180, 0.07 * _glow),
            Color.fromRGBO(221, 191, 136, 0.025 * _glow),
            const Color(0x00000000),
          ],
          const [0, 0.4, 1],
        ),
    );
  }
}

/// Full-bleed field of 3D diamonds of every cut streaming diagonally that
/// part around the finger, tumble when swept and catch its light. Pauses while scrolled off screen and
/// honours reduced motion.
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
    final run = _visible && !(_field.reduceMotion && _field.settled);
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
    if (!_ticker.isActive && _visible) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.background;
    final inset = Offset(0, widget.touchTopInset);
    Widget band(_Band b, double blur) {
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
  final _batch = GemBatch();

  @override
  void paint(Canvas canvas, Size size) {
    field._paintBand(canvas, band, _batch, fog);
  }

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
