import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/widgets/gem3d/gem_mesh.dart';
import 'auth_tokens.dart';

/// Fades + lifts its child into place once, staggered by [index].
class AuthReveal extends StatelessWidget {
  const AuthReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
    this.blur = false,
  });

  final Widget child;
  final int index;
  final double offset;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    if (AuthMotion.reduced(context)) return child;
    var a = child
        .animate(delay: AuthMotion.stagger(index))
        .fadeIn(duration: AuthMotion.entrance, curve: AuthMotion.ease)
        .moveY(
          begin: offset,
          end: 0,
          duration: AuthMotion.entrance,
          curve: AuthMotion.ease,
        );
    if (blur) {
      a = a.blurXY(begin: 8, end: 0, duration: AuthMotion.slow);
    }
    return a;
  }
}

/// "◇ GEMWORLD" letter-spaced wordmark.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Semantics(
      header: true,
      label: 'GemWorld',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(12, 14),
            painter: _GlyphPainter(p.accent),
          ),
          const SizedBox(width: AuthSpace.s8),
          Text(
            'GEMWORLD',
            style: AuthType.eyebrow(
              p,
            ).copyWith(color: p.ink, fontSize: 12, letterSpacing: 4.4),
          ),
        ],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final girdle = h * 0.34;
    final path = Path()
      ..moveTo(w * 0.22, 0)
      ..lineTo(w * 0.78, 0)
      ..lineTo(w, girdle)
      ..lineTo(w / 2, h)
      ..lineTo(0, girdle)
      ..close()
      ..moveTo(0, girdle)
      ..lineTo(w, girdle);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.color != color;
}

/// Soft breathing light pool that sits behind a gem.
class AuthHalo extends StatelessWidget {
  const AuthHalo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    final halo = IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              p.accent.withValues(alpha: p.isDark ? 0.22 : 0.16),
              p.accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
    if (AuthMotion.reduced(context)) return halo;
    return halo
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.92,
          end: 1.06,
          duration: 3200.ms,
          curve: AuthMotion.easeInOut,
        );
  }
}

/// Screen hero: an eyebrow, a serif statement and one supporting line.
/// [cut] and [showGem] are kept for call sites; no gem is drawn.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.cut = GemCut.round,
    this.showGem = false,
  });

  final String eyebrow;
  final String title;
  final Widget? subtitle;
  final GemCut cut;
  final bool showGem;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);

    return Column(
      children: [
        const SizedBox(height: AuthSpace.s24),
        AuthReveal(
          index: 1,
          child: Text(
            eyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: AuthType.eyebrow(p),
          ),
        ),
        const SizedBox(height: AuthSpace.s12),
        AuthReveal(
          index: 2,
          blur: true,
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AuthType.display(p),
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AuthSpace.s12),
          AuthReveal(
            index: 3,
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: AuthType.body(p),
              child: subtitle!,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small uppercase label that opens a group of fields.
class AuthSectionLabel extends StatelessWidget {
  const AuthSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AuthSpace.s12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: AuthType.eyebrow(
              p,
            ).copyWith(color: p.inkMuted, letterSpacing: 2),
          ),
          const SizedBox(width: AuthSpace.s12),
          Expanded(child: Container(height: 1, color: p.hairline)),
          if (trailing != null) ...[
            const SizedBox(width: AuthSpace.s12),
            Text(trailing!, style: AuthType.caption(p)),
          ],
        ],
      ),
    );
  }
}
