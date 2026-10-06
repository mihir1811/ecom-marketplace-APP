import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'atelier_theme.dart';

/// Fades and lifts [child] in once, staggered by [index].
///
/// Honours the platform "reduce motion" setting.
class Reveal extends StatelessWidget {
  const Reveal({
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = 14,
    this.horizontal = false,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final double offset;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    final wait = delay + AtelierMotion.stagger * index.clamp(0, 10);
    final animated = child
        .animate(delay: wait)
        .fadeIn(duration: 420.ms, curve: AtelierMotion.emphasized);
    return horizontal
        ? animated.moveX(
            begin: offset,
            end: 0,
            duration: 520.ms,
            curve: AtelierMotion.emphasized,
          )
        : animated.moveY(
            begin: offset,
            end: 0,
            duration: 520.ms,
            curve: AtelierMotion.emphasized,
          );
  }
}

/// Tap target that sinks slightly under the finger and springs back.
///
/// Replaces ink ripples across the workspace for a calmer, tactile feel.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.haptic = true,
    this.semanticLabel,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  /// Shape of the keyboard-focus ring.
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _set(bool down) {
    if (_down == down || !mounted) return;
    setState(() => _down = down);
  }

  void _activate() {
    if (widget.onTap == null) return;
    if (widget.haptic) AppHaptics.selection();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final scale = _down ? widget.scale : (_hover ? 1.006 : 1.0);
    Widget body = AnimatedScale(
      scale: _enabled ? scale : 1,
      duration: _down ? const Duration(milliseconds: 90) : AtelierMotion.base,
      curve: _down ? Curves.easeOut : AtelierMotion.settle,
      child: widget.child,
    );
    if (_focused) {
      body = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.gold, width: 2),
        ),
        child: body,
      );
    }
    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _set(true) : null,
          onTapUp: _enabled ? (_) => _set(false) : null,
          onTapCancel: _enabled ? () => _set(false) : null,
          onTap: widget.onTap == null ? null : _activate,
          onLongPress: widget.onLongPress,
          child: body,
        ),
      ),
    );
  }
}

/// Animates the first number inside a pre-formatted value ("$12,480.50",
/// "₹1,20,000", "38 items") from its previous value, then settles on the
/// exact original string.
class CountUpText extends StatelessWidget {
  const CountUpText(
    this.value, {
    required this.style,
    this.duration = const Duration(milliseconds: 1100),
    this.maxLines = 1,
    this.textAlign,
    super.key,
  });

  final String value;
  final TextStyle style;
  final Duration duration;
  final int maxLines;
  final TextAlign? textAlign;

  static final _number = RegExp(r'\d[\d,]*(\.\d+)?');

  @override
  Widget build(BuildContext context) {
    final match = _number.firstMatch(value);
    if (match == null || context.reduceMotion) return _text(value);
    final raw = match.group(0)!;
    final target = double.tryParse(raw.replaceAll(',', ''));
    if (target == null) return _text(value);
    final decimals = match.group(1) == null ? 0 : match.group(1)!.length - 1;
    final intPart = raw.split('.').first;
    final grouped = intPart.contains(',');
    final indian = RegExp(r'^\d{1,2}(,\d{2})+,\d{3}$').hasMatch(intPart);
    final prefix = value.substring(0, match.start);
    final suffix = value.substring(match.end);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, v, _) {
        if ((v - target).abs() < 1e-9) return _text(value);
        final body = _format(v, decimals, grouped: grouped, indian: indian);
        return _text('$prefix$body$suffix');
      },
    );
  }

  Widget _text(String text) => Text(
    text,
    style: style,
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    textAlign: textAlign,
  );

  static String _format(
    double v,
    int decimals, {
    required bool grouped,
    required bool indian,
  }) {
    final fixed = v.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    var whole = parts.first;
    if (grouped) whole = _group(whole, indian: indian);
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  static String _group(String digits, {required bool indian}) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final size = indian ? 2 : 3;
    final chunks = <String>[];
    while (rest.length > size) {
      chunks.insert(0, rest.substring(rest.length - size));
      rest = rest.substring(0, rest.length - size);
    }
    if (rest.isNotEmpty) chunks.insert(0, rest);
    return '${chunks.join(',')},$last3';
  }
}

