import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../theme/home_tokens.dart';
import 'stardust_field.dart';
import 'stardust_painter.dart';
import '../../../../spotlight/domain/spotlight_models.dart';
import '../../../../spotlight/presentation/widgets/spotlight_banner_carousel.dart';
import 'home_info_banners.dart';
import 'stage_backdrop.dart';

/// Opening stage: a deep-space shader and interactive stardust that gathers
/// into the GemWorld G, a brilliant and a galaxy, with the promo spotlight
/// overlapping its lower edge.
///
/// The stage is a header, not a screen: it is sized so the next section peeks
/// above the fold, its foot dissolves into the page canvas behind the
/// spotlight card, and only sideways drags orbit the cosmos, so vertical
/// swipes anywhere on it still scroll the page.
class HomeHero extends StatefulWidget {
  const HomeHero({
    required this.height,
    required this.topInset,
    required this.scrollOffset,
    super.key,
  });

  /// Height of the cosmos stage. The spotlight rises [overlap] into it.
  final double height;

  /// Space reserved above the cosmos.
  final double topInset;
  final ValueListenable<double> scrollOffset;

  /// How far the spotlight card rises into the stage; the stage dissolves
  /// into the page canvas behind it.
  static const overlap = 92.0;

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero>
    with SingleTickerProviderStateMixin {
  final _field = StardustField();
  final _clock = ValueNotifier<double>(2);
  final _progress = ValueNotifier<double>(0);
  final _hintVisible = ValueNotifier<bool>(true);
  int? _activePointer;
  late final Ticker _ticker = createTicker(_onTick);
  StardustSprites? _sprites;
  StardustPainter? _painter;
  Duration _last = Duration.zero;
  bool _reduceMotion = false;
  Offset _center = Offset.zero;
  double _scale = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    widget.scrollOffset.addListener(_onScroll);
    StardustSprites.load().then((s) {
      if (mounted) setState(() => _sprites = s);
    });
    sampleGlyph('G').then((cloud) {
      if (!mounted) return;
      _field.setGlyph(cloud);
      if (_reduceMotion) _settleStatic();
    });
    _hintTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) _hintVisible.value = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(HomeHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollOffset != widget.scrollOffset) {
      oldWidget.scrollOffset.removeListener(_onScroll);
      widget.scrollOffset.addListener(_onScroll);
    }
  }

  void _onScroll() {
    _progress.value = (widget.scrollOffset.value / widget.height).clamp(
      0.0,
      1.0,
    );
    _syncTicker();
  }

  /// Runs the simulation only while the stage is on screen.
  void _syncTicker() {
    final shouldRun = !_reduceMotion && _progress.value < 1;
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (_scale <= 0) return;
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    _field.step(dt, _center, _scale);
    _clock.value = _field.time + 2;
  }

  void _settleStatic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scale > 0) _field.settle(_center, _scale);
    });
  }

  void _dismissHint() {
    if (_hintVisible.value) _hintVisible.value = false;
  }

  // Touch scatter is screen-space and runs on any press, including one that
  // turns into a page scroll. Orbiting is a separate pan gesture that only
  // wins the arena for sideways drags; once it wins it orbits the camera a
  // full 360° on both axes as before. Neither pauses or advances the
  // formation cycle, and lifting the finger always lets every star spring
  // home.
  void _onPointerDown(PointerDownEvent e) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    _field
      ..burst(e.localPosition)
      ..setPointer(e.localPosition);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;
    _field.setPointer(e.localPosition);
  }

  void _onPointerEnd(PointerEvent e) {
    if (e.pointer != _activePointer) return;
    _activePointer = null;
    _field.setPointer(null);
  }

  void _onOrbitStart(DragStartDetails d) {
    _field.beginDrag();
    if (d.kind == PointerDeviceKind.touch) AppHaptics.light();
    _dismissHint();
  }

  void _onOrbitUpdate(DragUpdateDetails d) {
    _field.dragBy(d.delta);
    if (_reduceMotion) _field.reproject(_center, _scale);
  }

  void _onOrbitEnd(DragEndDetails d) {
    _field.endDrag(_reduceMotion ? Offset.zero : d.velocity.pixelsPerSecond);
  }

  void _onOrbitCancel() => _field.endDrag(Offset.zero);

  @override
  void dispose() {
    widget.scrollOffset.removeListener(_onScroll);
    _hintTimer?.cancel();
    _ticker.dispose();
    _field.dispose();
    _clock.dispose();
    _progress.dispose();
    _hintVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = width > 720 ? (width - 680) / 2 : HomeSpace.gutter;
    final palette = HomePalette.of(context);
    final stageHeight = widget.height;
    const overlap = HomeHero.overlap;

    return Semantics(
      container: true,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: stageHeight,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: StageBackdrop(
                      clock: _clock,
                      progress: _progress,
                      focusY: 0.36,
                    ),
                  ),
                  Positioned.fill(
                    top: widget.topInset,
                    child: _buildCosmos(context),
                  ),
                  // The stage's foot dissolves into the page behind the
                  // spotlight card instead of ending on a hard edge.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: overlap * 1.4,
                    child: IgnorePointer(
                      child: _StageFade(color: palette.canvas),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: overlap + 12,
                    child: _DragHint(
                      visible: _hintVisible,
                      animate: !_reduceMotion,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: stageHeight - overlap),
              // Keeps the stage's dissolve covered while banners load.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: overlap),
                // Paid HOME_BANNER ads from the spotlight API; GemWorld
                // info banners while none is live.
                child: SpotlightBannerCarousel(
                  query: spotlightQuery(SpotlightPlacement.homeBanner),
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  activeDotColor: palette.accent,
                  dotColor: palette.ink.withValues(alpha: 0.18),
                  empty: const HomeInfoBanners(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCosmos(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Centred in the stage area the spotlight leaves uncovered; stars
        // that drift lower pass behind the card and its dissolve.
        final open = size.height - HomeHero.overlap;
        final center = Offset(size.width / 2, open * 0.52);
        final scale = math.min(size.width * 0.46, open * 0.5);
        final sprites = _sprites;
        if (sprites != null &&
            (_painter == null ||
                _painter!.sprites != sprites ||
                center != _center ||
                scale != _scale)) {
          _painter = StardustPainter(
            field: _field,
            sprites: sprites,
            progress: _progress,
            center: center,
            scale: scale,
          );
          if (_reduceMotion) _settleStatic();
        }
        _center = center;
        _scale = scale;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Semantics(
                label: context.tr(HomeL10n.dragHint),
                // Sideways drags orbit; mostly-vertical drags lose the arena
                // to the page's scroll recognizer, so the stage never traps
                // the scroll. The listener sees every pointer for scatter.
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    PanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          PanGestureRecognizer
                        >(
                          PanGestureRecognizer.new,
                          (r) => r
                            ..onStart = _onOrbitStart
                            ..onUpdate = _onOrbitUpdate
                            ..onEnd = _onOrbitEnd
                            ..onCancel = _onOrbitCancel,
                        ),
                  },
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerEnd,
                    onPointerCancel: _onPointerEnd,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _painter,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Eased dissolve from transparent to the page [color]. Many stops on a
/// smoothstep curve avoid the visible band a two-stop linear gradient leaves
/// between a dark stage and a light page.
class _StageFade extends StatelessWidget {
  const _StageFade({required this.color});

  final Color color;

  static const _steps = 12;

  @override
  Widget build(BuildContext context) {
    final stops = [for (var i = 0; i <= _steps; i++) i / _steps];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: stops,
          colors: [
            for (final t in stops) color.withValues(alpha: t * t * (3 - 2 * t)),
          ],
        ),
      ),
    );
  }
}

/// Touch hint under the cosmos; fades away after the first interaction.
class _DragHint extends StatelessWidget {
  const _DragHint({required this.visible, required this.animate});

  final ValueListenable<bool> visible;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget hint = ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, shown, child) => AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: HomeMotion.medium,
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 14, color: HomeStage.inkMuted),
          const SizedBox(width: 5),
          Text(
            context.tr(HomeL10n.dragHint),
            style: HomeType.label(HomeStage.inkMuted, size: 11.5),
          ),
        ],
      ),
    );
    if (animate) {
      hint = hint.animate(delay: 1600.ms).fadeIn(duration: 900.ms);
    }
    return IgnorePointer(child: Center(child: hint));
  }
}
