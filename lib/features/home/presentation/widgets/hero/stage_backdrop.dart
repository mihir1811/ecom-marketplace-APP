import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/home_tokens.dart';

/// GPU-shaded hero backdrop (`shaders/home_cosmos.frag`).
///
/// Falls back to a static gradient while the shader loads or on platforms
/// where fragment programs are unavailable.
class StageBackdrop extends StatefulWidget {
  const StageBackdrop({
    required this.clock,
    required this.progress,
    super.key,
    this.focusY = 0.36,
  });

  /// Seconds since the hero started animating.
  final ValueListenable<double> clock;

  /// 0..1 hero scroll-away progress.
  final ValueListenable<double> progress;

  /// Vertical centre (0..1) of the warm key light.
  final double focusY;

  @override
  State<StageBackdrop> createState() => _StageBackdropState();
}

class _StageBackdropState extends State<StageBackdrop> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _program ??= ui.FragmentProgram.fromAsset('shaders/home_cosmos.frag');
    _program!
        .then((program) {
          if (mounted) setState(() => _shader = program.fragmentShader());
        })
        .catchError((Object _) {
          // Keep the gradient fallback; the stage still reads as intended.
        });
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _StagePainter(
          shader: _shader,
          clock: widget.clock,
          progress: widget.progress,
          focusY: widget.focusY,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  _StagePainter({
    required this.shader,
    required this.clock,
    required this.progress,
    required this.focusY,
  }) : super(repaint: Listenable.merge([clock, progress]));

  final ui.FragmentShader? shader;
  final ValueListenable<double> clock;
  final ValueListenable<double> progress;
  final double focusY;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final s = shader;
    if (s == null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(0, focusY * 2 - 1),
            radius: 0.9,
            colors: const [Color(0xFF101A26), HomeStage.obsidian],
          ).createShader(rect),
      );
      return;
    }
    s
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value)
      ..setFloat(3, focusY)
      ..setFloat(4, progress.value.clamp(0.0, 1.0));
    canvas.drawRect(rect, Paint()..shader = s);
  }

  @override
  bool shouldRepaint(_StagePainter oldDelegate) =>
      oldDelegate.shader != shader || oldDelegate.focusY != focusY;
}
