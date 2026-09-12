import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dispatched from melee / lot-type toggles so the screen ripple starts
/// at the exact press location.
class MeleeRippleOriginNotification extends Notification {
  const MeleeRippleOriginNotification(this.globalPosition);

  final Offset globalPosition;
}

/// Dispatched by [MeleeTintExtentAnchor] so the tinted band ends at the
/// bottom of the Single / Melee (or Lab Diamond / Lab Melee) switch.
class MeleeTintExtentNotification extends Notification {
  const MeleeTintExtentNotification(this.globalBottomY);

  final double globalBottomY;
}

/// Marks the Single/Melee switch as the bottom edge of the tinted background.
class MeleeTintExtentAnchor extends StatefulWidget {
  const MeleeTintExtentAnchor({required this.child, super.key});

  final Widget child;

  @override
  State<MeleeTintExtentAnchor> createState() => _MeleeTintExtentAnchorState();
}

class _MeleeTintExtentAnchorState extends State<MeleeTintExtentAnchor> {
  ScrollPosition? _scrollPosition;
  double? _lastBottom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next == _scrollPosition) return;
    _scrollPosition?.removeListener(_report);
    _scrollPosition = next;
    _scrollPosition?.addListener(_report);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_report);
    super.dispose();
  }

  void _report() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    if (_lastBottom != null && (bottom - _lastBottom!).abs() < 0.5) return;
    _lastBottom = bottom;
    MeleeTintExtentNotification(bottom).dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return widget.child;
  }
}

/// Background that tints from the top down to the Single/Melee switch
/// ([MeleeTintExtentAnchor]) and reveals the next color with a water-drop
/// circle. Content below the switch uses the theme default background.
class MeleeBackgroundShell extends StatefulWidget {
  const MeleeBackgroundShell({
    required this.isMelee,
    required this.child,
    this.family = MeleeBgFamily.natural,
    super.key,
  });

  final bool isMelee;
  final MeleeBgFamily family;
  final Widget child;

  @override
  State<MeleeBackgroundShell> createState() => _MeleeBackgroundShellState();
}

