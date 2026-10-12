import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../domain/models/product_detail.dart';

/// Height the dock reserves under the sheet.
const double kProductGemDockHeight = 118;

/// The product switcher: a curved glass rail that cradles gem-cut frames.
///
/// The frame in the middle rises out of the rail, glows and shimmers while
/// the others tilt away in depth. A thin ring traced around the active frame
/// shows how far through the list you are. Scrubbing glides on spring
/// physics and ticks at every stop; the product behind follows the rail.
class ProductGemDock extends StatefulWidget {
  const ProductGemDock({
    required this.count,
    required this.index,
    required this.detailAt,
    required this.onSelected,
    super.key,
  });

  final int count;

  /// Index of the product currently shown in the sheet.
  final int index;
  final ProductDetail Function(int index) detailAt;
  final ValueChanged<int> onSelected;

  @override
  State<ProductGemDock> createState() => _ProductGemDockState();
}

class _ProductGemDockState extends State<ProductGemDock>
    with SingleTickerProviderStateMixin {
  static const _fraction = 0.2;
  static const _settleDelay = Duration(milliseconds: 150);

  late final PageController _pages = PageController(
    initialPage: widget.index,
    viewportFraction: _fraction,
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );
  Timer? _settle;
  int _focus = 0;

  @override
  void initState() {
    super.initState();
    _focus = widget.index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _settle?.cancel();
    _idle.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _onPage(int page) {
    if (page == _focus) return;
    AppHaptics.selection();
    setState(() => _focus = page);
    _settle?.cancel();
    // Follow the rail once it has rested on a frame for a beat, so a fast
    // flick plays a single transition at the end instead of one per stop.
    _settle = Timer(_settleDelay, () {
      if (mounted && _focus != widget.index) widget.onSelected(_focus);
    });
  }

  void _tap(int i) {
    if (i == _focus) return;
    _settle?.cancel();
    AppHaptics.light();
    setState(() => _focus = i);
    widget.onSelected(i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 620),
      curve: LuxeMotion.settle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final focused = widget.detailAt(_focus.clamp(0, widget.count - 1));

    return SizedBox(
      height: kProductGemDockHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(top: 34, child: _Rail(palette: p)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 94,
            child: PageView.builder(
              controller: _pages,
              clipBehavior: Clip.none,
              itemCount: widget.count,
              onPageChanged: _onPage,
              physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: Listenable.merge([_pages, _idle]),
                builder: (context, _) => _Gem(
                  detail: widget.detailAt(i),
                  index: i,
                  count: widget.count,
                  page: _page,
                  shimmer: _idle.value,
                  palette: p,
                  onTap: () => _tap(i),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 9,
            child: _Caption(
              title: focused.title,
              index: _focus,
              count: widget.count,
              palette: p,
            ),
          ),
        ],
      ),
    );
  }

  double get _page {
    if (_pages.hasClients && _pages.position.haveDimensions) {
      return _pages.page ?? widget.index.toDouble();
    }
    return widget.index.toDouble();
  }
}

/// Title and "3 / 24", cross-fading as the rail moves.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.title,
    required this.index,
    required this.count,
    required this.palette,
  });

  final String title;
  final int index;
  final int count;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: LuxeMotion.fast,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(index),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(palette.ink, size: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${index + 1} / $count',
            style: LuxeType.figure(palette.inkFaint, size: 11),
          ),
        ],
      ),
    );
  }
}

/// Frosted rail whose top edge swells under the centre frame.
class _Rail extends StatelessWidget {
  const _Rail({required this.palette});

  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final path = _railPath(Size(c.maxWidth, c.maxHeight));
        return ClipPath(
          clipper: _PathClipper(path),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: CustomPaint(
              size: Size(c.maxWidth, c.maxHeight),
              painter: _RailPainter(path: path, palette: palette),
            ),
          ),
        );
      },
    );
  }
}

Path _railPath(Size s) {
  const r = 28.0;
  const swell = 24.0;
  final cx = s.width / 2;
  final hw = math.min(78.0, s.width / 4);
  // The rail is drawn in a box that starts [swell] above its flat top edge.
  const top = swell;
  return Path()
    ..moveTo(0, top + r)
    ..arcToPoint(const Offset(r, top), radius: const Radius.circular(r))
    ..lineTo(cx - hw, top)
    ..cubicTo(cx - hw * 0.42, top, cx - hw * 0.6, top - swell, cx, top - swell)
    ..cubicTo(cx + hw * 0.6, top - swell, cx + hw * 0.42, top, cx + hw, top)
    ..lineTo(s.width - r, top)
    ..arcToPoint(Offset(s.width, top + r), radius: const Radius.circular(r))
    ..lineTo(s.width, s.height - r)
    ..arcToPoint(
      Offset(s.width - r, s.height),
      radius: const Radius.circular(r),
    )
    ..lineTo(r, s.height)
    ..arcToPoint(Offset(0, s.height - r), radius: const Radius.circular(r))
    ..close();
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}

