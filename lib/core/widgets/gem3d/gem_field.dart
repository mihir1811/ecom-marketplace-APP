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
    required this.hx,
    required this.hy,
    required this.hz,
    required this.limX,
    required this.limY,
    required this.speed,
    required this.scale,
    required this.phase,
    required this.bob,
    required this.spinX,
    required this.spinY,
    required this.spinZ,
  }) : pose = GemPose(x: hx, y: hy, z: hz, scale: scale);

  final GemCut cut;
  final GemLook look;
  final _Band band;

  /// Rest position; it drifts along the flow and wraps inside ±lim.
  double hx, hy, hz;
  final double limX, limY, speed;
  final double scale, phase, bob;
  final double spinX, spinY, spinZ;
  final GemPose pose;
  double vx = 0, vy = 0, vz = 0;
  double wx = 0, wy = 0, wz = 0;
  double flash = 0;

  /// 0..1 touch light; rises fast under the finger, fades after.
  double lit = 0;
}

/// A short-lived four-point sparkle (jewelry-stage style) near the touch.
class _Spark {
  _Spark(this.x, this.y, this.vx, this.vy, this.life, this.size, this.tint);

  double x, y;
  final double vx, vy;
  final double life;
  final double size;
  final double tint;
  double age = 0;
}

/// Physics for a field of 3D stones drifting from the top-left to the
/// bottom-right corner.
///
/// Touch barely parts the stones; instead it lights them: stones under and
/// around the finger flare, glint and twinkle, sparks scatter from the
/// fingertip and a warm light follows it. A tap flashes the nearest stone.
class GemFieldController extends ChangeNotifier {
  GemFieldController({required this.seed, required this.reduceMotion});

  final int seed;
  bool reduceMotion;

  final List<_FieldGem> _gems = [];
  final List<_Spark> _sparks = [];
  final math.Random _rng = math.Random(11);
  Size _size = Size.zero;
  double _time = 0;
  double _flowX = 0, _flowY = 0;

  Offset? _pointer;
  Offset _pointerVelocity = Offset.zero;
  Offset _downAt = Offset.zero;
  Duration _downTime = Duration.zero;
  Offset _glowAt = Offset.zero;
  double _glow = 0;
  double _eyeX = 0, _eyeY = 0;
  double _energy = 0;
  double _sparkBudget = 0;

  static const _cuts = GemCut.values;

  /// World units across the field width.
  static const worldWidth = 6.4;

  /// Touch light radius in logical pixels (scaled by depth).
  static const lightRadius = 150.0;

  double get unit => _size.width / worldWidth;

  GemCamera get camera => GemCamera(
    center: _size.center(Offset.zero),
    unit: unit,
    distance: 9,
    eyeX: _eyeX,
    eyeY: _eyeY,
  );

  bool get settled =>
      _pointer == null && _energy < 0.002 && _sparks.isEmpty && _glow == 0;

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
    // Three times the original density, capped for frame budget.
    final count = (size.width * size.height / 5200 * 3).round().clamp(
      60,
      170,
    );

    // Flow along the screen diagonal: top-left → bottom-right.
    final len = math.sqrt(halfW * halfW + halfH * halfH);
    _flowX = halfW / len;
    _flowY = -halfH / len;