class _MeleeBackgroundShellState extends State<MeleeBackgroundShell>
    with SingleTickerProviderStateMixin {
  late Color _fromColor;
  late Color _toColor;
  late final AnimationController _controller;
  late final Animation<double> _reveal;

  final GlobalKey _stackKey = GlobalKey();
  Offset? _pendingGlobalOrigin;
  Offset _rippleOrigin = Offset.zero;
  Size _lastSize = Size.zero;
  double? _tintGlobalBottomY;
  bool _animating = false;
  bool _themeResolved = false;

  @override
  void initState() {
    super.initState();
    // Theme-aware colors are resolved in [didChangeDependencies].
    _fromColor = AppColors.naturalSingleBg;
    _toColor = _fromColor;

    _controller = AnimationController(
      vsync: this,
      duration: AppColors.meleeBgDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _fromColor = _toColor;
            _animating = false;
          });
        }
      });

    _reveal = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppColors.screenBgFor(
      context,
      melee: widget.isMelee,
      family: widget.family,
    );
    if (!_themeResolved) {
      _themeResolved = true;
      _fromColor = next;
      _toColor = next;
      return;
    }
    // Keep resting colors in sync when theme flips without a mode change.
    if (!_animating && !_controller.isAnimating && next != _toColor) {
      _fromColor = next;
      _toColor = next;
    }
  }

  Offset _resolveOrigin(Size size) {
    final global = _pendingGlobalOrigin;
    if (global != null) {
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.globalToLocal(global);
      }
    }
    return Offset(size.width * 0.5, size.height * 0.42);
  }

  double _tintHeight(Size size) {
    final globalBottom = _tintGlobalBottomY;
    if (globalBottom == null) return size.height;
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return size.height;
    final localY = box.globalToLocal(Offset(0, globalBottom)).dy;
    // Soft pad past the switch so the fade never clips mid-control.
    return (localY + 12).clamp(0.0, size.height);
  }

  void _startTransition(Color next) {
    final progress = _controller.isAnimating ? _reveal.value : 1.0;
    _fromColor = Color.lerp(_fromColor, _toColor, progress) ?? _toColor;
    _toColor = next;
    _animating = true;
    // Hold at 0 so the first painted frame is still [_fromColor] only.
    _controller.value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _rippleOrigin = _resolveOrigin(
          Size(_lastSize.width, _tintHeight(_lastSize)),
        );
      });
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(covariant MeleeBackgroundShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedMode = oldWidget.isMelee != widget.isMelee;
    final changedFamily = oldWidget.family != widget.family;
    if (!changedMode && !changedFamily) return;

    final next = AppColors.screenBgFor(
      context,
      melee: widget.isMelee,
      family: widget.family,
    );
    // Dark mode has no family tint — skip the color-reveal animation.
    if (AppColors.isDark(context)) {
      _fromColor = next;
      _toColor = next;
      _animating = false;
      _controller.value = 1;
      return;
    }
    if (next == _toColor && !_animating) return;
    _startTransition(next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    // Soft themed underlay below the switch — not plain white/black.
    final baseBg = dark ? AppColors.slateSurface : AppColors.sandSurface;
    final accent = AppColors.finderAccent(
      context,
      family: widget.family,
      melee: widget.isMelee,
    );
    final restingTint = AppColors.screenBgFor(
      context,
      melee: widget.isMelee,
      family: widget.family,
    );
    final from = _animating ? _fromColor : restingTint;
    final to = _animating ? _toColor : restingTint;

    return NotificationListener<Notification>(
      onNotification: (notification) {
        if (notification is MeleeRippleOriginNotification) {
          _pendingGlobalOrigin = notification.globalPosition;
          return true;
        }
        if (notification is MeleeTintExtentNotification) {
          if (_tintGlobalBottomY != notification.globalBottomY) {
            setState(() => _tintGlobalBottomY = notification.globalBottomY);
          }
          return true;
        }
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              _lastSize = constraints.biggest;
              final height = _tintHeight(_lastSize);
              final bandSize = Size(_lastSize.width, height);
              final origin = _rippleOrigin == Offset.zero
                  ? _resolveOrigin(bandSize)
                  : _rippleOrigin;
              final progress = _animating ? _reveal.value : 1.0;

              return Stack(
                key: _stackKey,
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: baseBg),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: height,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) {
                        // Keep tint strong through most of the band; soft
                        // blend only near the switch.
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFFFFFF),
                            Color(0xE6FFFFFF),
                            Color(0x66FFFFFF),
                          ],
                          stops: [0.0, 0.78, 0.94, 1.0],
                        ).createShader(bounds);
                      },
                      child: CustomPaint(
                        painter: _WaterRevealPainter(
                          progress: progress,
                          fromColor: from,
                          toColor: to,
                          accent: accent,
                          origin: origin,
                          dark: dark,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Expanding circle reveal of [toColor] over [fromColor], with soft rings.
class _WaterRevealPainter extends CustomPainter {
  const _WaterRevealPainter({
    required this.progress,
    required this.fromColor,
    required this.toColor,
    required this.accent,
    required this.origin,
    required this.dark,
  });

  final double progress;
  final Color fromColor;
  final Color toColor;
  final Color accent;
  final Offset origin;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Always paint the resting / source color full-bleed in the band.
    canvas.drawRect(Offset.zero & size, Paint()..color = fromColor);

    if (progress <= 0) return;

    final center = origin;
    final maxRadius =
        math.sqrt(
          math.max(center.dx, size.width - center.dx) *
                  math.max(center.dx, size.width - center.dx) +
              math.max(center.dy, size.height - center.dy) *
                  math.max(center.dy, size.height - center.dy),
        ) *
        1.2;

    // Ease the cover so the last 8% finishes solid (no abrupt cut-off).
    final coverT = progress >= 0.92
        ? 1.0
        : (progress / 0.92).clamp(0.0, 1.0);
    final radius = maxRadius * Curves.easeOutCubic.transform(coverT);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawRect(Offset.zero & size, Paint()..color = toColor);
    canvas.restore();

    // Soft water rings while the reveal is in flight (fade out near the end).
    final ringFade = (1.0 - progress).clamp(0.0, 1.0);
    if (ringFade > 0.04 && progress < 0.98) {
      // Dark mode needs brighter rings so the animation stays visible.
      final ringBoost = dark ? 1.35 : 1.0;
      canvas.drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22 * ringFade
          ..color = accent.withValues(alpha: 0.32 * ringFade * ringBoost),
      );
      canvas.drawCircle(
        center,
        radius * 1.04,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * ringFade
          ..color = toColor.withValues(alpha: 0.45 * ringFade * ringBoost),
      );
      canvas.drawCircle(
        center,
        radius * 1.14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * ringFade
          ..color = accent.withValues(alpha: 0.22 * ringFade * ringBoost),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterRevealPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fromColor != fromColor ||
        oldDelegate.toColor != toColor ||
        oldDelegate.accent != accent ||
        oldDelegate.origin != origin ||
        oldDelegate.dark != dark;
  }
}
