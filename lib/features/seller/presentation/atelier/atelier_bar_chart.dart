import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'atelier_theme.dart';

/// Animated bar chart with drag-to-scrub tooltips and an average guide.
///
/// Bars grow in with a slight stagger whenever the series changes; touching
/// or dragging across the plot focuses the nearest bar.
class AtelierBarChart extends StatefulWidget {
  const AtelierBarChart({
    required this.values,
    required this.labels,
    required this.detailAt,
    required this.formatValue,
    this.height = 230,
    this.accent,
    super.key,
  });

  final List<double> values;
  final List<String> labels;

  /// Full period name for the tooltip of bar `i`.
  final String Function(int i) detailAt;
  final String Function(double v) formatValue;
  final double height;
  final Color? accent;

  @override
  State<AtelierBarChart> createState() => _AtelierBarChartState();
}

class _AtelierBarChartState extends State<AtelierBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  int? _focus;

  static const _axisWidth = 46.0;
  static const _labelHeight = 26.0;

  @override
  void initState() {
    super.initState();
    _grow.forward();
  }

  @override
  void didUpdateWidget(covariant AtelierBarChart old) {
    super.didUpdateWidget(old);
    if (!_sameSeries(old.values, widget.values) ||
        old.accent != widget.accent) {
      _focus = null;
      _grow.forward(from: 0);
    }
  }

  static bool _sameSeries(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  static double niceMax(List<double> values) {
    if (values.isEmpty) return 1;
    final raw = values.reduce(math.max);
    if (raw <= 0) return 1;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 2.5
        ? 2.5
        : normalized <= 5
        ? 5
        : 10;
    return nice * magnitude;
  }

  void _focusAt(double dx, double plotWidth, int count) {
    if (count == 0 || plotWidth <= 0) return;
    final i = (dx / plotWidth * count).floor().clamp(0, count - 1);
    if (i != _focus) {
      AppHaptics.selection();
      setState(() => _focus = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accent = widget.accent ?? p.gold;
    final values = widget.values.isEmpty ? const <double>[0] : widget.values;
    final labels = widget.labels.isEmpty ? const ['—'] : widget.labels;
    final maxY = niceMax(values);
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    final labelStep = (labels.length / 7).ceil().clamp(1, labels.length);
    final plotHeight = widget.height - _labelHeight;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final plotWidth = constraints.maxWidth - _axisWidth;
          final barSlot = plotWidth / values.length;
          final focus = _focus;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final dx = d.localPosition.dx - _axisWidth;
              if (dx < 0) return;
              final i = (dx / plotWidth * values.length).floor().clamp(
                0,
                values.length - 1,
              );
              setState(() => _focus = _focus == i ? null : i);
              AppHaptics.selection();
            },
            onHorizontalDragUpdate: (d) => _focusAt(
              d.localPosition.dx - _axisWidth,
              plotWidth,
              values.length,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _grow,
                    builder: (context, _) => CustomPaint(
                      painter: _BarsPainter(
                        values: values,
                        maxY: maxY,
                        avg: avg,
                        progress: _grow.value,
                        focus: focus,
                        accent: accent,
                        grid: p.hairline,
                        axisText: AtelierType.figure(p.muted, size: 10.5),
                        formatValue: widget.formatValue,
                        axisWidth: _axisWidth,
                        plotHeight: plotHeight,
                        track: p.sunken,
                      ),
                    ),
                  ),
                ),
                // X labels
                Positioned(
                  left: _axisWidth,
                  right: 0,
                  bottom: 0,
                  height: _labelHeight - 6,
                  child: Row(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AtelierType.caption(
                              focus == i ? p.ink : p.muted,
                              size: 10.5,
                            ),
                            child: Text(
                              i % labelStep == 0 || i == labels.length - 1
                                  ? labels[i]
                                  : '',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (focus != null && focus < values.length)
                  _Tooltip(
                    key: ValueKey(focus),
                    left: _axisWidth + barSlot * focus + barSlot / 2,
                    top: plotHeight * (1 - values[focus] / maxY),
                    maxWidth: constraints.maxWidth,
                    title: widget.labels.isEmpty
                        ? labels[focus]
                        : widget.detailAt(focus),
                    value: widget.formatValue(values[focus]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.maxY,
    required this.avg,
    required this.progress,
    required this.focus,
    required this.accent,
    required this.grid,
    required this.axisText,
    required this.formatValue,
    required this.axisWidth,
    required this.plotHeight,
    required this.track,
  });

  final List<double> values;
  final double maxY;
  final double avg;
  final double progress;
  final int? focus;
  final Color accent;
  final Color grid;
  final Color track;
  final TextStyle axisText;
  final String Function(double) formatValue;
  final double axisWidth;
  final double plotHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - axisWidth;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    // Grid + y labels.
    for (var k = 0; k <= 3; k++) {
      final v = maxY * k / 3;
      final y = plotHeight * (1 - k / 3);
      _dashed(canvas, Offset(axisWidth, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _compact(v), style: axisText),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: axisWidth - 8);
      tp.paint(canvas, Offset(axisWidth - 8 - tp.width, y - tp.height / 2));
    }

    final n = values.length;
    final slot = plotWidth / n;
    final barWidth = math.min(28.0, slot * 0.56);
    for (var i = 0; i < n; i++) {
      // Stagger: each bar starts a little after the previous one.
      final start = (i / math.max(n, 1)) * 0.45;
      final local = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(local);
      final h = maxY <= 0 ? 0.0 : plotHeight * (values[i] / maxY) * eased;
      final cx = axisWidth + slot * i + slot / 2;
      final dim = focus != null && focus != i;

      // Track.
      final trackRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barWidth / 2, 0, barWidth, plotHeight),
        topLeft: Radius.circular(barWidth / 2),
        topRight: Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(
        trackRect,
        Paint()..color = track.withValues(alpha: focus == i ? 0.9 : 0.45),
      );
      if (h <= 0.5) continue;

      final rect = Rect.fromLTWH(
        cx - barWidth / 2,
        plotHeight - h,
        barWidth,
        h,
      );
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(barWidth / 2),
        topRight: Radius.circular(barWidth / 2),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: dim ? 0.35 : 1),
            accent.withValues(alpha: dim ? 0.12 : 0.45),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, paint);
      if (focus == i) {
        canvas.drawCircle(
          Offset(cx, plotHeight - h),
          barWidth / 2 + 3,
          Paint()
            ..color = accent.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // Average guide.
    if (avg > 0 && maxY > 0) {
      final y = plotHeight * (1 - (avg / maxY) * progress.clamp(0.0, 1.0));
      final avgPaint = Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      _dashed(
        canvas,
        Offset(axisWidth, y),
        Offset(size.width, y),
        avgPaint,
        dash: 3,
        gap: 4,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'avg',
          style: axisText.copyWith(color: accent, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height - 2));
    }
  }

  String _compact(double v) {
    if (v == 0) return '0';
    final formatted = formatValue(v);
    if (v >= 1e6) {
      return formatted.replaceFirst(
        RegExp(r'[\d,]+(\.\d+)?'),
        '${(v / 1e6).toStringAsFixed(v % 1e6 == 0 ? 0 : 1)}M',
      );
    }
    if (v >= 1e4) {
      return formatted.replaceFirst(
        RegExp(r'[\d,]+(\.\d+)?'),
        '${(v / 1e3).toStringAsFixed(0)}k',
      );
    }
    return formatted.replaceFirst(RegExp(r'\.0+$'), '');
  }

  void _dashed(
    Canvas canvas,
    Offset a,
    Offset b,
    Paint paint, {
    double dash = 2,
    double gap = 5,
  }) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final e = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * e, paint);
      d = e + gap;
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress ||
      old.focus != focus ||
      old.values != values ||
      old.accent != accent ||
      old.grid != grid;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.left,
    required this.top,
    required this.maxWidth,
    required this.title,
    required this.value,
    super.key,
  });

  final double left;
  final double top;
  final double maxWidth;
  final String title;
  final String value;

  static const _width = 168.0;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final x = (left - _width / 2)
        .clamp(0.0, math.max(0.0, maxWidth - _width))
        .toDouble();
    return Positioned(
      left: x,
      top: math.max(-12.0, top - 64),
      width: _width,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 6 * (1 - t)),
              child: child,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: p.isDark ? p.raised : p.onyx,
              borderRadius: BorderRadius.circular(AtelierRadius.sm),
              border: Border.all(
                color: p.isDark ? p.hairline : Colors.transparent,
              ),
              boxShadow: p.floatShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(
                    p.isDark ? p.muted : p.onOnyx.withValues(alpha: 0.6),
                    size: 10.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.figure(
                    p.isDark ? p.ink : p.onOnyx,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
