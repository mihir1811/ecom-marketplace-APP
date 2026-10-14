import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../diamonds/presentation/widgets/stone_tint.dart';
import '../../domain/models/product_detail.dart';
import 'product_pager.dart';

/// Height the dock reserves under the sheet.
const double kProductGemDockHeight = 120;

/// Edge of the square each frame is drawn in.
const double _kFrame = 66;

/// Distance from the dock's top to the frames' centre line.
const double _kRowY = 53;

/// The product switcher: a flat glass rail of frames.
///
/// Five frames are in sight at once: the one on show in the middle, one
/// either side of it, and half of the next one at each end of the rail.
/// The centre frame is larger, sits higher and glows. Every product sits in
/// the same rounded square. Swiping the rail, tapping a frame, or swiping the
/// cards above all move the same pager.
class ProductGemDock extends StatefulWidget {
  const ProductGemDock({
    required this.pager,
    required this.detailAt,
    super.key,
  });

  final ProductPager pager;
  final ProductDetail Function(int index) detailAt;

  @override
  State<ProductGemDock> createState() => _ProductGemDockState();
}

class _ProductGemDockState extends State<ProductGemDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5600),
  );

  /// Widgets that only change with the product, kept so a turning rail
  /// repaints transforms instead of rebuilding pictures.
  final Map<int, Widget> _contents = {};

  /// Rounded square every frame is cut from.
  static final Path _frame = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _kFrame, _kFrame),
        const Radius.circular(18),
      ),
    );

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
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final pager = widget.pager;
    final count = pager.count;

    return SizedBox(
      height: kProductGemDockHeight,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          // Four slots across: three whole frames and two halves.
          final slot = width / 4;
          return RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => pager.dragStart(),
                onHorizontalDragUpdate: (d) => pager.dragBy(-d.delta.dx / slot),
                onHorizontalDragEnd: (d) =>
                    pager.dragEnd(-d.velocity.pixelsPerSecond.dx / slot),
                onHorizontalDragCancel: () => pager.dragEnd(0),
                child: AnimatedBuilder(
                  animation: pager.listenable,
                  builder: (context, _) {
                    final pos = pager.position;
                    final from = math.max(0, pos.floor() - 2);
                    final to = math.min(count - 1, pos.ceil() + 2);
                    // Far frames first so the centre one paints on top.
                    final order = [for (var i = from; i <= to; i++) i]
                      ..sort(
                        (a, b) => (b - pos).abs().compareTo((a - pos).abs()),
                      );
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final i in order) _frameAt(i, pos, width, slot, p),
                        Positioned(
                          left: 28,
                          right: 28,
                          top: _kRowY + _kFrame / 2 + 14,
                          child: IgnorePointer(
                            child: _Caption(
                              title: widget.detailAt(pager.nearest).title,
                              index: pager.nearest,
                              count: count,
                              palette: p,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _frameAt(int i, double pos, double width, double slot, LuxePalette p) {
    final detail = widget.detailAt(i);
    final content = _contents.putIfAbsent(
      i,
      () => _GemContent(detail: detail, palette: p),
    );
    final d = i - pos;
    final away = d.abs();
    final near = (1 - away).clamp(0.0, 1.0);
    // Centre frame 1.14, neighbours 0.94, half-visible ends 0.8.
    final scale = away <= 1
        ? 1.14 - 0.2 * away
        : 0.94 - 0.14 * (away - 1).clamp(0.0, 1.0);
    final opacity = away <= 1 ? 1 - 0.1 * away : 0.9 - 0.15 * (away - 1);

    // The frame on show rides higher than the rest, so it reads as the main one.
    final lift = 6 - 11 * near;

    return Positioned(
      key: ValueKey('frame-$i'),
      left: width / 2 + d * slot - _kFrame / 2,
      top: _kRowY - _kFrame / 2 + lift,
      width: _kFrame,
      height: _kFrame,
      child: Semantics(
        button: true,
        label: detail.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.pager.animateTo(i),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: _GemFrame(
                path: _frame,
                near: near,
                palette: p,
                idle: _idle,
                content: content,
              ),
            ),
          ),
        ),
      ),
    );
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
              style: LuxeType.label(Colors.white, size: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${index + 1} / $count',
            style: LuxeType.figure(Colors.white70, size: 11),
          ),
        ],
      ),
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}

/// One frame: fill, picture and border all cut from the same outline.
class _GemFrame extends StatelessWidget {
  const _GemFrame({
    required this.path,
    required this.near,
    required this.palette,
    required this.idle,
    required this.content,
  });

