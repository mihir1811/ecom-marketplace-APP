import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'hero_diamond_bytes.dart';

/// Dark hero field: floating diamonds with soft proximity highlight and
/// magnetic finger repulsion. Claims pan gestures so the home scroll stays
/// locked while the finger is on this component.
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
  /// Radius where repulsion + diamond highlight apply.
  static const _influence = 150.0;
  static const _count = 138; // 46 × 3

  late final AnimationController _clock;
  ui.Image? _image;
  List<_Stone> _stones = const [];
  Size _size = Size.zero;
  final Stopwatch _watch = Stopwatch();
  Duration _last = Duration.zero;
  double _time = 0;

  Offset? _pointer;
  Offset _pointerVel = Offset.zero;
  bool _touching = false;
  bool _hovering = false;

  bool get _active => _touching || _hovering;

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
    final codec =
        await ui.instantiateImageCodec(base64Decode(heroDiamondBase64));
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
    _stones = List.generate(_count, (i) {
      final depth = 0.42 + rng.nextDouble() * 0.58;
      final stone = _Stone(
        home: Offset(
          (rng.nextDouble() * 1.12 - 0.06) * size.width,
          (rng.nextDouble() * 1.08 - 0.04) * size.height,
        ),
        size: (28 + rng.nextDouble() * 48) * depth,
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

    for (final stone in _stones) {
      final phase = stone.home.dx + stone.home.dy;
      final sway = Offset(
        math.sin(_time * 0.22 + phase) * (3 + stone.depth * 4),
        math.cos(_time * 0.18 + phase) * (3.5 + stone.depth * 5),
      );
      stone.spin += math.sin(_time * 0.2 + phase) * 0.0004;
      final home = stone.home + sway;

      if (_active && _pointer != null) {
        final delta = stone.pos - _pointer!;
        final dist = delta.distance;
        if (dist < _influence) {
          final safe = math.max(dist, 28.0);
          final dir = delta / safe;
          final falloff = (1 - dist / _influence).clamp(0.0, 1.0);
          // Gentle opposite-magnet push, not a snap.
          stone.vel += dir * (1.6 + 2.4 * falloff * stone.depth);
          stone.spin +=
              (_pointerVel.dx * dir.dy - _pointerVel.dy * dir.dx) * 0.00008;
        }
      }

      final toHome = home - stone.pos;
      final nearPointer = _active &&
          _pointer != null &&
          (stone.pos - _pointer!).distance < _influence;
      stone.vel += toHome * (nearPointer ? 0.012 : 0.028);
      stone.vel *= math.pow(nearPointer ? 0.9 : 0.86, dt * 60).toDouble();
      stone.spin *= math.pow(0.9, dt * 60).toDouble();
      stone.pos += stone.vel * (dt * 60) * 0.45;
      stone.rotation += stone.spin * (dt * 60) * 0.45;
    }
    setState(() {});
  }

  void _point(Offset local, {bool touching = true, bool hovering = false}) {
    final previous = _pointer;
    _pointer = local;
    if (touching) _touching = true;
    if (hovering) _hovering = true;
    if (previous != null) {
      _pointerVel = local - previous;
    }
  }

  void _clear() {
    _touching = false;
    _hovering = false;
    _pointer = null;
    _pointerVel = Offset.zero;
    setState(() {});
  }

  @override
  void dispose() {
    _clock.dispose();
    _image?.dispose();
    super.dispose();
  }

  Map<Type, GestureRecognizerFactory> _panGestures() {
    return <Type, GestureRecognizerFactory>{
      _ClaimPanRecognizer:
          GestureRecognizerFactoryWithHandlers<_ClaimPanRecognizer>(
        () => _ClaimPanRecognizer(),
        (instance) {
          instance.onStart = (d) {
            _point(d.localPosition);
          };
          instance.onUpdate = (d) {
            _point(d.localPosition);
          };
          instance.onEnd = (_) => _clear();
          instance.onCancel = _clear;
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _layout(size);
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: _panGestures(),
          child: MouseRegion(
            onHover: (e) {
              if (_touching) return;
              _point(e.localPosition, touching: false, hovering: true);
            },
            onExit: (_) {
              _hovering = false;
              if (!_touching) _clear();
            },
            child: CustomPaint(
              size: size,
              painter: _DiamondFieldPainter(
                image: _image,
                stones: _stones,
                pointer: _pointer,
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
    required this.influence,
  });

  final ui.Image? image;
  final List<_Stone> stones;
  final Offset? pointer;
  final double influence;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000000),
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
      const resting = 0.16;
      var alpha = resting;
      if (pointer != null) {
        final dist = (stone.pos - pointer!).distance;
        if (dist < influence) {
          final t = (1 - dist / influence).clamp(0.0, 1.0);
          alpha = resting + (1 - resting) * t;
        }
      }

      canvas.save();
      canvas.translate(stone.pos.dx, stone.pos.dy);
      canvas.rotate(stone.rotation);
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: stone.size * 0.52,
        height: stone.size * 0.72,
      );
      canvas.drawImageRect(
        sprite,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: alpha),
            BlendMode.modulate,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondFieldPainter oldDelegate) => true;
}

/// Wins the gesture arena on pointer-down so a parent scroll view cannot
/// scroll while the finger is on the diamond hero.
class _ClaimPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
