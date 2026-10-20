import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/audio/dial_sounds.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/luxe_tokens.dart';
import '../../../application/diamond_simulator_controller.dart';
import '../../../domain/diamond_grades.dart';
import '../../../simulation/sim_fancy.dart';
import '../../../simulation/sim_morph.dart';
import '../../sim_labels.dart';
import 'diamond_sim_viewport.dart';
import 'sim_viewport_overlay.dart';

/// The fancy cuts on a slider along the bottom, each as its top view; the
/// one at the centre, larger than the rest, is the stone's. Sliding recuts
/// the one stone from shape to shape exactly as the shape dial does
/// ([SimShapeMorph]), at the stone's own size, and every stop clicks into
/// place. The cuts are shown as they are: the stone keeps its colour and
/// weight, shows no clarity characteristics, and is left as it was when
/// the slider closes.
class SimFancyShapeSlider extends ConsumerStatefulWidget {
  const SimFancyShapeSlider({
    required this.viewport,
    required this.bottomInset,
    required this.onDone,
    super.key,
  });

  final SimViewportController viewport;

  /// Clearance below the Done button (the device's bottom inset).
  final double bottomInset;

  /// Called once the slider has come to rest after Done.
  final VoidCallback onDone;

  /// Centre to centre spacing of the shapes on the slider.
  static const spacing = 64.0;

  /// Height of the slider's track.
  static const track = 78.0;

  @override
  ConsumerState<SimFancyShapeSlider> createState() =>
      _SimFancyShapeSliderState();
}