  final Path path;
  final double near;
  final LuxePalette palette;
  final Animation<double> idle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _FramePainter(path: path, near: near, palette: palette),
        ),
        ClipPath(
          clipper: _PathClipper(path),
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (near > 0.5)
                RepaintBoundary(
                  child: _Sheen(animation: idle, strength: near),
                ),
            ],
          ),
        ),
        CustomPaint(
          foregroundPainter: _OutlinePainter(
            path: path,
            near: near,
            palette: palette,
          ),
        ),
      ],
    );
  }
}

/// What sits inside a frame: a diamond or gemstone is drawn as its cut in
/// its own colour ([StoneTint]); anything else shows its photo.
class _GemContent extends StatelessWidget {
  const _GemContent({required this.detail, required this.palette});

  final ProductDetail detail;
  final LuxePalette palette;

  @override
  Widget build(BuildContext context) {
    final key = _shapeKey(detail);
    if (key != null) {
      final color = detail.stoneColor;
      return _TintedCut(
        shape: key,
        tint: StoneTint.resolve(
          grade: color?.grade,
          fancyColor: color?.fancyColor,
          intensity: color?.intensity,
          overtone: color?.overtone,
          species: color?.species,
        ),
        palette: palette,
      );
    }

    final media = detail.media;
    final image = media.imageAt(0);
    final fallback = Center(
      child: Icon(media.fallbackIcon, size: 26, color: palette.accent),
    );

    Widget picture;
    if (image == null || image.path == CatalogMissingImage.assetPath) {
      picture = fallback;
    } else if (!image.isAsset) {
      picture = AppNetworkImage(
        url: image.path,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        error: fallback,
      );
    } else {
      picture = Image.asset(
        image.path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ColoredBox(color: palette.surfaceRaised, child: picture);
  }
}

/// The cut's outline drawn lit from the top left: a soft glow of the body
/// colour behind, an engraved shade under the lines so pale stones still
/// read on a light frame, then the lines in the stone's light → body →
/// shade gradient.
class _TintedCut extends StatelessWidget {
  const _TintedCut({
    required this.shape,
    required this.tint,
    required this.palette,
  });

  final String shape;
  final StoneTint tint;
  final LuxePalette palette;

  static const double _size = _kFrame * 0.66;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.15, -0.2),
            radius: 0.85,
            colors: [
              Color.alphaBlend(
                tint.body.withValues(alpha: 0.3),
                palette.surfaceRaised,
              ),
              palette.surfaceRaised,
            ],
          ),
        ),
        child: Center(
          child: SizedBox.square(
            dimension: _size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: const Offset(0.4, 0.9),
                  child: renderShapeSvg(
                    shape,
                    size: _size,
                    color: tint.deep.withValues(
                      alpha: palette.isDark ? 0.55 : 0.85,
                    ),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: tint.shader,
                  child: renderShapeSvg(
                    shape,
                    size: _size,
                    color: Colors.white,
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

/// Cut drawn for a diamond or gemstone; null for every other segment.
String? _shapeKey(ProductDetail detail) => switch (detail.segment) {
  ProductSegment.naturalDiamond ||
  ProductSegment.labGrownDiamond ||
  ProductSegment.gemstone => resolveShapeSvgKey(
    detail.shapeKey ?? detail.media.shapeKey,
  ),
  _ => null,
};

/// Glow, drop shadow and base fill, drawn from the frame's own outline.
class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.path,
    required this.near,
    required this.palette,
  });

  final Path path;
  final double near;
  final LuxePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (near > 0.02) {
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.accent.withValues(alpha: 0.5 * near)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 12 * near),
      );
    }
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(path, Paint()..color = palette.surfaceRaised);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.near != near || old.path != path || old.palette != palette;
}

/// Border, cut from the same outline as the fill so they never drift apart.
class _OutlinePainter extends CustomPainter {
  const _OutlinePainter({
    required this.path,
    required this.near,
    required this.palette,
  });

  final Path path;
  final double near;
  final LuxePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 + 1.2 * near
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(palette.hairline, palette.accent, near)!,
    );
  }

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.near != near || old.path != path || old.palette != palette;
}

/// A slow diagonal glint that crosses the centre frame now and then.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.animation, required this.strength});

  final Animation<double> animation;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          // The glint only runs in the first part of each cycle, then rests.
          final run = (animation.value / 0.4).clamp(0.0, 1.0);
          if (run <= 0 || run >= 1) return const SizedBox.expand();
          final x = -1.6 + run * 3.2;
          return DecoratedBox(
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
          );
        },
      ),
    );
  }
}
