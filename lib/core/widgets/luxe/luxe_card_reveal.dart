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
/// While the list scrolls, cards assemble from the wide corners on
/// their side and retreat back out of view ([LuxeScrollAssemble]).
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
      child: _AssembleTarget(
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


/// Scroll-scrubbed corner assembly for the [LuxeCardReveal] cards below it.
///
/// Every card's pose follows its place on screen, so the motion tracks the
/// finger exactly and runs backwards when the list scrolls the other way:
/// * entering at the bottom, each card flies in from the wide bottom corner
///   on its own side (left column from bottom-left, right column from
///   bottom-right), starting pushed deep into the screen, turned so its
///   inner, centre-facing edge leans away and tipped back, then comes
///   forward and settles flat into its cell,
/// * leaving under the top, it lifts back out the same way toward the top
///   corner on its side, a little softer so the rows above stay readable.
///
/// Scrolling up replays both in reverse: cards near the bottom disassemble
/// and retreat to their corners, cards coming back in at the top assemble.
/// Full-width list cards keep the depth and tilt with no sideways throw.
class LuxeScrollAssemble extends StatefulWidget {
  const LuxeScrollAssemble({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<LuxeScrollAssemble> createState() => _LuxeScrollAssembleState();
}

/// Pings the cards on every scroll and tells them where the viewport is.
class _AssembleSignal extends ChangeNotifier {
  _AssembleSignal(this._viewportOf);

  final Rect Function() _viewportOf;

  Rect get viewport => _viewportOf();

  void ping() => notifyListeners();
}

class _LuxeScrollAssembleState extends State<LuxeScrollAssemble> {
  late final _signal = _AssembleSignal(_viewport);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_signal.ping);
  }

  @override
  void didUpdateWidget(LuxeScrollAssemble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_signal.ping);
      widget.controller.addListener(_signal.ping);
    }
  }

  Rect _viewport() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return Rect.zero;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_signal.ping);
    _signal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AssembleScope(signal: _signal, child: widget.child);
}

class _AssembleScope extends InheritedWidget {
  const _AssembleScope({required this.signal, required super.child});

  final _AssembleSignal signal;

  @override
  bool updateShouldNotify(_AssembleScope oldWidget) =>
      oldWidget.signal != signal;
}

class _AssembleTarget extends SingleChildRenderObjectWidget {
  const _AssembleTarget({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAssemble(
    context.dependOnInheritedWidgetOfExactType<_AssembleScope>()?.signal,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderAssemble renderObject) {
    renderObject.signal = context
        .dependOnInheritedWidgetOfExactType<_AssembleScope>()
        ?.signal;
  }
}

/// Poses its child for [LuxeScrollAssemble] from its place in the viewport.
class _RenderAssemble extends RenderProxyBox {
  _RenderAssemble(this._signal);

  /// Pinned listing toolbar the cards slide under.
  static const _topInset = 56.0;

  /// Viewport share a card travels past the bottom edge before it lands.
  static const _enterTail = 0.14;

  /// Card heights over which a card lifts out under the top.
  static const _leaveSpan = 0.8;

  /// Exit strength relative to the entrance.
  static const _leaveAmount = 0.7;

  /// Sideways throw toward the corner, in viewport widths.
  static const _spread = 0.34;

  /// Vertical throw past the edge, in card heights.
  static const _drop = 0.55;

  /// Turn about the vertical axis, inner edge away (~41°).
  static const _yaw = 0.72;

  /// Tip about the horizontal axis, far edge away (~23°).
  static const _pitch = 0.4;

  /// Fan in the screen plane (~7°).
  static const _roll = 0.12;

  /// Push into the screen, in camera distances (~0.53x at full depth).
  static const _depth = 0.9;

  _AssembleSignal? _signal;
  final _layer = LayerHandle<TransformLayer>();

  set signal(_AssembleSignal? value) {
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

  @override
  void dispose() {
    _layer.layer = null;
    super.dispose();
  }

  /// Local → local projective pose, or null once the card sits in place.
  Matrix4? _pose() {
    final s = _signal;
    if (s == null || !hasSize || !attached) return null;
    final v = s.viewport;
    final w = size.width;
    final h = size.height;
    if (v.isEmpty || w <= 0 || h <= 0) return null;
    final g = localToGlobal(Offset.zero);

    // 0 = in its corner, 1 = in place; whichever edge is nearer wins.
    final enter = _saturate((v.bottom - g.dy) / (h + v.height * _enterTail));
    final leave = _saturate(
      (g.dy + h - (v.top + _topInset)) / (h * _leaveSpan),
    );
    final double amount;
    final double dir; // +1 toward the bottom corners, -1 toward the top.
    if (enter < 1) {
      amount = (1 - enter) * (1 - enter);
      dir = 1;
    } else if (leave < 1) {
      amount = (1 - leave) * (1 - leave) * _leaveAmount;
      dir = -1;
    } else {
      return null;
    }
    if (amount < 0.0005) return null;

    // -1 left column, +1 right column, 0 full-width row.
    final side = ((g.dx + w / 2 - v.center.dx) / (v.width / 4)).clamp(
      -1.0,
      1.0,
    );
    final camera = math.max(w, h) * 2;
    final cx = w / 2;
    final cy = h / 2;
    // Vanishing point on the screen's centre line, level with the card, so
    // the inner edges recede toward the middle of the grid.
    final px = v.center.dx - g.dx;
    final dx = side * amount * v.width * _spread;
    final dy = dir * amount * h * _drop;
    final dz = amount * camera * _depth;

    return Matrix4.translationValues(dx + px, dy + cy, 0)
      ..multiply(Matrix4.identity()..setEntry(3, 2, 1 / camera))
      ..multiply(Matrix4.translationValues(cx - px, 0, dz))
      ..multiply(Matrix4.rotationZ(side * dir * amount * _roll))
      ..multiply(Matrix4.rotationY(side * amount * _yaw))
      ..multiply(Matrix4.rotationX(-dir * amount * _pitch))
      ..multiply(Matrix4.translationValues(-cx, -cy, 0));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final m = _pose();
    if (m == null) {
      _layer.layer = null;
      super.paint(context, offset);
      return;
    }
    _layer.layer = context.pushTransform(
      needsCompositing,
      offset,
      m,
      super.paint,
      oldLayer: _layer.layer,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final m = _pose();
    if (m == null) return super.hitTestChildren(result, position: position);
    return result.addWithPaintTransform(
      transform: m,
      position: position,
      hitTest: (result, p) => super.hitTestChildren(result, position: p),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final m = _pose();
    if (m != null) transform.multiply(m);
  }
}
