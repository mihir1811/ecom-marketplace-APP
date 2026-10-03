import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../jewellery_category_images.dart';

/// Always-dark hero stage for the jewelry house.
///
/// Cut-out pieces float on a warm key light, sway in 3D, catch a travelling
/// glint and twinkle with stardust. Swiping changes the piece; dragging
/// tilts it. Pieces advance on their own, shown by the story-style
/// progress bars, and pause while touched. The editorial copy and the
/// "Explore …" call to action follow the current piece.
class JewelryShowcaseStage extends StatefulWidget {
  const JewelryShowcaseStage({
    required this.height,
    required this.topInset,
    required this.onExplore,
    required this.onShopAll,
    super.key,
  });

  final double height;

  /// Space reserved for the floating header.
  final double topInset;
  final ValueChanged<JewelryShowcasePiece> onExplore;
  final VoidCallback onShopAll;

  @override
  State<JewelryShowcaseStage> createState() => _JewelryShowcaseStageState();
}

class _JewelryShowcaseStageState extends State<JewelryShowcaseStage>
    with TickerProviderStateMixin {
  static const _pieces = JewelryShowcasePiece.all;
  static const _dwell = Duration(milliseconds: 5200);

  /// Continuous clock for float, sway, glint and stardust (seconds / 12).
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  /// Time spent on the current piece; drives auto-advance and the bars.
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _dwell,
  )..addStatusListener(_onDwellDone);

  /// Drag tilt that springs back to rest on release.
  late final AnimationController _tilt = AnimationController.unbounded(
    vsync: this,
  );

  final _pages = PageController();
  final _page = ValueNotifier<double>(0);
  int _index = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      if (_pages.hasClients) _page.value = _pages.page ?? 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _clock.stop();
      _progress.stop();
    } else {
      if (!_clock.isAnimating) _clock.repeat();
      if (!_progress.isAnimating) _progress.forward();
    }
    for (final piece in _pieces) {
      precacheImage(AssetImage(piece.asset), context);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _progress.dispose();
    _tilt.dispose();
    _pages.dispose();
    _page.dispose();
    super.dispose();
  }

  void _onDwellDone(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (!_pages.hasClients) return;
    _pages.animateToPage(
      (_index + 1) % _pieces.length,
      duration: const Duration(milliseconds: 1100),
      curve: LuxeMotion.settle,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    if (_reduceMotion) return;
    _progress.forward(from: 0);
  }

  void _onPointerDown(PointerDownEvent _) {
    _tilt.stop();
    _progress.stop();
  }

  void _onPointerMove(PointerMoveEvent e) {
    _tilt.value = (_tilt.value + e.delta.dx * 0.006).clamp(-0.55, 0.55);
  }

  void _onPointerUp(PointerEvent _) {
    _tilt.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 120, damping: 11),
        _tilt.value,
        0,
        0,
      ),
    );
    if (!_reduceMotion) _progress.forward();
  }

  void _jumpTo(int index) {
    AppHaptics.selection();
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 900),
      curve: LuxeMotion.settle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final piece = _pieces[_index];
    final width = MediaQuery.sizeOf(context).width;
    final pieceExtent = math.min(width * 0.78, widget.height * 0.5);

    return SizedBox(
      height: widget.height,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Key light, re-tinted for each piece.
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: piece.glow),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, glow, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: LuxeStage.obsidian,
                  gradient: RadialGradient(
                    center: Alignment(
                      0,
                      -1 + 2 * (widget.topInset + pieceExtent * 0.55) /
                          widget.height,
                    ),
                    radius: 0.85,
                    // Opaque blends: the stage never shows the page behind.
                    colors: [
                      Color.alphaBlend(
                        glow!.withValues(alpha: 0.24),
                        LuxeStage.obsidian,
                      ),
                      Color.alphaBlend(
                        glow.withValues(alpha: 0.07),
                        LuxeStage.obsidian,
                      ),
                      LuxeStage.obsidian,
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            CustomPaint(painter: _StardustPainter(_clock)),
            // Pieces.
            Positioned(
              top: widget.topInset,
              left: 0,
              right: 0,
              height: pieceExtent + 40,
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _pieces.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, i) => _FloatingPiece(
                    piece: _pieces[i],
                    index: i,
                    extent: pieceExtent,
                    clock: _clock,
                    page: _page,
                    tilt: _tilt,
                    onTap: () => widget.onExplore(_pieces[i]),
                  ),
                ),
              ),
            ),
            // Fade into the page below.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 140,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00070709), LuxeStage.obsidian],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 44,
              child: _StageCopy(
                piece: piece,
                index: _index,
                count: _pieces.length,
                progress: _progress,
                onExplore: () => widget.onExplore(piece),
                onShopAll: widget.onShopAll,
                onJump: _jumpTo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One showcase piece: floats, sways and tilts in perspective, slides with
/// parallax between pages and catches a travelling glint.
class _FloatingPiece extends StatelessWidget {
  const _FloatingPiece({
    required this.piece,
    required this.index,
    required this.extent,
    required this.clock,
    required this.page,
    required this.tilt,
    required this.onTap,
  });

  final JewelryShowcasePiece piece;
  final int index;
  final double extent;
  final Animation<double> clock;
  final ValueNotifier<double> page;
  final Animation<double> tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = Image.asset(
      piece.asset,
      width: extent,
      height: extent,
      fit: BoxFit.contain,
      cacheWidth: (extent * dpr).round(),
      filterQuality: FilterQuality.medium,
    );

    return Semantics(
      button: true,
      label: context.tr(
        JewelryFlowL10n.explore,
        {'name': context.tr(piece.labelKey)},
      ),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([clock, page, tilt]),
          builder: (context, child) {
            final t = clock.value * 2 * math.pi;
            final offset = (page.value - index).clamp(-1.0, 1.0);
            final bob = math.sin(t * 2 + index) * 7;
            final sway = math.sin(t + index) * 0.16 + tilt.value - offset * 0.7;
            final pitch = math.sin(t * 1.5 + index) * 0.05;
            final scale = 1 - offset.abs() * 0.22;
            final opacity = (1 - offset.abs() * 1.1).clamp(0.0, 1.0);
            // Glint sweeps across every ~4s and rests off-piece between.
            final g = (clock.value * 3 + index * 0.27) % 1 * 2.6 - 0.8;

            final m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..translateByDouble(offset * -70, bob, 0, 1)
              ..rotateY(sway)
              ..rotateX(pitch)
              ..scaleByDouble(scale, scale, 1, 1);

            return Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x59FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [
                          0,
                          (g - 0.12).clamp(0.0, 1.0),
                          g.clamp(0.0, 1.0),
                          (g + 0.12).clamp(0.0, 1.0),
                          1,
                        ],
                      ).createShader(rect),
                      child: child,
                    ),
                  ),
                  // Soft reflection pooling beneath the piece.
                  Transform.scale(
                    scaleX: 1 - (bob + 7) / 60,
                    child: Container(
                      width: extent * 0.62,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: piece.glow.withValues(alpha: 0.32),
                            blurRadius: 26,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          child: image,
        ),
      ),
    );
  }
}

