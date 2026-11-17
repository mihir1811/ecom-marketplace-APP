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

/// Full-bleed opening stage: a deep-space shader, interactive stardust that
/// gathers into the GemWorld G, a brilliant and a galaxy, and a spotlight of
/// promo banners with trust marks.
class HomeHero extends StatefulWidget {
  const HomeHero({
    required this.height,
    required this.topInset,
    required this.scrollOffset,
    this.bottomInset = 0,
    super.key,
  });

  final double height;

  /// Space reserved above the cosmos.
  final double topInset;
  final ValueListenable<double> scrollOffset;

  /// Space kept clear at the bottom: the stage runs on behind the floating
  /// dock, the spotlight stays above it.
  final double bottomInset;

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
  VelocityTracker? _tracker;
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

  // Dragging orbits the camera 360° exactly as before; the touch scatter is
  // an add-on in screen space. Neither pauses or advances the formation
  // cycle, and lifting the finger always lets every star spring home.
  void _onPointerDown(PointerDownEvent e) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    _tracker = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
    _field
      ..beginDrag()
      ..burst(e.localPosition)
      ..setPointer(e.localPosition);
    if (e.kind == PointerDeviceKind.touch) AppHaptics.light();
    _dismissHint();
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;
    _tracker?.addPosition(e.timeStamp, e.position);
    _field
      ..dragBy(e.delta)
      ..setPointer(e.localPosition);
    if (_reduceMotion) _field.reproject(_center, _scale);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;
    final v = _tracker?.getVelocity().pixelsPerSecond ?? Offset.zero;
    _release(_reduceMotion ? Offset.zero : v);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _release(Offset.zero);
  }

  void _release(Offset velocity) {
    _activePointer = null;
    _tracker = null;
    _field
      ..endDrag(velocity)
      ..setPointer(null);
  }

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

    // The stage ends on a clean edge; no fade bleeds into the page below.
    return Semantics(
      container: true,
      child: SizedBox(
        height: widget.height,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: StageBackdrop(
                  clock: _clock,
                  progress: _progress,
                  focusY: 0.32,
                ),
              ),
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: widget.topInset),
                    Expanded(child: _buildCosmos(context)),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, child) {
                        final p = _progress.value;
                        return Opacity(
                          opacity: (1 - p * 1.8).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -p * 60),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: 16 + widget.bottomInset,
                        ),
                        // Paid HOME_BANNER ads from the spotlight API;
                        // GemWorld info banners while none is live.
                        child: SpotlightBannerCarousel(
                          query: spotlightQuery(SpotlightPlacement.homeBanner),
                          padding: EdgeInsets.symmetric(horizontal: gutter),
                          activeDotColor: HomeStage.gold,
                          dotColor: HomeStage.ink.withValues(alpha: 0.25),
                          empty: const HomeInfoBanners(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCosmos(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final center = Offset(size.width / 2, size.height * 0.42);
        final scale = math.min(size.width * 0.46, size.height * 0.4);
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
                // The eager recognizer wins the gesture arena on touch-down,
                // so the page does not scroll while a finger orbits the
                // cosmos. Scrolling from anywhere else is unaffected.
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    EagerGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          EagerGestureRecognizer
                        >(EagerGestureRecognizer.new, (_) {}),
                  },
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    onPointerCancel: _onPointerCancel,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 2,
              child: _DragHint(visible: _hintVisible, animate: !_reduceMotion),
            ),
          ],
        );
      },
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
