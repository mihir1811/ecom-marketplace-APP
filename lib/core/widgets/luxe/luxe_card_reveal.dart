import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/luxe_tokens.dart';

/// Product-card scroll entrance modelled on the lusion.co work grid.
///
/// Each time a card scrolls into view (and again after it fully leaves):
/// * the card slides in from the grid centre with a slight tilt (2s expo-out),
/// * its media opens from a 70% rounded window while the image settles from
///   a 1.33x zoom (1.5s expo-out) — see [LuxeRevealMask] / [LuxeRevealZoom],
/// * the title rolls each letter down like a slot reel, centre letters first
///   — see [LuxeRollTitle],
/// * small text lines type in with scrambled characters — see
///   [LuxeScrambleText].
///
/// While the list scrolls, cards near the top and bottom of the screen
/// stretch sideways with scroll speed ([LuxeScrollRipple]).
class LuxeCardReveal extends StatefulWidget {
  const LuxeCardReveal({required this.index, required this.child, super.key});

  /// Position in the results; even items lean in from the right, odd from
  /// the left, like the two columns of the lusion grid.
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

  static const total = 2.0;

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
    final width = MediaQuery.sizeOf(context).width;
    // Left column starts nudged toward the centre and turned clockwise;
    // the right column mirrors it.
    final side = widget.index.isEven ? 1.0 : -1.0;
    return _ClockScope(
      clock: _clock,
      child: _RippleTarget(
        child: AnimatedBuilder(
          animation: _clock.animation,
          child: widget.child,
          builder: (context, child) {
            final rest = 1 - LuxeEase.expoOut(_clock.seconds / 2);
            return Transform.translate(
              offset: Offset(rest * side * width * 0.05, 0),
              child: Transform.rotate(angle: rest * side * 0.05, child: child),
            );
          },
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

/// Clips media to a centred rounded window that opens from 70% to full size.
class LuxeRevealMask extends StatelessWidget {
  const LuxeRevealMask({required this.radius, required this.child, super.key});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = LuxeCardReveal.clockOf(context);
    if (clock == null) return child;
    return AnimatedBuilder(
      animation: clock.animation,
      child: child,
      builder: (context, child) {
        final show = LuxeEase.expoOut(clock.seconds / 1.5);
        return ClipRRect(
          clipper: _CentredRRect(0.7 + 0.3 * show, radius),
          child: child,
        );
      },
    );
  }
}

class _CentredRRect extends CustomClipper<RRect> {
  const _CentredRRect(this.fraction, this.radius);

  final double fraction;
  final double radius;

  @override
  RRect getClip(Size size) => RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * fraction,
      height: size.height * fraction,
    ),
    Radius.circular(radius),
  );

  @override
  bool shouldReclip(_CentredRRect oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.radius != radius;
}

/// Settles media from a 1.33x zoom to rest while the mask opens.
class LuxeRevealZoom extends StatelessWidget {
  const LuxeRevealZoom({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clock = LuxeCardReveal.clockOf(context);
    if (clock == null) return child;
    return AnimatedBuilder(
      animation: clock.animation,
      child: child,
      builder: (context, child) {
        final show = LuxeEase.expoOut(clock.seconds / 1.5);
        return Transform.scale(scale: 1 / (0.75 + 0.25 * show), child: child);
      },
    );
  }
}

/// Small text line that types in at 40 characters a second, the newest few
/// shown as random glyphs.
class LuxeScrambleText extends StatelessWidget {
  const LuxeScrambleText(this.text, {required this.style, super.key});

  static const _lettersPerSecond = 40;
  static const _randomTail = 5;
  static final _random = math.Random();

  final String text;
  final TextStyle style;

  Text _text(String value) =>
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);

  @override
  Widget build(BuildContext context) {
    final clock = LuxeCardReveal.clockOf(context);
    if (clock == null) return _text(text);
    final chars = text.characters.toList();
    return AnimatedBuilder(
      animation: clock.animation,
      builder: (context, _) {
        final typed = (_lettersPerSecond * clock.seconds).floor();
        final settled = math.min(chars.length, typed - _randomTail);
        if (clock.done || settled >= chars.length) return _text(text);
        final shown = math.min(chars.length, typed);
        final b = StringBuffer();
        for (var i = 0; i < settled; i++) {
          b.write(chars[i]);
        }
        for (var i = math.max(0, settled); i < shown; i++) {
          b.writeCharCode(33 + _random.nextInt(93));
        }
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: _text(b.toString()),
        );
      },
    );
  }
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

/// One-line title whose letters roll down into place like a slot reel, and
/// which slides right behind an arrow while the card is hovered or pressed.
class LuxeRollTitle extends StatefulWidget {
  const LuxeRollTitle(this.text, {required this.style, super.key});

  final String text;
  final TextStyle style;

  @override
  State<LuxeRollTitle> createState() => _LuxeRollTitleState();
}

class _LuxeRollTitleState extends State<LuxeRollTitle>
    with SingleTickerProviderStateMixin {
  // Lusion's hover ratio moves at 2.5 per second.
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  _RollLayout? _layout;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LuxeCardActive.of(context)) {
      _hover.forward();
    } else {
      _hover.reverse();
    }
  }

