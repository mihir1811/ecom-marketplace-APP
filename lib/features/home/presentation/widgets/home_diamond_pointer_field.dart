import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hero_diamond_bytes.dart';

/// Dark hero field modeled on the Oryzo footer: scattered objects, a soft
/// spotlight on the pointer, and a push/spin while the finger stays down.
class HomeDiamondPointerField extends StatefulWidget {
  const HomeDiamondPointerField({super.key});

  @override
  State<HomeDiamondPointerField> createState() =>
      _HomeDiamondPointerFieldState();
}

class _Stone {
  _Stone({
    required this.home,
    required this.size,
    required this.rotation,
    required this.depth,
  });

  final Offset home;
  Offset pos = Offset.zero;
  Offset vel = Offset.zero;
  double rotation;
  double spin = 0;
  final double size;
  final double depth;
}

class _HomeDiamondPointerFieldState extends State<HomeDiamondPointerField>
    with SingleTickerProviderStateMixin {
  static const _influence = 220.0;

  late final AnimationController _clock;
  ui.Image? _image;
  List<_Stone> _stones = const [];
  Size _size = Size.zero;
  final Stopwatch _watch = Stopwatch();
  Duration _last = Duration.zero;
  double _time = 0;

  Offset? _pointer;
  Offset _pointerVel = Offset.zero;
  bool _active = false;
  double _glow = 0;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onFrame);
    _watch.start();
    _clock.repeat();
    _load();
  }

  Future<void> _load() async {
    final codec = await ui.instantiateImageCodec(
      base64Decode(heroDiamondBase64),
    );
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _image = frame.image);
  }

  void _layout(Size size) {
    if (_stones.isNotEmpty && _size == size) return;
    _size = size;
    final rng = math.Random(7);
    _stones = List.generate(46, (i) {
      final depth = 0.42 + rng.nextDouble() * 0.58;
      final stone = _Stone(
        home: Offset(
          (rng.nextDouble() * 1.12 - 0.06) * size.width,
          (rng.nextDouble() * 1.08 - 0.04) * size.height,
        ),
        size: (36 + rng.nextDouble() * 62) * depth,
        rotation: rng.nextDouble() * math.pi * 2,
        depth: depth,
      );
      stone.pos = stone.home;
      return stone;
    });
  }

  void _onFrame() {
    final elapsed = _watch.elapsed;
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.033);
    _last = elapsed;
    _time += dt;
    if (_stones.isEmpty || !mounted) return;

    final glowTarget = _active && _pointer != null ? 1.0 : 0.0;
    _glow += (glowTarget - _glow) * (1 - math.exp(-dt * 12));
    if (!_active && _glow < 0.01) {
      _pointer = null;
      _glow = 0;
    }

    for (final stone in _stones) {
      final phase = stone.home.dx + stone.home.dy;
      final sway = Offset(
        math.sin(_time * 0.55 + phase) * (14 + stone.depth * 22),
        math.cos(_time * 0.42 + phase) * (18 + stone.depth * 28),
      );
      stone.spin += math.sin(_time * 0.35 + phase) * 0.004;
      final home = stone.home + sway;

      if (_active && _pointer != null) {
        final delta = stone.pos - _pointer!;
        final dist = delta.distance;
        if (dist < _influence) {
          final safe = math.max(dist, 12.0);
          final t = 1 - dist / _influence;
          final falloff = t * t;
          // Strong radial push so nearby stones visibly scatter away.
          final force = (55 + 90 * stone.depth) * falloff;
          final dir = delta / safe;
          stone.vel += dir * force * dt * 60;
          final tangent =
              Offset(-dir.dy, dir.dx) * (_pointerVel.distance.clamp(0, 40));
          stone.vel += tangent * 0.08 * falloff;
          stone.spin +=
              (_pointerVel.dx * dir.dy - _pointerVel.dy * dir.dx) *
              0.0008 *
              falloff;
        }
      }

      // Soft spring home — weaker while finger is near so push wins.
      final toHome = home - stone.pos;
      final nearPointer =
          _active &&
          _pointer != null &&
          (stone.pos - _pointer!).distance < _influence;
      stone.vel += toHome * (nearPointer ? 0.02 : 0.09);
      stone.vel *= math.pow(nearPointer ? 0.90 : 0.82, dt * 60).toDouble();
      stone.spin *= math.pow(0.88, dt * 60).toDouble();
      stone.pos += stone.vel * (dt * 60);
      stone.rotation += stone.spin * (dt * 60);
    }
    setState(() {});
  }

  void _point(Offset local) {
    final previous = _pointer;
    _pointer = local;
    _active = true;
    if (previous != null) {
      _pointerVel = local - previous;
    }
  }

  void _clear() {
    _active = false;
    _pointerVel = Offset.zero;
  }

  @override
  void dispose() {
    _clock.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _layout(size);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _point(e.localPosition),
          onPointerMove: (e) {
            if (!_active) return;
            _point(e.localPosition);
          },
          onPointerHover: (e) => _point(e.localPosition),
          onPointerUp: (_) => _clear(),
          onPointerCancel: (_) => _clear(),
          child: MouseRegion(
            onExit: (_) {
              if (!_active) _clear();
            },
            child: CustomPaint(
              size: size,
              painter: _DiamondFieldPainter(
                image: _image,
                stones: _stones,
                pointer: _pointer,
                glow: _glow,
                influence: _influence,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiamondFieldPainter extends CustomPainter {
  _DiamondFieldPainter({
    required this.image,
    required this.stones,
    required this.pointer,
    required this.glow,
    required this.influence,
  });

  final ui.Image? image;
  final List<_Stone> stones;
  final Offset? pointer;
  final double glow;
  final double influence;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050505),
    );
    final sprite = image;
    if (sprite == null) return;

    final ordered = [...stones]..sort((a, b) => a.depth.compareTo(b.depth));
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );

    for (final stone in ordered) {
      final lit = pointer == null || glow < 0.02
          ? 0.0
          : (1 - (stone.pos - pointer!).distance / influence).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(stone.pos.dx, stone.pos.dy);
      canvas.rotate(stone.rotation);
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: stone.size * 0.52,
        height: stone.size * 0.72,
      );
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: 0.42 + stone.depth * 0.58);
      if (lit > 0.04) {
        paint.colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: lit * glow),
          BlendMode.srcATop,
        );
      }
      canvas.drawImageRect(sprite, src, dst, paint);
      canvas.restore();
    }

    final center = pointer;
    if (center == null || glow < 0.02) return;

    // Soft bright halo around the finger (drawn under stones would be hidden;
    // drawn after so surroundings read as lit).
    canvas.drawCircle(
      center,
      influence,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          influence,
          [
            Color.fromRGBO(255, 252, 245, 0.55 * glow),
            Color.fromRGBO(255, 236, 200, 0.22 * glow),
            const Color.fromRGBO(255, 255, 255, 0),
          ],
          const [0.0, 0.35, 1.0],
        )
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      center,
      36,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.35 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondFieldPainter oldDelegate) => true;
}
