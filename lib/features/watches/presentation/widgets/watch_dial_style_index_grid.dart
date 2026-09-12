import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/watch_filter_state.dart';

/// Dial Style / Indexes picker with drawn watch-face icons (Chrono24-style).
class WatchDialStyleIndexGrid extends StatelessWidget {
  const WatchDialStyleIndexGrid({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<String> selected;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 3;
          const gap = AppSpacing.s12;
          final cellW =
              (constraints.maxWidth - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.s12,
            children: [
              for (final opt in WatchFilterState.indexesOptions)
                SizedBox(
                  width: cellW,
                  child: _DialStyleCard(
                    label: opt,
                    selected: selected.contains(opt),
                    onTap: () => onToggle(opt),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DialStyleCard extends StatelessWidget {
  const _DialStyleCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _dialSize = 48;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? AppColors.selectedFill(context)
        : AppColors.border(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSpacing.r8),
              border: Border.all(color: border, width: selected ? 2 : 1),
            ),
            child: Center(
              child: SizedBox(
                width: _dialSize,
                height: _dialSize,
                child: CustomPaint(
                  painter: _DialFacePainter(
                    style: _DialIndexStyle.fromLabel(label),
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              height: 1.2,
              color: selected
                  ? AppColors.textPrimary(context)
                  : AppColors.textMuted(context),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DialIndexStyle {
  arabic,
  dots,
  baton,
  blank,
  roman;

  static _DialIndexStyle fromLabel(String label) {
    final key = label.toLowerCase();
    if (key.contains('arabic')) return _DialIndexStyle.arabic;
    if (key.contains('roman')) return _DialIndexStyle.roman;
    if (key.contains('baton') || key.contains('line')) {
      return _DialIndexStyle.baton;
    }
    if (key.contains('dot') || key.contains('gem')) {
      return _DialIndexStyle.dots;
    }
    return _DialIndexStyle.blank;
  }
}

class _DialFacePainter extends CustomPainter {
  const _DialFacePainter({required this.style, required this.color});

  final _DialIndexStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1.5;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke);

    _paintMarkers(canvas, center, radius);
    _paintHands(canvas, center, radius);
  }

  void _paintMarkers(Canvas canvas, Offset center, double radius) {
    // Cardinals: 12, 3, 6, 9 (angles from 12 o'clock, clockwise).
    const angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];

    switch (style) {
      case _DialIndexStyle.blank:
        return;
      case _DialIndexStyle.dots:
        final fill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        for (final angle in angles) {
          final p = _pointOnDial(center, radius * 0.78, angle);
          canvas.drawCircle(p, radius * 0.07, fill);
        }
      case _DialIndexStyle.baton:
        final stroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        for (final angle in angles) {
          final outer = _pointOnDial(center, radius * 0.86, angle);
          final inner = _pointOnDial(center, radius * 0.68, angle);
          canvas.drawLine(inner, outer, stroke);
        }
      case _DialIndexStyle.arabic:
        _paintTexts(
          canvas,
          center,
          radius,
          // Eastern Arabic–Indic numerals (١٢ ٣ ٦ ٩), not Latin digits.
          const ['١٢', '٣', '٦', '٩'],
          fontSizeFactor: 0.24,
        );
      case _DialIndexStyle.roman:
        _paintTexts(
          canvas,
          center,
          radius,
          const ['XII', 'III', 'VI', 'IX'],
          fontSizeFactor: 0.16,
        );
    }
  }

  void _paintTexts(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> labels, {
    required double fontSizeFactor,
  }) {
    const angles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    final fontSize = radius * fontSizeFactor;
    for (var i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = _pointOnDial(center, radius * 0.72, angles[i]);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _paintHands(Canvas canvas, Offset center, double radius) {
    // Hands at ~3 o'clock, matching the reference image.
    final hourEnd = _pointOnDial(center, radius * 0.42, math.pi / 2);
    final minuteEnd = _pointOnDial(center, radius * 0.62, math.pi / 2);

    canvas.drawLine(
      center,
      hourEnd,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      minuteEnd,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      1.8,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  Offset _pointOnDial(Offset center, double r, double angleFrom12) {
    // Convert clock angle (0 = 12) to canvas radians (0 = 3 o'clock).
    final canvasAngle = angleFrom12 - math.pi / 2;
    return Offset(
      center.dx + r * math.cos(canvasAngle),
      center.dy + r * math.sin(canvasAngle),
    );
  }

  @override
  bool shouldRepaint(covariant _DialFacePainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color;
}
