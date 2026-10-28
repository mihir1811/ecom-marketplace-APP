import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/live_format.dart';
import 'live_stage_tokens.dart';

/// Lot clock on the server's time, rebuilt only when the shown second
/// changes. Turns ruby and beats on each second under 10 s; reads
/// "Closing" at 0 until the result push lands.
class LiveCountdown extends StatefulWidget {
  const LiveCountdown({
    required this.endsAt,
    required this.serverNow,
    super.key,
    this.large = false,
  });

  final DateTime? endsAt;
  final DateTime Function() serverNow;
  final bool large;

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  Duration get _left {
    final ends = widget.endsAt;
    return ends == null ? Duration.zero : ends.difference(widget.serverNow());
  }

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant LiveCountdown old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _beat.dispose();
    super.dispose();
  }

  /// Wakes just past the next whole second, when the label changes.
  void _schedule() {
    _tick?.cancel();
    _tick = null;
    if (widget.endsAt == null) return;
    final left = _left;
    if (left <= Duration.zero) return;
    final ms = left.inMilliseconds % 1000;
    _tick = Timer(Duration(milliseconds: (ms == 0 ? 1000 : ms) + 5), () {
      if (!mounted) return;
      final now = _left;
      if (now > Duration.zero &&
          now < const Duration(seconds: 10) &&
          !MediaQuery.disableAnimationsOf(context)) {
        unawaited(_beat.forward(from: 0));
      }
      setState(() {});
      _schedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ends = widget.endsAt;
    final left = _left;
    final closing = ends != null && left <= Duration.zero;
    final urgent = !closing && left < const Duration(seconds: 10);
    final label = ends == null
        ? '--:--'
        : closing
        ? 'Closing'
        : liveClock(left + const Duration(milliseconds: 999));
    final hot = urgent || closing;
    final color = hot ? LiveStage.urgent : LiveStage.ink;

    return Semantics(
      liveRegion: urgent,
      label: closing ? 'Closing' : 'Time left $label',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _beat,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.08 * (1 - Curves.easeOut.transform(_beat.value)),
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 12 : 9,
            vertical: widget.large ? 7 : 5,
          ),
          decoration: BoxDecoration(
            color: hot
                ? LiveStage.urgent.withValues(alpha: 0.16)
                : LiveStage.ink.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hot
                  ? LiveStage.urgent.withValues(alpha: 0.6)
                  : LiveStage.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                closing ? Icons.gavel_rounded : Icons.schedule_rounded,
                size: widget.large ? 15 : 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: LiveType.figure(
                  widget.large ? 15 : 12.5,
                  color: color,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] (the lot image) in a hairline ring that drains as the
/// lot's time runs out: champagne, then ruby in the last 10 s. Painted on
/// its own layer, stepped about half a pixel at a time rather than every
/// display frame.
class LiveCountdownRing extends StatefulWidget {
  const LiveCountdownRing({
    required this.child,
    required this.endsAt,
    required this.serverNow,
    super.key,
    this.startedAt,
    this.durationSeconds = 0,
    this.size = 56,
    this.stroke = 2.4,
  });

  final Widget child;
  final DateTime? endsAt;
  final DateTime? startedAt;
  final int durationSeconds;
  final DateTime Function() serverNow;
  final double size;
  final double stroke;

  @override
  State<LiveCountdownRing> createState() => _LiveCountdownRingState();
}

class _LiveCountdownRingState extends State<LiveCountdownRing> {
  final _progress = ValueNotifier<double>(1);
  Timer? _tick;
  var _enabled = true;

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Same rule as a Ticker: a covered route stops drawing its clock.
    _enabled = TickerMode.valuesOf(context).enabled;
    _restart();
  }

  @override
  void didUpdateWidget(covariant LiveCountdownRing old) {
    super.didUpdateWidget(old);
    if (old.endsAt != widget.endsAt ||
        old.startedAt != widget.startedAt ||
        old.durationSeconds != widget.durationSeconds ||
        old.size != widget.size) {
      _restart();
    }
  }

  Duration get _total {
    final ends = widget.endsAt;
    return widget.durationSeconds > 0
        ? Duration(seconds: widget.durationSeconds)
        : widget.startedAt == null || ends == null
        ? const Duration(seconds: 60)
        : ends.difference(widget.startedAt!);
  }

  void _restart() {
    _tick?.cancel();
    _tick = null;
    _update();
    if (!_enabled || widget.endsAt == null || _progress.value <= 0) return;
    // The ring runs a little under 4 sides long; one step is ~0.5 px.
    final step = _total.inMilliseconds * 0.5 / (widget.size * 3.6);
    _tick = Timer.periodic(
      Duration(milliseconds: step.clamp(16, 500).round()),
      (_) {
        _update();
        if (_progress.value <= 0) {
          _tick?.cancel();
          _tick = null;
        }
      },
    );
  }

  void _update() {
    final ends = widget.endsAt;
    if (ends == null) {
      _progress.value = 1;
      return;
    }
    final left = ends.difference(widget.serverNow());
    final ms = _total.inMilliseconds;
    _progress.value = ms <= 0
        ? 0
        : (left.inMilliseconds / ms).clamp(0.0, 1.0).toDouble();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = widget.size - (widget.stroke + 3) * 2;
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _RingPainter(
                  progress: _progress,
                  stroke: widget.stroke,
                  endsAt: widget.endsAt,
                  serverNow: widget.serverNow,
                ),
              ),
            ),
          ),
          SizedBox.square(dimension: inner, child: widget.child),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.endsAt,
    required this.serverNow,
  }) : super(repaint: progress);

  final ValueNotifier<double> progress;
  final double stroke;
  final DateTime? endsAt;
  final DateTime Function() serverNow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(
      rect.deflate(stroke / 2),
      Radius.circular(size.width * 0.32),
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = LiveStage.hairlineStrong;
    canvas.drawRRect(r, track);

    final p = progress.value;
    if (p <= 0) return;
    final ends = endsAt;
    final urgent =
        ends != null &&
        ends.difference(serverNow()) < const Duration(seconds: 10);
    final path = Path()..addRRect(r);
    final metric = path.computeMetrics().first;
    // Start at top-centre, run clockwise.
    final len = metric.length;
    final start = len * 0.125 + size.width * 0.18;
    final arc = len * p;
    final drawn = Path();
    final from = start % len;
    final to = from + arc;
    if (to <= len) {
      drawn.addPath(metric.extractPath(from, to), Offset.zero);
    } else {
      drawn
        ..addPath(metric.extractPath(from, len), Offset.zero)
        ..addPath(metric.extractPath(0, to - len), Offset.zero);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader =
          (urgent
                  ? const LinearGradient(
                      colors: [LiveStage.urgent, LiveStage.live],
                    )
                  : LiveStage.champagneGradient)
              .createShader(rect);
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.endsAt != endsAt || old.stroke != stroke;
}
