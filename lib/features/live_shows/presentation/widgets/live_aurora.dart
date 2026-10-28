import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'live_ambient.dart';
import 'live_stage_tokens.dart';

/// GPU-shaded noir backdrop (`shaders/live_aurora.frag`): a slow champagne
/// aurora on velvet black, stepped by the ambient clock rather than every
/// frame. Falls back to a still gradient while the shader loads or where
/// fragment programs are missing; holds still with reduced motion.
class LiveAurora extends StatefulWidget {
  const LiveAurora({super.key, this.energy = 0});

  /// 0..1; brightens the aurora a touch.
  final double energy;

  @override
  State<LiveAurora> createState() => _LiveAuroraState();
}

class _LiveAuroraState extends State<LiveAurora> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

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
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiveAmbient(
      builder: (context, time) => RepaintBoundary(
        child: CustomPaint(
          painter: _AuroraPainter(_shader, time, widget.energy),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.shader, this.clock, this.energy) : super(repaint: clock);

  final ui.FragmentShader? shader;
  final ValueListenable<double> clock;
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
