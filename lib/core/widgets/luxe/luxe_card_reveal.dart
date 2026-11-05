import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/luxe_tokens.dart';

/// Product-card scroll entrance modelled on the lusion.co work grid.
///
/// Each time a card scrolls into view (and again after it fully leaves):
/// * the whole card opens from a centred 70% rounded window while its
///   content settles from a 1.33x zoom (1.5s expo-out); the clip keeps it
///   inside its own cell,
/// * the title rolls each letter down like a slot reel, centre letters first
///   — see [LuxeRollTitle],
/// * small text lines type in with scrambled characters — see
///   [LuxeScrambleText].
///
/// While the list scrolls, the screen folds into a drum ([LuxeScrollRipple]):
/// cards rise from the near bottom edge, sink to the centre and lift out
/// toward the viewer at the top.
class LuxeCardReveal extends StatefulWidget {
  const LuxeCardReveal({required this.index, required this.child, super.key});

  /// Position in the results.
  final int index;
  final Widget child;

  /// Reveal clock of the enclosing card, or null outside a reveal.
  static LuxeRevealClock? clockOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ClockScope>()?.clock;

  @override
  State<LuxeCardReveal> createState() => _LuxeCardRevealState();
}

/// Elapsed time of one card's entrance.
class LuxeRevealClock {
  LuxeRevealClock._(this.animation);

  /// Longest effect: the window / zoom (1.5s).
  static const total = 1.5;

  /// Drives listeners every frame of the entrance.
  final AnimationController animation;

  double get seconds => animation.value * total;
  bool get done => animation.isCompleted;
}

class _LuxeCardRevealState extends State<LuxeCardReveal>
    with SingleTickerProviderStateMixin {
  late final LuxeRevealClock _clock = LuxeRevealClock._(
    AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (LuxeRevealClock.total * 1000).round()),
    ),
  );
  ScrollPosition? _position;
  bool _checkScheduled = false;
  bool _playing = false;
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _clock.animation.value = 1;
      return;
    }
    var scrollable = Scrollable.maybeOf(context);
    while (scrollable != null &&
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    final next = scrollable?.position;
    if (next != _position) {
      _position?.removeListener(_scheduleCheck);
      _position = next;
      _position?.addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _check() {
    if (!mounted || _reduced) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final viewport = _position?.context.notificationContext?.findRenderObject();
    double top = 0;
    var bottom = MediaQuery.sizeOf(context).height;
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      top = viewport.localToGlobal(Offset.zero).dy;
      bottom = top + viewport.size.height;
    }
    final y = box.localToGlobal(Offset.zero).dy;
    final visible = y + box.size.height > top && y < bottom;
    if (visible && !_playing) {
      _playing = true;
      _clock.animation.forward(from: 0);
    } else if (!visible && _playing) {
      // Fully off screen: rewind so the next pass plays again.
      _playing = false;
      _clock.animation.value = 0;
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _clock.animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) return widget.child;
    // The window and zoom run in paint only: no widget rebuilds per frame,
    // and the boundary lets the card's raster be reused while it animates.
    return _ClockScope(
      clock: _clock,
      child: _RippleTarget(
        child: _RevealWindow(
          animation: _clock.animation,
          child: RepaintBoundary(child: widget.child),
        ),
      ),
    );
  }
}

class _ClockScope extends InheritedWidget {
  const _ClockScope({required this.clock, required super.child});

  final LuxeRevealClock clock;

  @override
  bool updateShouldNotify(_ClockScope oldWidget) => oldWidget.clock != clock;
}

/// Lusion easing curves.
abstract final class LuxeEase {
  static double expoOut(double t) =>
      t >= 1 ? 1 : (t <= 0 ? 0 : 1 - math.pow(2, -10 * t).toDouble());

  static double expoInOut(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return t < 0.5
        ? math.pow(2, 20 * t - 10) / 2
        : (2 - math.pow(2, -20 * t + 10)) / 2;
  }
}

double _saturate(double v) => v.clamp(0.0, 1.0);

class _RevealWindow extends SingleChildRenderObjectWidget {
  const _RevealWindow({required this.animation, required Widget super.child});

  final Animation<double> animation;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRevealWindow(animation);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRevealWindow renderObject,
  ) => renderObject.animation = animation;
}

