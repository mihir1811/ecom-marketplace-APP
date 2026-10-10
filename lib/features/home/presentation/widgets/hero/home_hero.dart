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
import 'stage_backdrop.dart';

/// Full-bleed opening stage: a deep-space shader, interactive stardust that
/// gathers into the GemWorld G, a brilliant and a galaxy, an editorial
/// headline and the primary search entry.
class HomeHero extends StatefulWidget {
  const HomeHero({
    required this.height,
    required this.topInset,
    required this.scrollOffset,
    required this.onSearch,
    required this.onExplore,
    super.key,
  });

  final double height;

  /// Space reserved above the cosmos.
  final double topInset;
  final ValueListenable<double> scrollOffset;
  final VoidCallback onSearch;
  final VoidCallback onExplore;

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

  void _select(StarForm form) {
    AppHaptics.selection();
    _dismissHint();
    _field.advance(form);
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
                    const SizedBox(height: 14),
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
                        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 28),
                        child: _HeroCopy(
                          animate: !_reduceMotion,
                          onSearch: widget.onSearch,
                          onExplore: widget.onExplore,
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
              child: _FormDial(
                field: _field,
                hintVisible: _hintVisible,
                animate: !_reduceMotion,
                onSelect: _select,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Caption for the current formation plus a three-step selector.
class _FormDial extends StatelessWidget {
  const _FormDial({
    required this.field,
    required this.hintVisible,
    required this.animate,
    required this.onSelect,
  });

  final StardustField field;
  final ValueListenable<bool> hintVisible;
  final bool animate;
  final ValueChanged<StarForm> onSelect;

  static String _caption(StarForm f) => switch (f) {
    StarForm.glyph => HomeL10n.formGlyph,
    StarForm.gem => HomeL10n.formGem,
    StarForm.galaxy => HomeL10n.formGalaxy,
  };

  @override
  Widget build(BuildContext context) {
    Widget dial = ValueListenableBuilder<StarForm>(
      valueListenable: field.form,
      builder: (context, current, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              switchInCurve: HomeMotion.settle,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                context.tr(_caption(current)).toUpperCase(),
                key: ValueKey(current),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HomeType.eyebrow(HomeStage.gold),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in StarForm.values)
                  Semantics(
                    button: true,
                    selected: f == current,
                    label: context.tr(_caption(f)),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(f),
                      child: SizedBox(
                        width: 36,
                        height: 32,
                        child: Center(
                          child: AnimatedContainer(
                            duration: HomeMotion.medium,
                            curve: HomeMotion.settle,
                            width: f == current ? 22 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: f == current
                                  ? HomeStage.gold
                                  : HomeStage.ink.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: hintVisible,
              builder: (context, visible, child) => AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: HomeMotion.medium,
                child: child,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 14,
                    color: HomeStage.inkMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.tr(HomeL10n.dragHint),
                    style: HomeType.label(HomeStage.inkMuted, size: 11.5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (animate) {
      dial = dial.animate(delay: 1600.ms).fadeIn(duration: 900.ms);
    }
    return dial;
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.animate,
    required this.onSearch,
    required this.onExplore,
  });

  final bool animate;
  final VoidCallback onSearch;
  final VoidCallback onExplore;

  Widget _enter(Widget child, int delayMs, {double dy = 14}) {
    if (!animate) return child;
    return child
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 800.ms, curve: HomeMotion.settle)
        .moveY(begin: dy, end: 0, duration: 900.ms, curve: HomeMotion.settle);
  }

  Widget _line(Widget text, int delayMs) {
    if (!animate) return text;
    return ClipRect(
      child: text
          .animate(delay: delayMs.ms)
          .slideY(
            begin: 1.05,
            end: 0,
            duration: 1100.ms,
            curve: HomeMotion.settle,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final headline = (width * 0.115).clamp(38.0, 62.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(
          Text(
            context.tr(HomeL10n.heroTitleLine1),
            style: HomeType.display(headline, HomeStage.ink),
          ),
          300,
        ),
        _line(
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (rect) => LinearGradient(
              colors: [
                HomeStage.goldLight,
                HomeStage.gold,
                Color.lerp(HomeStage.gold, HomeStage.goldDeep, 0.5)!,
              ],
            ).createShader(rect),
            child: Text(
              context.tr(HomeL10n.heroTitleLine2),
              style: HomeType.displayItalic(headline, Colors.white),
            ),
          ),
          420,
        ),
        const SizedBox(height: 14),
        _enter(
          Text(
            context.tr(
              RemainingL10n.indiaSMarketplaceForDiamondsGemstonesJewelry,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: HomeType.body(HomeStage.inkMuted, size: 14),
          ),
          700,
        ),
        const SizedBox(height: 22),
        _enter(
          _HeroSearchPill(animate: animate, onSearch: onSearch),
          860,
          dy: 18,
        ),
        const SizedBox(height: 14),
        _enter(_ExploreLink(animate: animate, onTap: onExplore), 1050),
      ],
    );
  }
}

/// Glass search entry with a rotating category word.
class _HeroSearchPill extends StatefulWidget {
  const _HeroSearchPill({required this.animate, required this.onSearch});

  final bool animate;
  final VoidCallback onSearch;

  @override
  State<_HeroSearchPill> createState() => _HeroSearchPillState();
}

class _HeroSearchPillState extends State<_HeroSearchPill> {
  static const _words = [
    RemainingL10n.naturalDiamonds,
    RemainingL10n.gemstones,
    RemainingL10n.jewelry,
    RemainingL10n.watches,
    RemainingL10n.labGrown,
    RemainingL10n.bullion,
  ];
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
        if (mounted) setState(() => _index = (_index + 1) % _words.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = context.tr(_words[_index]).toLowerCase();
    return Semantics(
      button: true,
      label: context.tr(HomeL10n.searchPlaceholder),
      child: Material(
        color: HomeStage.glass,
        shape: const StadiumBorder(
          side: BorderSide(color: HomeStage.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onSearch,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.search_rounded, color: HomeStage.gold, size: 21),
                const SizedBox(width: 12),
                Text(
                  '${context.tr(HomeL10n.searchPrefix)} ',
                  style: HomeType.body(HomeStage.inkMuted, size: 15),
                ),
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: HomeMotion.medium,
                      switchInCurve: HomeMotion.settle,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey<String>(word);
                        final slide = Tween<Offset>(
                          begin: Offset(0, incoming ? 0.9 : -0.9),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: Text(
                        word,
                        key: ValueKey<String>(word),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.body(HomeStage.ink, size: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreLink extends StatelessWidget {
  const _ExploreLink({required this.animate, required this.onTap});

  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget arrow = Icon(Icons.south_rounded, size: 16, color: HomeStage.gold);
    if (animate) {
      arrow = arrow
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -2, end: 3, duration: 1100.ms, curve: Curves.easeInOut);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: HomeStage.ink,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          minimumSize: const Size(48, 44),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(HomeL10n.exploreCollections),
              style: HomeType.label(HomeStage.ink),
            ),
            const SizedBox(width: 8),
            arrow,
          ],
        ),
      ),
    );
  }
}