/// Eyebrow, headline, current collection, CTA pair and progress bars.
class _StageCopy extends StatelessWidget {
  const _StageCopy({
    required this.piece,
    required this.index,
    required this.count,
    required this.progress,
    required this.onExplore,
    required this.onShopAll,
    required this.onJump,
  });

  final JewelryShowcasePiece piece;
  final int index;
  final int count;
  final Animation<double> progress;
  final VoidCallback onExplore;
  final VoidCallback onShopAll;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final label = context.tr(piece.labelKey);
    Widget enter(Widget child, int i) => animate
        ? child
              .animate(delay: (150 + i * 110).ms)
              .fadeIn(duration: 600.ms)
              .moveY(
                begin: 16,
                end: 0,
                duration: 900.ms,
                curve: LuxeMotion.settle,
              )
        : child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        enter(
          Row(
            children: [
              Container(width: 22, height: 1, color: LuxeStage.gold),
              const SizedBox(width: 10),
              Text(
                context.tr(JewelryFlowL10n.houseEyebrow).toUpperCase(),
                style: LuxeType.eyebrow(LuxeStage.gold),
              ),
            ],
          ),
          0,
        ),
        const SizedBox(height: 12),
        enter(
          Text(
            context.tr(JewelryFlowL10n.houseHeadline),
            style: LuxeType.display(40, LuxeStage.ink),
          ),
          1,
        ),
        const SizedBox(height: 10),
        enter(
          Text(
            context.tr(JewelryFlowL10n.houseIntro),
            style: LuxeType.body(LuxeStage.inkMuted, size: 14),
          ),
          2,
        ),
        const SizedBox(height: 20),
        enter(
          Row(
            children: [
              Flexible(
                child: _StagePill(
                  label: context.tr(JewelryFlowL10n.explore, {'name': label}),
                  icon: Icons.arrow_forward_rounded,
                  filled: true,
                  onTap: onExplore,
                  keyValue: piece.asset,
                ),
              ),
              const SizedBox(width: 10),
              _StagePill(
                label: context.tr(JewelryFlowL10n.shopAll),
                filled: false,
                onTap: onShopAll,
              ),
            ],
          ),
          3,
        ),
        const SizedBox(height: 22),
        enter(
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _ProgressBar(
                    state: i < index
                        ? 1
                        : i > index
                        ? 0
                        : null,
                    progress: progress,
                    onTap: () => onJump(i),
                  ),
                ),
              ],
            ],
          ),
          4,
        ),
      ],
    );
  }
}