    // Jittered grid keeps coverage even without clumps.
    final cols = math.max(4, math.sqrt(count * halfW / halfH).round());
    final rows = (count / cols).ceil();
    for (var i = 0; i < count; i++) {
      final col = i % cols, row = i ~/ cols;
      final z = -3.8 + rng.nextDouble() * 4.9;
      final band = z < -1.7
          ? _Band.far
          : z > 0.35
          ? _Band.near
          : _Band.focus;
      // Wider bounds at depth so the frame stays filled under perspective;
      // the margin lets stones enter and leave fully off screen.
      final spread = 9 / (9 - z);
      final limX = (halfW + 0.7) / spread;
      final limY = (halfH + 0.7) / spread;
      final x = -limX + (col + 0.15 + rng.nextDouble() * 0.7) * 2 * limX / cols;
      final y = limY - (row + 0.15 + rng.nextDouble() * 0.7) * 2 * limY / rows;
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
        hx: x,
        hy: y,
        hz: z,
        limX: limX,
        limY: limY,
        // Nearer stones travel faster for depth parallax.
        speed: (0.22 + 0.16 * ((z + 3.8) / 4.9)) * (0.85 + rng.nextDouble() * 0.3),
        scale: 0.17 + rng.nextDouble() * 0.17,
        phase: rng.nextDouble(),
        bob: 0.03 + rng.nextDouble() * 0.05,
        spinX: (rng.nextDouble() - 0.5) * 0.5,
        spinY: (0.15 + rng.nextDouble() * 0.35) * (rng.nextBool() ? 1 : -1),
        spinZ: (rng.nextDouble() - 0.5) * 0.3,
      );
      g.pose
        ..rx = rng.nextDouble() * math.pi * 2
        ..ry = rng.nextDouble() * math.pi * 2
        ..rz = rng.nextDouble() * math.pi * 2;
      if (first && !reduceMotion) {
        // Entrance: stones drift in from the top-left and settle.
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

    // Camera parallax follows the finger, gently.
    final targetEyeX = pointer == null || reduceMotion
        ? 0.0
        : (pointer.dx / _size.width - 0.5) * 0.35;
    final targetEyeY = pointer == null || reduceMotion
        ? 0.0
        : -(pointer.dy / _size.height - 0.5) * 0.25;
    final ease = 1 - math.exp(-3 * dt);
    _eyeX += (targetEyeX - _eyeX) * ease;
    _eyeY += (targetEyeY - _eyeY) * ease;

    // Warm light that follows the finger and fades on release.
    if (pointer != null) {
      _glowAt = Offset.lerp(_glowAt, pointer, 1 - math.exp(-20 * dt))!;
      _glow = math.min(1, _glow + dt * 5);
    } else {
      _glow = math.max(0, _glow - dt * 2.2);
    }

    for (final g in _gems) {
      final p = g.pose;

      // Continuous diagonal flow with wrap-around (torus), teleporting the
      // pose with its rest point so wraps happen off screen, unseen.
      if (idle > 0) {
        final d = g.speed * dt;
        g.hx += _flowX * d;
        g.hy += _flowY * d;
        if (g.hx > g.limX) {
          g.hx -= 2 * g.limX;
          p.x -= 2 * g.limX;
        }
        if (g.hy < -g.limY) {
          g.hy += 2 * g.limY;
          p.y += 2 * g.limY;
        }
      }

      final ty = g.hy + math.sin(_time * 0.7 + g.phase * 6.283) * g.bob * idle;
      var ax = (g.hx - p.x) * 10 - g.vx * 4.2;
      var ay = (ty - p.y) * 10 - g.vy * 4.2;
      var az = (g.hz - p.z) * 10 - g.vz * 4.2;

      var lightTarget = 0.0;
      if (pointer != null) {
        final sp = cam.project(p.x, p.y, p.z);
        final k = cam.depthScale(p.z);
        final radius = lightRadius * k;
        final dx = sp.dx - pointer.dx, dy = sp.dy - pointer.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < radius) {
          final f = 1 - dist / radius;
          lightTarget = math.sqrt(f);
          final s = f * f;
          final ux = dist < 0.001 ? 0.0 : dx / dist;
          final uy = dist < 0.001 ? -1.0 : dy / dist;
          // Minimal parting: a soft nudge, no scatter.
          ax += ux * s * 9 / k;
          ay -= uy * s * 9 / k;
          ax += _pointerVelocity.dx / unit * s * 0.6;
          ay -= _pointerVelocity.dy / unit * s * 0.6;
          // Lit stones turn to catch the light — that is what sparkles.
          g.wx += uy * s * 9 * dt;
          g.wy += ux * s * 9 * dt;
        }
      }
      if (lightTarget > g.lit) {
        g.lit += (lightTarget - g.lit) * math.min(1.0, dt * 14);
      } else {
        g.lit = math.max(lightTarget, g.lit - dt * 1.1);
      }

      g.vx += ax * dt;
      g.vy += ay * dt;
      g.vz += az * dt;
      p.x += g.vx * dt;
      p.y += g.vy * dt;
      p.z += g.vz * dt;

      final spinEase = 1 - math.exp(-1.1 * dt);
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

    // Sparks: emitted around the fingertip while touching.
    if (pointer != null) {
      _sparkBudget += dt * (18 + _pointerVelocity.distance * 0.03);
      while (_sparkBudget >= 1) {
        _sparkBudget -= 1;
        _spawnSpark(pointer, 70);
      }
    }
    for (final s in _sparks) {
      s
        ..age += dt
        ..x += s.vx * dt
        ..y += s.vy * dt;
    }
    _sparks.removeWhere((s) => s.age >= s.life);

    _pointerVelocity *= math.exp(-8 * dt);
    notifyListeners();
  }