/// Clips the card to a centred rounded window opening from 70% to full size
/// while the content settles from a 1.33x zoom about its centre.
class _RenderRevealWindow extends RenderProxyBox {
  _RenderRevealWindow(this._animation);

  static const _duration = 1.5;
  static const _radius = Radius.circular(LuxeSpace.cardRadius);

  Animation<double> _animation;

  set animation(Animation<double> value) {
    if (value == _animation) return;
    if (attached) {
      _animation.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _animation = value;
    markNeedsPaint();
  }

  final _clip = LayerHandle<ClipRRectLayer>();
  final _transform = LayerHandle<TransformLayer>();

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _clip.layer = null;
    _transform.layer = null;
    super.dispose();
  }

  double get _show =>
      LuxeEase.expoOut(_animation.value * LuxeRevealClock.total / _duration);

  /// Scale about the centre, or null once settled.
  Matrix4? _zoom() {
    final show = _show;
    if (show >= 0.999 || !hasSize) return null;
    final z = 1 / (0.75 + 0.25 * show);
    final c = size.center(Offset.zero);
    return Matrix4.diagonal3Values(z, z, 1)
      ..setTranslationRaw(c.dx * (1 - z), c.dy * (1 - z), 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final show = _show;
    if (show >= 0.999) {
      _clip.layer = null;
      _transform.layer = null;
      context.paintChild(child, offset);
      return;
    }
    final f = 0.7 + 0.3 * show;
    final window = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * f,
        height: size.height * f,
      ),
      _radius,
    );
    final zoom = _zoom()!;
    _clip.layer = context.pushClipRRect(
      needsCompositing,
      offset,
      window.outerRect,
      window,
      (context, offset) {
        _transform.layer = context.pushTransform(
          needsCompositing,
          offset,
          zoom,
          (context, offset) => context.paintChild(child, offset),
          oldLayer: _transform.layer,
        );
      },
      oldLayer: _clip.layer,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final m = _zoom();
    if (m == null) return super.hitTestChildren(result, position: position);
    return result.addWithPaintTransform(
      transform: m,
      position: position,
      hitTest: (result, p) => super.hitTestChildren(result, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final m = _zoom();
    if (m != null) transform.multiply(m);
  }
}

/// Small text line that types in at 40 characters a second, the newest few
/// shown as random glyphs.
///
/// The final text keeps the layout (hidden while typing) and the typing is
/// painted over it on its own layer straight from the clock, so the card
/// never relays out or repaints for it. The widget rebuilds only when typing
/// starts or ends.
class LuxeScrambleText extends StatefulWidget {
  const LuxeScrambleText(this.text, {required this.style, super.key});

  final String text;
  final TextStyle style;

  @override
  State<LuxeScrambleText> createState() => _LuxeScrambleTextState();
}

class _LuxeScrambleTextState extends State<LuxeScrambleText> {
  LuxeRevealClock? _clock;
  late _ScrambleTyping _typing;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _typing = _ScrambleTyping(widget.text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = LuxeCardReveal.clockOf(context);
    if (next != _clock) {
      _clock?.animation.removeListener(_tick);
      _clock = next;
      _clock?.animation.addListener(_tick);
    }
    _animating = _typing.animating(_clock);
  }

  @override
  void didUpdateWidget(LuxeScrambleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _typing.dispose();
      _typing = _ScrambleTyping(widget.text);
      _animating = _typing.animating(_clock);
    }
  }

  @override
  void dispose() {
    _clock?.animation.removeListener(_tick);
    _typing.dispose();
    super.dispose();
  }

  void _tick() {
    final next = _typing.animating(_clock);
    if (next != _animating) setState(() => _animating = next);
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
    final clock = _clock;
    if (clock == null) return text;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _animating
            ? _ScramblePainter(
                typing: _typing,
                clock: clock,
                style: DefaultTextStyle.of(context).style.merge(widget.style),
                scaler: MediaQuery.textScalerOf(context),
                direction: Directionality.of(context),
              )
            : null,
        child: Opacity(
          opacity: _animating ? 0 : 1,
          alwaysIncludeSemantics: true,
          child: text,
        ),
      ),
    );
  }
}

/// Typing state of one line, shared by its painter across frames.
class _ScrambleTyping {
  _ScrambleTyping(this.text) : chars = text.characters.toList();

