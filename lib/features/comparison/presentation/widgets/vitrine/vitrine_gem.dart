import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/widgets/app_network_image.dart';
import '../../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../domain/models/compare_category.dart';
import '../../../domain/models/compare_item.dart';
import 'vitrine_style.dart';

/// A brilliant-cut wireframe turning slowly in 3D: crown, girdle and
/// pavilion edges are projected with perspective and fade with depth.
class VitrineGem extends StatefulWidget {
  const VitrineGem({super.key, this.size = 140, this.period = 16});

  final double size;

  /// Seconds per full turn.
  final double period;

  @override
  State<VitrineGem> createState() => _VitrineGemState();
}

class _VitrineGemState extends State<VitrineGem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.period * 1000).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _GemPainter(turn: _spin, gold: v.gold, glow: v.goldSoft),
        ),
      ),
    );
  }
}

class _GemPainter extends CustomPainter {
  _GemPainter({required this.turn, required this.gold, required this.glow})
    : super(repaint: turn);

  final Animation<double> turn;
  final Color gold;
  final Color glow;

  static final List<List<double>> _verts = () {
    final v = <List<double>>[];
    // Table (0–7), girdle (8–23), culet (24).
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      v.add([0.52 * math.cos(a), -0.42, 0.52 * math.sin(a)]);
    }
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 + math.pi / 16;
      v.add([math.cos(a), -0.08, math.sin(a)]);
    }
    v.add([0, 0.95, 0]);
    return v;
  }();

  static final List<(int, int)> _edges = () {
    final e = <(int, int)>[];
    for (var i = 0; i < 8; i++) {
      e.add((i, (i + 1) % 8));
      e.add((i, 8 + (2 * i) % 16));
      e.add((i, 8 + (2 * i + 15) % 16));
    }
    for (var i = 0; i < 16; i++) {
      e.add((8 + i, 8 + (i + 1) % 16));
      if (i.isEven) e.add((8 + i, 24));
    }
    return e;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.4;

    canvas.drawCircle(
      c,
      r * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.25)),
    );

    final yaw = turn.value * 2 * math.pi;
    final cy = math.cos(yaw), sy = math.sin(yaw);
    const ct = 0.9286, st = 0.3709; // cos / sin of a 0.38 rad tilt

    final pts = <Offset>[];
    final depth = <double>[];
    for (final p in _verts) {
      final x1 = p[0] * cy + p[2] * sy;
      final z1 = -p[0] * sy + p[2] * cy;
      final y2 = p[1] * ct - z1 * st;
      final z2 = p[1] * st + z1 * ct;
      final persp = 3.2 / (3.2 + z2);
      pts.add(c + Offset(x1 * r * persp, y2 * r * persp));
      depth.add(z2);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _edges) {
      final z = (depth[a] + depth[b]) / 2;
      final near = ((1 - z) / 2).clamp(0.0, 1.0);
      paint
        ..strokeWidth = 0.6 + near * 0.9
        ..color = gold.withValues(alpha: 0.18 + near * 0.72);
      canvas.drawLine(pts[a], pts[b], paint);
    }
    // A glint riding the girdle.
    final glint = pts[8 + ((turn.value * 16).floor() % 16)];
    canvas.drawCircle(
      glint,
      2.4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_GemPainter old) =>
      old.gold != gold || old.glow != glow || old.turn != turn;
}

/// A piece's photo (or cut glyph) on a soft champagne glow.
class VitrinePieceImage extends StatelessWidget {
  const VitrinePieceImage({
    required this.item,
    required this.size,
    super.key,
    this.radius = 20,
    this.ring = false,
  });

  final CompareItem item;
  final double size;
  final double radius;

  /// Gold hairline ring, for the piece leading the comparison.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final shape = BorderRadius.circular(radius);
    return AnimatedContainer(
      duration: VitrineMotion.settle,
      curve: VitrineMotion.ease,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.35),
          radius: 1.1,
          colors: [v.goldSoft, v.card],
        ),
        border: Border.all(
          color: ring ? v.gold : v.line,
          width: ring ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: v.isDark ? 0.4 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: shape, child: _content(context, v)),
    );
  }

  Widget _content(BuildContext context, Vitrine v) {
    final glyph = _glyph(v);
    final url = item.imageUrl?.trim() ?? '';
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.')) {
      return AppNetworkImage(
        url: lower.startsWith('www.') ? 'https://$url' : url,
        fit: BoxFit.cover,
        memCacheWidth: (size * 3).round(),
        placeholder: _Shimmer(child: glyph),
        error: glyph,
      );
    }
    if (url.startsWith('public/') || url.startsWith('assets/')) {
      return Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => glyph,
        ),
      );
    }
    return glyph;
  }

  Widget _glyph(Vitrine v) {
    final shape = item.shape;
    final glyphSize = size * 0.46;
    return Center(
      child: shape != null && shape.trim().isNotEmpty
          ? renderShapeSvg(shape, size: glyphSize, color: v.gold)
          : Icon(
              item.category == CompareCategory.watch
                  ? Icons.watch_outlined
                  : Icons.diamond_outlined,
              size: glyphSize,
              color: v.gold,
            ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Opacity(opacity: 0.55, child: child)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: v.card.withValues(alpha: 0.9),
        );
  }
}