class _SimFancyShapeSliderState extends ConsumerState<SimFancyShapeSlider>
    with SingleTickerProviderStateMixin {
  /// The shape dial's spring: settles with the barest overshoot.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 130,
    ratio: 0.86,
  );

  /// Where the slider was left, so it reopens on the same shape.
  static double _left = 0;

  /// Slider position in shapes: shape i is at the centre when it is i.
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: _left,
  );
  final _nearest = ValueNotifier<int>(_left.round());

  List<SimFancyShape> _shapes = const [];

  /// The stone being edited, whose colour and weight every cut takes.
  DiamondSimulatorState? _base;
  final _stones = <int, DiamondSimulatorState>{};

  /// Morphs from shape i to i + 1, by i.
  final _pairs = <int, SimShapeMorph>{};
  int _generation = 0;
  double _prev = 0;
  int? _stop;
  bool _closing = false;

  int get _n => _shapes.length;

  @override
  void initState() {
    super.initState();
    _prev = _slide.value;
    _slide
      ..addListener(_onSlide)
      ..addStatusListener(_onStatus);
    DialSounds.preload();
    // A scope only holds a round: the cuts are seen in daylight.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stone = ref.read(diamondSimulatorProvider);
      if (stone.lighting == SimLighting.heartsArrows) {
        ref.read(diamondSimulatorProvider.notifier).setHeartsArrows(false);
      }
    });
    final ready = SimFancyCatalog.loaded;
    if (ready != null) {
      _start(ready);
    } else {
      SimFancyCatalog.load().then((shapes) {
        if (mounted) setState(() => _start(shapes));
      });
    }
  }

  void _start(List<SimFancyShape> shapes) {
    if (shapes.isEmpty) return;
    _shapes = shapes;
    final at = _slide.value.clamp(0, shapes.length - 1).roundToDouble();
    _prev = at;
    _slide.value = at;
    _nearest.value = at.round();
    _rebase(ref.read(diamondSimulatorProvider));
  }

  @override
  void dispose() {
    _generation++;
    _left = _slide.value.clamp(0, math.max(0, _n - 1)).roundToDouble();
    _slide.dispose();
    _nearest.dispose();
    // Back to the stone being edited.
    widget.viewport.morph.value = null;
    super.dispose();
  }

  DiamondSimulatorState _stoneAt(int i) => _stones[i] ??= _base!.copyWith(
    mesh: _shapes[i].mesh,
    inclusions: const [],
  );

  SimShapeMorph _pairAt(int i) =>
      _pairs[i] ??= SimShapeMorph(_shapes[i].mesh, _shapes[i + 1].mesh);

  /// Takes the colour and weight of [stone]; the cuts' morphs stay.
  void _rebase(DiamondSimulatorState stone) {
    _generation++;
    _base = stone;
    _stones.clear();
    _publish(_slide.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _warm());
  }

  /// Cuts the shapes and their morphs ahead of use, nearest first, one
  /// every frame or so, so sliding never waits on them.
  Future<void> _warm() async {
    final gen = _generation;
    final at = _slide.value.round().clamp(0, _n - 1);
    Future<bool> pause() async {
      await Future<void>.delayed(const Duration(milliseconds: 24));
      return mounted && gen == _generation;
    }

    for (var d = 0; d < _n; d++) {
      for (final i in {at + d, at - d - 1}) {
        if (i < 0 || i >= _n) continue;
        if (!await pause()) return;
        _stoneAt(i);
        if (i + 1 < _n) _pairAt(i);
      }
    }
  }

  void _onSlide() {
    final p = _slide.value;
    _ticks(_prev, p);
    _prev = p;
    if (_n == 0) return;
    final near = p.round().clamp(0, _n - 1);
    if (near != _nearest.value) _nearest.value = near;
    _publish(p);
  }

  /// Shows the stone at slider position [p]: at a stop, that cut; between
  /// stops, the one stone partway from one cut to the next. Eased so the
  /// shape holds near each stop and changes most between them.
  void _publish(double p) {
    if (_n == 0 || _base == null) return;
    final q = p.clamp(0.0, _n - 1.0);
    final i = q.floor();
    final f = q - i;
    if (f < 1e-4 || f > 1 - 1e-4 || i >= _n - 1) {
      widget.viewport.morph.value = SimMorphFrame.still(
        _stoneAt(math.min(f < 0.5 ? i : i + 1, _n - 1)),
      );
      return;
    }
    widget.viewport.morph.value = SimMorphFrame(
      from: _stoneAt(i),
      to: _stoneAt(i + 1),
      t: f * f * (3 - 2 * f),
      morph: _pairAt(i),
    );
  }

  /// A detent felt and heard at every stop crossed; many in one frame (a
  /// fast flick) sound once, and rocking back over the same stop is
  /// silent.
  void _ticks(double prev, double cur) {
    final a = prev.floor(), b = cur.floor();
    if (a == b) return;
    final stop = b > a ? b : b + 1;
    if (stop == _stop) return;
    _stop = stop;
    if (stop < 0 || stop >= _n) return;
    AppHaptics.detent();
    DialSounds.detent();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final k = _slide.value.round();
    if ((_slide.value - k).abs() > 1e-3) return;
    if (_slide.value != k) _slide.value = k.toDouble();
    if (_closing) widget.onDone();
  }

  void _settleTo(double target, double velocity) {
    if (_n == 0) return;
    final to = target.roundToDouble().clamp(0.0, _n - 1.0);
    _slide.animateWith(SpringSimulation(_spring, _slide.value, to, velocity));
  }

  void _onDragStart(DragStartDetails d) => _slide.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    if (_n == 0) return;
    var step = -d.delta.dx / SimFancyShapeSlider.spacing;
    // Past either end the slider gives, heavily.
    final p = _slide.value;
    if ((p <= 0 && step < 0) || (p >= _n - 1 && step > 0)) step *= 0.3;
    _slide.value = p + step;
  }

  void _onDragEnd(DragEndDetails d) {
    final speed = (-d.velocity.pixelsPerSecond.dx / SimFancyShapeSlider.spacing)
        .clamp(-30.0, 30.0);
    _settleTo(_slide.value + speed * 0.22, speed);
  }

  void _stepBy(int stops) => _settleTo(_slide.value.roundToDouble() + stops, 0);

  void _done() {
    if (_slide.isAnimating) {
      _closing = true;
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    // A stone changed elsewhere (a reset, its colour): take it on.
    ref.listen(diamondSimulatorProvider, (_, next) {
      if (_n > 0) _rebase(next);
    });
    final p = LuxePalette.of(context);
    const track = SimFancyShapeSlider.track;
    final doneBottom = widget.bottomInset + 14;
    final trackBottom = doneBottom + 40 + 8;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Keeps the shapes legible over the stage.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: trackBottom + track + 56,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x99000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        // The centred shape's name above the slider.
        Positioned(
          left: 16,
          right: 16,
          bottom: trackBottom + track + 4,
          child: IgnorePointer(
            child: ValueListenableBuilder<int>(
              valueListenable: _nearest,
              builder: (context, i, _) => AnimatedSwitcher(
                duration: LuxeMotion.fast,
                child: Text(
                  _n == 0 ? '' : context.fancyShapeName(_shapes[i]),
                  key: ValueKey(i),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(20, p.ink),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: trackBottom,
          height: track,
          child: _Entrance(
            child: ValueListenableBuilder<int>(
              valueListenable: _nearest,
              builder: (context, i, child) => Semantics(
                label: context.tr(EducationL10n.fancyShapes),
                value: _n == 0 ? null : context.fancyShapeName(_shapes[i]),
                increasedValue: i + 1 < _n
                    ? context.fancyShapeName(_shapes[i + 1])
                    : null,
                decreasedValue: i > 0
                    ? context.fancyShapeName(_shapes[i - 1])
                    : null,
                onIncrease: i + 1 < _n ? () => _stepBy(1) : null,
                onDecrease: i > 0 ? () => _stepBy(-1) : null,
                child: child,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: _n == 0
                    ? Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.accent,
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, c) => RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _slide,
                            builder: (context, _) =>
                                _strip(p, c.maxWidth, track),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: doneBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimGlassPill(
                label: context.tr(EducationL10n.done),
                selected: true,
                palette: p,
                height: 40,
                onTap: _done,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The shapes along the track, the centred one largest and in the
  /// accent, the rest smaller and fainter toward the edges.
  Widget _strip(LuxePalette p, double width, double height) {
    const spacing = SimFancyShapeSlider.spacing;
    final pos = _slide.value;
    final cx = width / 2, cy = height / 2;
    final reach = (width / 2 / spacing).ceil() + 1;
    final first = math.max(0, (pos - reach).floor());
    final last = math.min(_n - 1, (pos + reach).ceil());
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The window the centred shape sits in.
        Positioned(
          left: cx - 34,
          top: cy - 34,
          width: 68,
          height: 68,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accent.withValues(alpha: 0.14),
              border: Border.all(color: p.accent.withValues(alpha: 0.5)),
            ),
          ),
        ),
        for (var i = first; i <= last; i++)
          () {
            final rel = i - pos;
            final x = cx + rel * spacing;
            final near = (1 - rel.abs()).clamp(0.0, 1.0);
            final size = 28 + 20 * near;
            // Fades toward the screen's edges.
            final edge = ((x - cx).abs() / (width / 2)).clamp(0.0, 1.0);
            final fade = 1 - edge * edge * 0.85;
            final color = Color.lerp(
              p.ink.withValues(alpha: 0.6),
              p.accent,
              near,
            )!;
            return Positioned(
              left: x - size / 2,
              top: cy - size / 2,
              width: size,
              height: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _settleTo(i.toDouble(), 0),
                child: SvgPicture.asset(
                  _shapes[i].svgAsset,
                  colorFilter: ColorFilter.mode(
                    color.withValues(alpha: color.a * fade),
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (_) => const SizedBox.shrink(),
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// Fades and lifts the slider in when it opens.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: LuxeMotion.settle,
    child: child,
    builder: (context, v, child) => v >= 1
        ? child!
        : Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 18),
              child: child,
            ),
          ),
  );
}
