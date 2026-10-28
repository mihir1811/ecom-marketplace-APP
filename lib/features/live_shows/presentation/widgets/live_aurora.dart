import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'live_stage_tokens.dart';

/// GPU-shaded noir backdrop (`shaders/live_aurora.frag`): a slow champagne
/// aurora on velvet black. Falls back to a still gradient while the shader
/// loads, where fragment programs are missing, or with reduced motion.
class LiveAurora extends StatefulWidget {
  const LiveAurora({super.key, this.energy = 0});

  /// 0..1; brightens the aurora a touch.
  final double energy;

  @override
  State<LiveAurora> createState() => _LiveAuroraState();
}

class _LiveAuroraState extends State<LiveAurora>
    with SingleTickerProviderStateMixin {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (e) => _clock.value = e.inMicroseconds / 1e6,
  );

  @override
  void initState() {
    super.initState();
    _program ??= ui.FragmentProgram.fromAsset('shaders/live_aurora.frag');
    _program!
        .then((program) {
          if (mounted) setState(() => _shader = program.fragmentShader());
        })
        .catchError((Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(_shader, _clock, widget.energy),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.shader, this.clock, this.energy) : super(repaint: clock);

  final ui.FragmentShader? shader;
  final ValueNotifier<double> clock;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final s = shader;
    if (s == null) {
      canvas
        ..drawRect(rect, Paint()..color = LiveStage.void_)
        ..drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(0.3, -0.7),
              radius: 1.1,
              colors: [
                LiveStage.champagne.withValues(alpha: 0.10),
                Colors.transparent,
              ],
            ).createShader(rect),
        );
      return;
    }
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value)
      ..setFloat(3, energy);
    canvas.drawRect(rect, Paint()..shader = s);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.shader != shader || old.energy != energy;
}
