import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

enum _Glyph { seal, shield, lock }

/// Three trust pillars whose line icons draw themselves on reveal.
class HomePromise extends StatelessWidget {
  const HomePromise({super.key});

  @override
  Widget build(BuildContext context) {
    final gutter = homeGutter(context);
    const pillars = [
      (
        _Glyph.seal,
        HomeL10n.pillarCertifiedTitle,
        HomeL10n.pillarCertifiedBody,
      ),
      (_Glyph.shield, HomeL10n.pillarSellersTitle, HomeL10n.pillarSellersBody),
      (_Glyph.lock, HomeL10n.pillarPaymentsTitle, HomeL10n.pillarPaymentsBody),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, HomeSpace.section, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeading(
            eyebrow: context.tr(HomeL10n.promiseEyebrow),
            title: context.tr(HomeL10n.promiseTitle),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < pillars.length; i++)
            ScrollReveal.builder(
              delay: HomeMotion.stagger * i,
              duration: const Duration(milliseconds: 1400),
              builder: (context, reveal) => _Pillar(
                glyph: pillars[i].$1,
                title: context.tr(pillars[i].$2),
                body: context.tr(pillars[i].$3),
                reveal: reveal,
              ),
            ),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.glyph,
    required this.title,
    required this.body,
    required this.reveal,
  });

  final _Glyph glyph;
  final String title;
  final String body;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, _) {
        final t = reveal.value;
        final text = (t * 1.4 - 0.3).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: t.clamp(0.0, 1.0),
                child: Container(height: 0.8, color: palette.hairline),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomPaint(
                    size: const Size.square(44),
                    painter: _GlyphPainter(
                      glyph: glyph,
                      progress: t,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, (1 - text) * 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: HomeType.display(24, palette.ink),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: HomeType.body(palette.inkMuted, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Strokes a 44×44 line glyph up to [progress] of its total length.
class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.glyph,
    required this.progress,
    required this.color,
  });

  final _Glyph glyph;
  final double progress;
  final Color color;

  static final Map<_Glyph, Path> _paths = {
    _Glyph.seal: Path()
      ..addOval(Rect.fromCircle(center: const Offset(22, 18), radius: 13))
      ..moveTo(22, 10)
      ..lineTo(28.5, 16)
      ..lineTo(22, 26)
      ..lineTo(15.5, 16)
      ..close()
      ..moveTo(15.5, 16)
      ..lineTo(28.5, 16)
      ..moveTo(15, 29)
      ..lineTo(12, 41)
      ..lineTo(17, 38)
      ..lineTo(20, 42)
      ..lineTo(22, 31)
      ..moveTo(29, 29)
      ..lineTo(32, 41)
      ..lineTo(27, 38)
      ..lineTo(24, 42)
      ..lineTo(22, 31),
    _Glyph.shield: Path()
      ..moveTo(22, 4)
      ..lineTo(37, 10)
      ..lineTo(37, 21)
      ..quadraticBezierTo(37, 34, 22, 41)
      ..quadraticBezierTo(7, 34, 7, 21)
      ..lineTo(7, 10)
      ..close()
      ..moveTo(15, 22)
      ..lineTo(20, 27)
      ..lineTo(30, 16),
    _Glyph.lock: Path()
      ..moveTo(15, 19)
      ..lineTo(15, 13)
      ..arcToPoint(const Offset(29, 13), radius: const Radius.circular(7))
      ..lineTo(29, 19)
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 19, 26, 21),
          const Radius.circular(4),
        ),
      )
      ..addOval(Rect.fromCircle(center: const Offset(22, 28), radius: 2.4))
      ..moveTo(22, 30.4)
      ..lineTo(22, 34),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final source = _paths[glyph]!;
    if (progress >= 1) {
      canvas.drawPath(source, paint);
      return;
    }
    final metrics = source.computeMetrics().toList(growable: false);
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var budget = total * progress;
    final out = Path();
    for (final ui.PathMetric m in metrics) {
      if (budget <= 0) break;
      out.addPath(m.extractPath(0, budget.clamp(0, m.length)), Offset.zero);
      budget -= m.length;
    }
    canvas.drawPath(out, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.progress != progress || old.color != color || old.glyph != glyph;
}