class _RailPainter extends CustomPainter {
  const _RailPainter({required this.path, required this.palette});

  final Path path;
  final LuxePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.isDark;
    final bounds = Offset.zero & size;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xB3222226), Color(0xCC121214)]
              : const [Color(0xD9FFFFFF), Color(0xB8F1ECE3)],
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.accent.withValues(alpha: dark ? 0.55 : 0.5),
            palette.hairline.withValues(alpha: 0.6),
          ],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.path != path || old.palette != palette;
}

/// One gem-cut frame on the rail.
class _Gem extends StatelessWidget {
  const _Gem({
    required this.detail,
    required this.index,
    required this.count,
    required this.page,
    required this.shimmer,
    required this.palette,
    required this.onTap,
  });

  static const _size = 62.0;

  final ProductDetail detail;
  final int index;
  final int count;
  final double page;
  final double shimmer;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = index - page;
    final away = d.abs();
    final near = (1 - away).clamp(0.0, 1.0);
    final scale = ui.lerpDouble(1.18, 0.7, (away / 1.6).clamp(0.0, 1.0))!;
    // Centre frame lifts out of the rail; the rest sag along a shallow arc.
    final lift = -22 * near + math.pow(math.min(away, 2.6), 2) * 3.2;
    final opacity = (1 - away * 0.26).clamp(0.22, 1.0);

    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Color.lerp(palette.hairline, palette.accent, near)!,
        width: 1 + near * 1.3,
      ),
    );

    final frame = SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              color: palette.surfaceRaised,
              shadows: [
                if (near > 0.02)
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.5 * near),
                    blurRadius: 26 * near,
                    spreadRadius: 1 * near,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18 * opacity),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Parallax: the picture drifts against the rail's motion.
                Transform.translate(
                  offset: Offset(-d.clamp(-1.5, 1.5) * 9, 0),
                  child: Transform.scale(
                    scale: 1.28,
                    child: _GemPicture(media: detail.media, palette: palette),
                  ),
                ),
                if (near > 0.5) _Sheen(t: shimmer, strength: near),
              ],
            ),
          ),
          if (near > 0.05)
            CustomPaint(
              painter: _ProgressRing(
                shape: shape,
                progress: ((page + 1) / count).clamp(0.0, 1.0),
                color: palette.accent,
                track: palette.hairline,
                opacity: near,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: detail.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..translateByDouble(0, lift, 0, 1)
                ..rotateY(-d.clamp(-1.5, 1.5) * 0.5)
                ..rotateZ(d.clamp(-1.5, 1.5) * 0.14)
                ..scaleByDouble(scale, scale, 1, 1),
              child: frame,
            ),
          ),
        ),
      ),
    );
  }
}

/// A slow diagonal glint that crosses the active frame now and then.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.t, required this.strength});

  final double t;
  final double strength;

  @override
  Widget build(BuildContext context) {
    // The glint only runs in the first part of each cycle, then rests.
    final run = (t / 0.4).clamp(0.0, 1.0);
    if (run <= 0 || run >= 1) return const SizedBox.shrink();
    final x = -1.6 + run * 3.2;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(x - 0.6, -1),
            end: Alignment(x + 0.6, 1),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.42 * strength),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Traces the frame's outline to show the position in the list.
class _ProgressRing extends CustomPainter {
  const _ProgressRing({
    required this.shape,
    required this.progress,
    required this.color,
    required this.track,
    required this.opacity,
  });

  final BeveledRectangleBorder shape;
  final double progress;
  final Color color;
  final Color track;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = shape.getOuterPath(Offset.zero & size);
    canvas.save();
    // Sit just outside the frame so the ring never covers the picture.
    const grow = 6.0;
    canvas.translate(-grow / 2, -grow / 2);
    canvas.scale(
      (size.width + grow) / size.width,
      (size.height + grow) / size.height,
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track.withValues(alpha: 0.7 * opacity),
    );
    final metrics = outline.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: opacity);
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = math.min(remaining, m.length);
      canvas.drawPath(m.extractPath(0, take), arc);
      remaining -= take;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ProgressRing old) =>
      old.progress != progress ||
      old.opacity != opacity ||
      old.color != color ||
      old.track != track;
}

class _GemPicture extends StatelessWidget {
  const _GemPicture({required this.media, required this.palette});

  final ProductMedia media;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    final image = media.imageAt(0);
    Widget fallback() {
      final shape = media.shapeKey;
      return Center(
        child: shape != null
            ? renderShapeSvg(shape, size: 30, color: palette.accent)
            : Icon(media.fallbackIcon, size: 26, color: palette.accent),
      );
    }

    if (image == null) return fallback();
    if (!image.isAsset) {
      return AppNetworkImage(
        url: image.path,
        fit: media.fit,
        memCacheWidth: 220,
        error: fallback(),
      );
    }
    if (image.path == CatalogMissingImage.assetPath) return fallback();
    return Image.asset(
      image.path,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}