  static const _lettersPerSecond = 40;
  static const _randomTail = 5;
  static final _random = math.Random();

  final String text;
  final List<String> chars;
  TextPainter? _painter;
  int _typed = -1;

  int typedAt(LuxeRevealClock clock) =>
      (_lettersPerSecond * clock.seconds).floor();

  bool animating(LuxeRevealClock? clock) =>
      clock != null &&
      !clock.done &&
      typedAt(clock) - _randomTail < chars.length;

  /// Painter for the current typed count; rebuilt only when it moves.
  TextPainter painterFor(
    int typed,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final cached = _painter;
    if (cached != null && typed == _typed) return cached;
    _typed = typed;
    final settled = math.min(chars.length, typed - _randomTail);
    final shown = math.min(chars.length, typed);
    final b = StringBuffer();
    for (var i = 0; i < settled; i++) {
      b.write(chars[i]);
    }
    for (var i = math.max(0, settled); i < shown; i++) {
      b.writeCharCode(33 + _random.nextInt(93));
    }
    cached?.dispose();
    return _painter = TextPainter(
      text: TextSpan(text: b.toString(), style: style),
      maxLines: 1,
      textDirection: direction,
      textScaler: scaler,
    )..layout();
  }

  void dispose() {
    _painter?.dispose();
    _painter = null;
  }
}

class _ScramblePainter extends CustomPainter {
  _ScramblePainter({
    required this.typing,
    required this.clock,
    required this.style,
    required this.scaler,
    required this.direction,
  }) : super(repaint: clock.animation);

  final _ScrambleTyping typing;
  final LuxeRevealClock clock;
  final TextStyle style;
  final TextScaler scaler;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final typed = typing.typedAt(clock);
    if (typed <= 0) return;
    // Random glyphs can run wider than the final text: clip to its box.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    typing
        .painterFor(typed, style, scaler, direction)
        .paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScramblePainter old) =>
      old.typing != typing ||
      old.clock != clock ||
      old.style != style ||
      old.scaler != scaler ||
      old.direction != direction;
}

/// Card hover / press state published by the card frame.
class LuxeCardActive extends InheritedWidget {
  const LuxeCardActive({required this.active, required super.child, super.key});

  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LuxeCardActive>()?.active ??
      false;

  @override
  bool updateShouldNotify(LuxeCardActive oldWidget) =>
      oldWidget.active != active;
}

/// One-line title whose letters roll down into place like a slot reel.
class LuxeRollTitle extends StatefulWidget {
  const LuxeRollTitle(this.text, {required this.style, super.key});

  final String text;
  final TextStyle style;

  @override
  State<LuxeRollTitle> createState() => _LuxeRollTitleState();
}

class _LuxeRollTitleState extends State<LuxeRollTitle> {
  _RollLayout? _layout;

  @override
  void dispose() {
    _layout?.painter.dispose();
    super.dispose();
  }

  Text get _plain => Text(
    widget.text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );

  _RollLayout _layoutFor(BuildContext context, double maxWidth) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final heightBehavior = DefaultTextHeightBehavior.maybeOf(context);
    final cached = _layout;
    if (cached != null &&
        cached.text == widget.text &&
        cached.style == style &&
        cached.maxWidth == maxWidth &&
        cached.scaler == scaler &&
        cached.direction == direction) {
      return cached;
    }
    cached?.painter.dispose();
    return _layout = _RollLayout(
      text: widget.text,
      style: style,
      maxWidth: maxWidth,
      scaler: scaler,
      direction: direction,
      heightBehavior: heightBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clock = LuxeCardReveal.clockOf(context);
    if (clock == null) return _plain;
    // Painted straight from the clock: no rebuild or relayout per frame, and
    // its own layer so the rolling letters never repaint the rest of the card.
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _layoutFor(context, constraints.maxWidth);
            return CustomPaint(
              size: Size(
                constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : layout.painter.width,
                layout.painter.height,
              ),
              painter: _RollPainter(layout: layout, clock: clock),
            );
          },
        ),
      ),
    );
  }
}