  void _spawnSpark(Offset around, double radius) {
    if (_sparks.length > 120) return;
    final a = _rng.nextDouble() * math.pi * 2;
    final r = math.sqrt(_rng.nextDouble()) * radius;
    _sparks.add(
      _Spark(
        around.dx + math.cos(a) * r,
        around.dy + math.sin(a) * r,
        math.cos(a) * 14,
        math.sin(a) * 14 - 6,
        0.5 + _rng.nextDouble() * 0.6,
        2.5 + _rng.nextDouble() * 4.5,
        _rng.nextDouble(),
      ),
    );
  }

  void pointerDown(Offset at, Duration stamp) {
    _pointer = at;
    _downAt = at;
    _downTime = stamp;
    _glowAt = at;
    _pointerVelocity = Offset.zero;
    for (var i = 0; i < 8; i++) {
      _spawnSpark(at, 40);
    }
  }

  void pointerMove(Offset at, Offset delta, Duration stamp) {
    _pointer = at;
    // Smoothed px/s from event deltas.
    _pointerVelocity = _pointerVelocity * 0.6 + delta * (60 * 0.4);
  }

  void pointerUp(Duration stamp) {
    final tap =
        _pointer != null &&
        (_pointer! - _downAt).distance < 12 &&
        stamp - _downTime < const Duration(milliseconds: 300);
    if (tap) _tapFlare(_downAt);
    _pointer = null;
  }

  void pointerCancel() => _pointer = null;

  /// A tap lights a ring of stones and flares the nearest one.
  void _tapFlare(Offset at) {
    final cam = camera;
    _FieldGem? nearest;
    var nearestD = double.infinity;
    for (final g in _gems) {
      final p = g.pose;
      final sp = cam.project(p.x, p.y, p.z);
      final d = (sp - at).distance;
      final radius = lightRadius * 1.3 * cam.depthScale(p.z);
      if (d < radius) {
        g.lit = math.max(g.lit, 1 - d / radius);
        g.wy += 4 * (1 - d / radius) * (g.spinY >= 0 ? 1 : -1);
      }
      if (d < nearestD) {
        nearestD = d;
        nearest = g;
      }
    }
    if (nearest != null && nearestD < 70) {
      nearest
        ..flash = 1
        ..wy += 10;
    }
    for (var i = 0; i < 22; i++) {
      _spawnSpark(at, 90);
    }
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
      // Far stones sink into the dark unless the touch lights them.
      final fog01 = ((-g.pose.z - 0.6) / 4).clamp(0.0, 0.7) * (1 - g.lit * 0.6);
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
        phase: g.phase,
        glint: band != _Band.far || g.lit > 0.2,
        flat: band == _Band.far,
      );
    }
    batch.paint(canvas, glintSprite: GemGlintSprite.image);
  }

  void _paintLight(Canvas canvas) {
    if (_glow > 0) {
      const r = lightRadius * 1.25;
      canvas.drawCircle(
        _glowAt,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(_glowAt, r, [
            Color.fromRGBO(255, 236, 200, 0.16 * _glow),
            Color.fromRGBO(221, 191, 136, 0.06 * _glow),
            const Color(0x00000000),
          ], const [0, 0.45, 1]),
      );
    }
    if (_sparks.isEmpty) return;
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9
      ..blendMode = BlendMode.plus;
    final dot = Paint()..blendMode = BlendMode.plus;
    for (final s in _sparks) {
      final t = s.age / s.life;
      // Quick bloom, slow fade.
      final a = (t < 0.2 ? t / 0.2 : 1 - (t - 0.2) / 0.8).clamp(0.0, 1.0);
      final c = Offset(s.x, s.y);
      final color = Color.lerp(
        const Color(0xFFDDBF88),
        const Color(0xFFFFFFFF),
        s.tint,
      )!;
      final len = s.size * (1.2 + a * 1.4);
      line.color = color.withValues(alpha: a * 0.9);
      canvas
        ..drawLine(c.translate(-len, 0), c.translate(len, 0), line)
        ..drawLine(c.translate(0, -len), c.translate(0, len), line);
      dot.color = color.withValues(alpha: a);
      canvas.drawCircle(c, s.size * 0.22, dot);
    }
  }
}

/// Full-bleed field of 3D diamonds of every cut drifting diagonally that
/// light up and sparkle under touch. Pauses while scrolled off screen and
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