/// Shimmering placeholder block for skeleton loaders.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = AtelierRadius.xs,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (context.reduceMotion) return box;
    return box
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: p.isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.7),
        );
  }
}

/// Slow, drifting champagne light behind hero areas. Cheap: three radial
/// gradients repainted on their own layer.
class AtelierAmbient extends StatefulWidget {
  const AtelierAmbient({this.intensity = 1, super.key});

  final double intensity;

  @override
  State<AtelierAmbient> createState() => _AtelierAmbientState();
}

class _AtelierAmbientState extends State<AtelierAmbient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AmbientPainter(
            repaint: _c,
            gold: p.gold,
            accent: p.isDark
                ? const Color(0xFF6E5A3A)
                : const Color(0xFFE9D7B8),
            cool: p.sapphire,
            strength: (p.isDark ? 0.22 : 0.32) * widget.intensity,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.repaint,
    required this.gold,
    required this.accent,
    required this.cool,
    required this.strength,
  }) : super(repaint: repaint);

  final Animation<double> repaint;
  final Color gold;
  final Color accent;
  final Color cool;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final t = repaint.value * 2 * math.pi;
    void orb(Offset c, double r, Color color, double a) {
      final shader = RadialGradient(
        colors: [
          color.withValues(alpha: a),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, Paint()..shader = shader);
    }

    final w = size.width, h = size.height;
    final r = math.max(w, h);
    orb(
      Offset(w * (0.82 + 0.06 * math.sin(t)), h * (0.18 + 0.08 * math.cos(t))),
      r * 0.55,
      gold,
      strength,
    );
    orb(
      Offset(
        w * (0.12 + 0.05 * math.cos(t * 2)),
        h * (0.9 + 0.05 * math.sin(t)),
      ),
      r * 0.5,
      accent,
      strength * 0.9,
    );
    orb(
      Offset(
        w * (0.5 + 0.12 * math.sin(t + 1.4)),
        h * (0.5 + 0.1 * math.cos(t * 2)),
      ),
      r * 0.35,
      cool,
      strength * 0.18,
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.gold != gold || old.strength != strength;
}

/// Perspective tilt that follows the pointer/finger and springs back.
class TiltSurface extends StatefulWidget {
  const TiltSurface({required this.child, this.maxTilt = 0.12, super.key});

  final Widget child;
  final double maxTilt;

  @override
  State<TiltSurface> createState() => _TiltSurfaceState();
}

class _TiltSurfaceState extends State<TiltSurface>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Offset _target = Offset.zero;
  Offset _current = Offset.zero;
  Size _size = Size.zero;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration _) {
    final next = Offset.lerp(_current, _target, 0.14)!;
    if ((next - _target).distance < 0.0005) {
      _current = _target;
      _ticker.stop();
    } else {
      _current = next;
    }
    setState(() {});
  }

  void _aim(Offset local) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) _size = box.size;
    if (_size.isEmpty || context.reduceMotion) return;
    final dx = (local.dx / _size.width - 0.5) * 2;
    final dy = (local.dy / _size.height - 0.5) * 2;
    _target = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1));
    if (!_ticker.isActive) _ticker.start();
  }

  void _release() {
    _target = Offset.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(-_current.dy * widget.maxTilt)
      ..rotateY(_current.dx * widget.maxTilt);
    return MouseRegion(
      onHover: (e) => _aim(e.localPosition),
      onExit: (_) => _release(),
      child: Listener(
        onPointerMove: (e) => _aim(e.localPosition),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: Transform(
          alignment: Alignment.center,
          transform: m,
          child: widget.child,
        ),
      ),
    );
  }
}