class _RollLayout {
  _RollLayout({
    required this.text,
    required this.style,
    required this.maxWidth,
    required this.scaler,
    required this.direction,
    required TextHeightBehavior? heightBehavior,
  }) : painter = TextPainter(
         text: TextSpan(text: text, style: style),
         maxLines: 1,
         ellipsis: '…',
         textDirection: direction,
         textScaler: scaler,
         textHeightBehavior: heightBehavior,
       )..layout(maxWidth: maxWidth.isFinite ? maxWidth : double.infinity) {
    em = scaler.scale(style.fontSize ?? 14);
    // One column per visible glyph, tiling the line so settled letters
    // join seamlessly; a trailing column carries the ellipsis.
    var offset = 0;
    var left = 0.0;
    for (final ch in text.characters) {
      final end = offset + ch.length;
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: end),
      );
      offset = end;
      if (boxes.isEmpty) continue;
      final right = boxes.map((b) => b.right).reduce(math.max);
      if (right <= left) continue;
      columns.add((left, right));
      left = right;
    }
    if (painter.width - left > 0.5 || columns.isEmpty) {
      columns.add((left, painter.width));
    }
  }

  final String text;
  final TextStyle style;
  final double maxWidth;
  final TextScaler scaler;
  final TextDirection direction;
  final TextPainter painter;
  final columns = <(double, double)>[];
  late final double em;
}

class _RollPainter extends CustomPainter {
  _RollPainter({required this.layout, required this.clock})
    : super(repaint: clock.animation);

  /// Edge letters finish last, at 1 / 0.8 seconds.
  static const _end = 1.25;

  final _RollLayout layout;
  final LuxeRevealClock clock;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = layout.painter;
    final line = tp.height;
    final seconds = clock.seconds;
    if (clock.done || seconds >= _end) {
      tp.paint(canvas, Offset.zero);
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.width, size.height));
    final n = layout.columns.length;
    for (var f = 0; f < n; f++) {
      final p = n == 1 ? math.pi : math.pi / 2 + math.pi * f / (n - 1);
      final g = _saturate(seconds * 0.8 - math.cos(p) / 20);
      // Reel of four copies, starting five reel heights above.
      final reel = 5 * (1 - LuxeEase.expoInOut(g));
      final dy = -reel * 4 * line;
      final (l, r) = layout.columns[f];
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(l, 0, r, line));
      for (var k = 0; k < 4; k++) {
        final y = dy + k * line;
        if (y > -line && y < line) tp.paint(canvas, Offset(0, y));
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RollPainter old) =>
      old.layout != layout || old.clock != clock;
}