  @override
  void dispose() {
    _hover.dispose();
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
    return AnimatedBuilder(
      animation: Listenable.merge([clock.animation, _hover]),
      builder: (context, _) {
        // Edge letters finish last, at 1 / 0.8 seconds.
        final rolled = clock.done || clock.seconds >= 1.25;
        if (rolled && _hover.value == 0) return _plain;
        return LayoutBuilder(
          builder: (context, constraints) {
            final layout = _layoutFor(context, constraints.maxWidth);
            return Semantics(
              label: widget.text,
              excludeSemantics: true,
              child: CustomPaint(
                size: Size(
                  constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : layout.painter.width + layout.em * 1.5,
                  layout.painter.height,
                ),
                painter: _RollPainter(
                  layout: layout,
                  seconds: rolled ? double.infinity : clock.seconds,
                  hover: _hover.value,
                  color: layout.style.color ?? const Color(0xFF000000),
                ),
              ),
            );
          },
        );
      },
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
  _RollPainter({
    required this.layout,
    required this.seconds,
    required this.hover,
    required this.color,
  });

  final _RollLayout layout;
  final double seconds;
  final double hover;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = layout.painter;
    final em = layout.em;
    final line = tp.height;
    final shiftT = LuxeMotion.settle.transform(hover);
    final iconT = LuxeMotion.settle.transform(_saturate((hover - 0.3) / 0.7));
    final shift = 1.5 * em * shiftT;

    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.width, size.height));

    if (hover > 0) _paintArrow(canvas, em, line, -em + em * iconT);

    final n = layout.columns.length;
    if (seconds.isInfinite) {
      tp.paint(canvas, Offset(shift, 0));
    } else {
      for (var f = 0; f < n; f++) {
        final p = n == 1 ? math.pi : math.pi / 2 + math.pi * f / (n - 1);
        final g = _saturate(seconds * 0.8 - math.cos(p) / 20);
        // Reel of four copies, starting five reel heights above.
        final reel = 5 * (1 - LuxeEase.expoInOut(g));
        final dy = -reel * 4 * line;
        final (l, r) = layout.columns[f];
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(l + shift, 0, r + shift, line));
        for (var k = 0; k < 4; k++) {
          final y = dy + k * line;
          if (y > -line && y < line) tp.paint(canvas, Offset(shift, y));
        }
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _paintArrow(Canvas canvas, double em, double line, double x) {
    final s = em * 0.8;
    final top = (line - s) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, em * 0.07)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final midY = top + s / 2;
    canvas.drawLine(Offset(x, midY), Offset(x + s, midY), paint);
    canvas.drawPath(
      Path()
        ..moveTo(x + s * 0.55, top + s * 0.1)
        ..lineTo(x + s, midY)
        ..lineTo(x + s * 0.55, top + s * 0.9),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RollPainter old) =>
      old.layout != layout ||
      old.seconds != seconds ||
      old.hover != hover ||
      old.color != color;
}

/// Measures scroll speed for [LuxeCardReveal] cards below it, which stretch
/// sideways near the screen edges while the list moves.
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

class _LuxeScrollRippleState extends State<LuxeScrollRipple>
    with SingleTickerProviderStateMixin {
  final _strength = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double? _lastPixels;
  double _eased = 0;

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

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final c = widget.controller;
    if (!c.hasClients || c.positions.length != 1) return;
    final pos = c.position;
    final pixels = pos.pixels;
    final vh = pos.viewportDimension <= 0 ? 1.0 : pos.viewportDimension;
    final delta = _lastPixels == null ? 0.0 : (pixels - _lastPixels!).abs();
    _lastPixels = pixels;
    // Viewport heights per second; a hard fling (~4 vh/s) maxes out.
    final speed = dt <= 0 ? 0.0 : delta / vh / dt;
    final target = speed / 12;
    _eased += (target - _eased) * (1 - math.exp(-dt * 10));
    _strength.value = math.min(0.15, _eased * 0.5);
    if (target == 0 && _eased < 0.002) {
      _eased = 0;
      _strength.value = 0;
      _lastPixels = null;
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _ticker.dispose();
    _strength.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RippleScope(strength: _strength, child: widget.child);
}

class _RippleScope extends InheritedWidget {
  const _RippleScope({required this.strength, required super.child});

  final ValueListenable<double> strength;

  @override
  bool updateShouldNotify(_RippleScope oldWidget) =>
      oldWidget.strength != strength;
}

class _RippleTarget extends SingleChildRenderObjectWidget {
  const _RippleTarget({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderRipple(
    context.dependOnInheritedWidgetOfExactType<_RippleScope>()?.strength,
    MediaQuery.sizeOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRipple renderObject) {
    renderObject
      ..strength = context
          .dependOnInheritedWidgetOfExactType<_RippleScope>()
          ?.strength
      ..screen = MediaQuery.sizeOf(context);
  }
}

/// Stretches its child horizontally about the screen centre by
/// `1 / (1 - r * (1 - sin(pi * y)))`, lusion's scroll ripple sampled at the
/// card's centre.
class _RenderRipple extends RenderProxyBox {
  _RenderRipple(this._strength, this.screen);

  ValueListenable<double>? _strength;
  Size screen;

  set strength(ValueListenable<double>? value) {
    if (value == _strength) return;
    if (attached) {
      _strength?.removeListener(markNeedsPaint);
      value?.addListener(markNeedsPaint);
    }
    _strength = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _strength?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _strength?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final r = _strength?.value ?? 0;
    if (r <= 0.0005 || screen.height <= 0) {
      super.paint(context, offset);
      return;
    }
    final global = localToGlobal(Offset.zero);
    final y = _saturate((global.dy + size.height / 2) / screen.height);
    final k = r * (1 - math.sin(math.pi * y));
    final pivot = screen.width / 2 - global.dx;
    final matrix = Matrix4.identity()
      ..translateByDouble(pivot, 0, 0, 1)
      ..scaleByDouble(1 / (1 - k), 1, 1, 1)
      ..translateByDouble(-pivot, 0, 0, 1);
    context.pushTransform(needsCompositing, offset, matrix, super.paint);
  }
}
