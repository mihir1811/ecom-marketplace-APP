import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'live_stage_tokens.dart';

/// Hearts that rise from the heart button, sway and fade. Call
/// [LiveHeartsController.burst] for each tap or each push from others.
class LiveHeartsController extends ChangeNotifier {
  final _pending = <bool>[];

  /// Adds [count] hearts; [own] ones are larger and champagne-edged.
  void burst(int count, {bool own = false}) {
    for (var i = 0; i < count; i++) {
      _pending.add(own);
    }
    notifyListeners();
  }

  List<bool> _take() {
    final out = List<bool>.of(_pending);
    _pending.clear();
    return out;
  }
}

class LiveHeartsLayer extends StatefulWidget {
  const LiveHeartsLayer({required this.controller, super.key});

  final LiveHeartsController controller;

  @override
  State<LiveHeartsLayer> createState() => _LiveHeartsLayerState();
}

class _Heart {
  _Heart(this.born, this.own, this.seed);

  final double born;
  final bool own;
  final double seed;
}

/// All hearts are drawn by one painter on one layer: no widget per heart.
class _LiveHeartsLayerState extends State<LiveHeartsLayer>
    with SingleTickerProviderStateMixin {
  static const _life = 2.4;
  static const _max = 70;

  late final Ticker _ticker = createTicker(_onTick);
  final _hearts = <_Heart>[];
  final _rng = math.Random();
  final _clock = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_spawn);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_spawn);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _spawn() {
    final fresh = widget.controller._take();
    if (MediaQuery.disableAnimationsOf(context)) return;
    for (var i = 0; i < fresh.length; i++) {
      // Spread a burst so hearts don't stack.
      _hearts.add(_Heart(_clock.value + i * 0.09, fresh[i], _rng.nextDouble()));
    }
    if (_hearts.length > _max) _hearts.removeRange(0, _hearts.length - _max);
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // The clock restarts with the ticker, so it is display-rate independent.
    _clock.value = elapsed.inMicroseconds / 1e6;
    final now = _clock.value;
    _hearts.removeWhere((h) => now - h.born > _life);
    if (_hearts.isEmpty) {
      _ticker.stop();
      _clock.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HeartsPainter(_hearts, _clock, _life),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter(this.hearts, this.clock, this.life) : super(repaint: clock);

  final List<_Heart> hearts;
  final ValueNotifier<double> clock;
  final double life;

  static const _palette = [
    Color(0xFFFF4D6D),
    Color(0xFFFF8FA3),
    Color(0xFFFFC2CF),
    LiveStage.champagne,
    Color(0xFFFF6B81),
  ];

  static Path _heart(double s) {
    final p = Path()
      ..moveTo(0, s * 0.35)
      ..cubicTo(-s * 0.05, s * 0.28, -s * 0.5, s * 0.02, -s * 0.5, -s * 0.2)
      ..cubicTo(-s * 0.5, -s * 0.42, -s * 0.28, -s * 0.52, -s * 0.12, -s * 0.46)
      ..cubicTo(-s * 0.05, -s * 0.43, 0, -s * 0.36, 0, -s * 0.3)
      ..cubicTo(0, -s * 0.36, s * 0.05, -s * 0.43, s * 0.12, -s * 0.46)
      ..cubicTo(s * 0.28, -s * 0.52, s * 0.5, -s * 0.42, s * 0.5, -s * 0.2)
      ..cubicTo(s * 0.5, s * 0.02, s * 0.05, s * 0.28, 0, s * 0.35)
      ..close();
    return p;
  }

  static final _base = _heart(26);

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    for (final h in hearts) {
      final age = now - h.born;
      if (age < 0) continue;
      final t = (age / life).clamp(0.0, 1.0);
      final rise = Curves.easeOutCubic.transform(t) * (size.height - 20);
      final sway = math.sin(t * math.pi * 2 + h.seed * 6) * 14 * (0.3 + t);
      final pop = t < 0.12 ? Curves.easeOutBack.transform(t / 0.12) : 1.0;
      final scale = (h.own ? 1.0 : 0.72) * pop * (1 - t * 0.15);
      final opacity = t > 0.65 ? (1 - (t - 0.65) / 0.35) : 1.0;
      final color =
          _palette[(h.seed * _palette.length).floor() % _palette.length];
      canvas
        ..save()
        ..translate(size.width / 2 + sway, size.height - 16 - rise)
        ..rotate(math.sin(t * math.pi * 1.5 + h.seed * 4) * 0.25)
        ..scale(scale);
      canvas.drawPath(
        _base,
        Paint()..color = color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
      if (h.own) {
        canvas.drawPath(
          _base,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white.withValues(
              alpha: 0.7 * opacity.clamp(0.0, 1.0),
            ),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_HeartsPainter old) => false;
}