/// Folds the screen into a concave drum while the list scrolls, for the
/// [LuxeCardReveal] cards below it.
///
/// The viewport is wrapped onto the inside of a horizontal cylinder seen
/// through one perspective camera at the viewport centre (the
/// scroll-velocity bend used by WebGL galleries such as lusion.co, done on
/// the CPU per card). Cards entering at the bottom start near the viewer and
/// sink into the screen toward the centre; past the centre they lift back
/// toward the viewer and leave over the top edge.
///
/// Each card is laid on the chord between the drum points of its own top and
/// bottom edge, and every card shares the same camera, so neighbours in a
/// row stay apart sideways and rows never cross.
///
/// Scroll speed is smoothed and mapped through a soft curve: a slow drag
/// already folds the screen about half way, a fling folds it fully. The fold
/// rises in ~0.15s and relaxes over ~1s after the list stops.
class LuxeScrollRipple extends StatefulWidget {
  const LuxeScrollRipple({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<LuxeScrollRipple> createState() => _LuxeScrollRippleState();
}

/// Fold amount and viewport rectangle published to the cards each frame.
class _FoldSignal extends ChangeNotifier {
  double bend = 0;
  Rect viewport = Rect.zero;

  void update(double nextBend, Rect nextViewport) {
    bend = nextBend;
    viewport = nextViewport;
    notifyListeners();
  }
}

class _LuxeScrollRippleState extends State<LuxeScrollRipple>
    with SingleTickerProviderStateMixin {
  // Viewport heights per second at which the fold reaches ~63%.
  static const _speedScale = 0.4;
  static const _speedSmoothing = 0.08;
  static const _riseTime = 0.12;
  static const _relaxTime = 0.32;

  final _signal = _FoldSignal();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double? _lastPixels;
  double _speed = 0;
  double _bend = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(LuxeScrollRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (!_ticker.isActive && !MediaQuery.disableAnimationsOf(context)) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  Rect _viewport() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(1 / 240, 1 / 20);
    _last = elapsed;
    final c = widget.controller;
    if (!c.hasClients || c.positions.length != 1) return;
    final pos = c.position;
    final pixels = pos.pixels;
    final vh = pos.viewportDimension <= 0 ? 1.0 : pos.viewportDimension;
    final delta = _lastPixels == null ? 0.0 : (pixels - _lastPixels!).abs();
    _lastPixels = pixels;

    final raw = delta / vh / dt;
    _speed += (raw - _speed) * (1 - math.exp(-dt / _speedSmoothing));
    final target = 1 - math.exp(-_speed / _speedScale);
    final tau = target > _bend ? _riseTime : _relaxTime;
    _bend += (target - _bend) * (1 - math.exp(-dt / tau));

    if (raw == 0 && _speed < 0.01 && _bend < 0.002) {
      _speed = 0;
      _bend = 0;
      _lastPixels = null;
      _signal.update(0, _viewport());
      _ticker.stop();
      return;
    }
    _signal.update(_bend, _viewport());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _ticker.dispose();
    _signal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RippleScope(signal: _signal, child: widget.child);
}

class _RippleScope extends InheritedWidget {
  const _RippleScope({required this.signal, required super.child});

  final _FoldSignal signal;

  @override
  bool updateShouldNotify(_RippleScope oldWidget) => oldWidget.signal != signal;
}

class _RippleTarget extends SingleChildRenderObjectWidget {
  const _RippleTarget({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFold(
    context.dependOnInheritedWidgetOfExactType<_RippleScope>()?.signal,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderFold renderObject) {
    renderObject.signal = context
        .dependOnInheritedWidgetOfExactType<_RippleScope>()
        ?.signal;
  }
}

/// Lays its child on the drum described by [LuxeScrollRipple].
class _RenderFold extends RenderProxyBox {
  _RenderFold(this._signal);

  /// Drum angle at the viewport edges at full fold (~34°).
  static const _edgeAngle = 0.6;

  /// Camera distance in viewport heights; sets how strongly near edges grow.
  static const _camera = 2.0;

  _FoldSignal? _signal;

  set signal(_FoldSignal? value) {
    if (value == _signal) return;
    if (attached) {
      _signal?.removeListener(markNeedsPaint);
      value?.addListener(markNeedsPaint);
    }
    _signal = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _signal?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _signal?.removeListener(markNeedsPaint);
    super.detach();
  }

  /// Local → local projective transform, or null while the screen is flat.
  Matrix4? _fold() {
    final s = _signal;
    if (s == null || s.bend <= 0.001 || !hasSize || !attached) return null;
    final v = s.viewport;
    final h = size.height;
    if (v.isEmpty || h <= 0) return null;

    final half = v.height / 2;
    final cx = v.center.dx;
    final cy = v.center.dy;
    final radius = half / (_edgeAngle * s.bend);
    final camera = v.height * _camera;
    final g = localToGlobal(Offset.zero);

    // Screen row → point on the drum (height from centre, depth toward the
    // viewer); arc length equals the flat distance from the centre.
    (double, double) drum(double y) {
      final phi = ((y - cy) / radius).clamp(-1.45, 1.45);
      return (radius * math.sin(phi), radius * (1 - math.cos(phi)));
    }

    final (y0, z0) = drum(g.dy);
    final (y1, z1) = drum(g.dy + h);
    // Homogeneous w = 1 - depth / camera along the card's chord.
    final w0 = 1 - z0 / camera;
    final wy = -(z1 - z0) / (camera * h);
    final ox = cx - g.dx;
    final oy = cy - g.dy;
    // Column-major.
    return Matrix4(
      1,
      0,
      0,
      0, //
      ox * wy,
      oy * wy + (y1 - y0) / h,
      0,
      wy, //
      0,
      0,
      1,
      0, //
      ox * w0 - ox,
      oy * w0 + y0,
      0,
      w0, //
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final m = _fold();
    if (m == null) {
      super.paint(context, offset);
      return;
    }
    context.pushTransform(needsCompositing, offset, m, super.paint);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final m = _fold();
    if (m == null) return super.hitTestChildren(result, position: position);
    return result.addWithPaintTransform(
      transform: m,
      position: position,
      hitTest: (result, p) => super.hitTestChildren(result, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final m = _fold();
    if (m != null) transform.multiply(m);
  }
}