/// Stadium action on the dark stage: champagne-white filled or glass.
class _StagePill extends StatelessWidget {
  const _StagePill({
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
    this.keyValue,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final IconData? icon;

  /// Cross-fades the label when this changes.
  final String? keyValue;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? LuxeStage.obsidian : LuxeStage.ink;
    return Material(
      color: filled ? LuxeStage.ink : LuxeStage.glass,
      shape: StadiumBorder(
        side: BorderSide(
          color: filled ? LuxeStage.ink : LuxeStage.glassBorder,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.light();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: AnimatedSize(
            duration: LuxeMotion.medium,
            curve: LuxeMotion.settle,
            child: AnimatedSwitcher(
              duration: LuxeMotion.medium,
              child: Row(
                key: ValueKey(keyValue ?? label),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(fg, size: 13.5),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 16, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Story-style segment: full, empty or (for the current piece) filling.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.state,
    required this.progress,
    required this.onTap,
  });

  /// 1 = done, 0 = upcoming, null = current (follows [progress]).
  final double? state;
  final Animation<double> progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 2,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) => LinearProgressIndicator(
                value: state ?? progress.value,
                backgroundColor: const Color(0x33FFFFFF),
                valueColor: const AlwaysStoppedAnimation(LuxeStage.gold),
                minHeight: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Twinkling four-point glints scattered across the stage.
class _StardustPainter extends CustomPainter {
  _StardustPainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  static final _stars = () {
    final rng = math.Random(7);
    return [
      for (var i = 0; i < 34; i++)
        (
          x: rng.nextDouble(),
          y: rng.nextDouble() * 0.78,
          r: 0.8 + rng.nextDouble() * 2.6,
          phase: rng.nextDouble(),
          speed: 1 + rng.nextInt(3),
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    final dot = Paint();
    for (final s in _stars) {
      final wave = math.sin((clock.value * s.speed + s.phase) * 2 * math.pi);
      final a = math.pow(math.max(0.0, wave), 3).toDouble();
      if (a < 0.02) continue;
      final c = Offset(s.x * size.width, s.y * size.height);
      final color = Color.lerp(LuxeStage.gold, Colors.white, s.phase)!;
      final len = s.r * (2.5 + a * 2.5);
      line.color = color.withValues(alpha: a * 0.8);
      canvas
        ..drawLine(c.translate(-len, 0), c.translate(len, 0), line)
        ..drawLine(c.translate(0, -len), c.translate(0, len), line);
      dot.color = color.withValues(alpha: a);
      canvas.drawCircle(c, s.r * 0.55, dot);
    }
  }

  @override
  bool shouldRepaint(_StardustPainter old) => old.clock != clock;
}
