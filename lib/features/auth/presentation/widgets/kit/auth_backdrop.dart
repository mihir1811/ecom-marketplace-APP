import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'auth_tokens.dart';

/// GPU-shaded silk backdrop (`shaders/auth_silk.frag`) for auth screens.
///
/// Drifts slowly, leans toward the pointer for a little parallax, and falls
/// back to a static gradient while the shader loads or where fragment
/// programs are unavailable. Freezes when the OS asks for reduced motion.
class AuthBackdrop extends StatefulWidget {
  const AuthBackdrop({super.key, required this.pointer, this.focus});

  /// Normalised (0..1) pointer position, used for parallax.
  final ValueNotifier<Offset> pointer;

  /// Normalised (0..1) centre of the warm key light.
  final Offset? focus;

  @override
  State<AuthBackdrop> createState() => _AuthBackdropState();
}

class _AuthBackdropState extends State<AuthBackdrop>
    with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;

  late final Ticker _ticker = createTicker(_tick);
  final _clock = ValueNotifier<double>(0);
  final _lean = ValueNotifier<Offset>(const Offset(0.5, 0.5));
  ui.FragmentShader? _shader;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _program ??= ui.FragmentProgram.fromAsset('shaders/auth_silk.frag');
    _program!
        .then((program) {
          if (mounted) setState(() => _shader = program.fragmentShader());
        })
        .catchError((Object _) {
          // Gradient fallback keeps the mood intact.
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = AuthMotion.reduced(context);
    if (still && _ticker.isActive) {
      _ticker.stop();
    } else if (!still && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    _clock.value += dt;
    final target = widget.pointer.value;
    final current = _lean.value;
    _lean.value = Offset.lerp(current, target, (dt * 2.4).clamp(0.0, 1.0))!;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _lean.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AuthPalette.of(context);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SilkPainter(
          shader: _shader,
          clock: _clock,
          lean: _lean,
          palette: palette,
          focus: widget.focus ?? const Offset(0.5, 0.2),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SilkPainter extends CustomPainter {
  _SilkPainter({
    required this.shader,
    required this.clock,
    required this.lean,
    required this.palette,
    required this.focus,
  }) : super(repaint: Listenable.merge([clock, lean]));

  final ui.FragmentShader? shader;
  final ValueNotifier<double> clock;
  final ValueNotifier<Offset> lean;
  final AuthPalette palette;
  final Offset focus;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final s = shader;
    if (s == null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(focus.dx * 2 - 1, focus.dy * 2 - 1),
            radius: 1.1,
            colors: [
              Color.alphaBlend(palette.accentSoft, palette.bg),
              palette.bg,
            ],
          ).createShader(rect),
      );
      return;
    }
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value)
      ..setFloat(3, palette.isDark ? 1 : 0)
      ..setFloat(4, focus.dx)
      ..setFloat(5, focus.dy)
      ..setFloat(6, lean.value.dx)
      ..setFloat(7, lean.value.dy);
    canvas.drawRect(rect, Paint()..shader = s);
  }

  @override
  bool shouldRepaint(_SilkPainter old) =>
      old.shader != shader || old.palette != palette || old.focus != focus;
}
