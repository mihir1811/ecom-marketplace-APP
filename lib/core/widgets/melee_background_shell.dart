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
/// ([MeleeTintExtentAnchor]), crossfades colors, and plays a water-drop
/// reveal when [isMelee] changes. Content below the switch uses the
/// theme default background.
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
    with TickerProviderStateMixin {
  late Color _fromColor;
  late Color _toColor;
  late final AnimationController _colorController;
  late final AnimationController _rippleController;
  late final Animation<double> _colorT;
  late final Animation<double> _rippleT;

  final GlobalKey _stackKey = GlobalKey();
  Offset? _pendingGlobalOrigin;
  Offset _rippleOrigin = Offset.zero;
  Size _lastSize = Size.zero;
  double? _tintGlobalBottomY;

  @override
  void initState() {
    super.initState();
    _fromColor = AppColors.screenBg(
      melee: widget.isMelee,
      family: widget.family,
    );
    _toColor = _fromColor;

    _colorController = AnimationController(
      vsync: this,
      duration: AppColors.meleeBgDuration,
    );
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _colorT = CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOutCubic,
    );
    _rippleT = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutCubic,
    );

    _colorController.value = 1;
  }

  Offset _resolveOrigin(Size size) {
    final global = _pendingGlobalOrigin;
    if (global != null) {
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        return box.globalToLocal(global);
      }
    }
    return Offset(size.width * 0.5, size.height * 0.5);
  }

  double _tintHeight(Size size) {
    final globalBottom = _tintGlobalBottomY;
    if (globalBottom == null) return size.height;
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return size.height;
    final localY = box.globalToLocal(Offset(0, globalBottom)).dy;
    return localY.clamp(0.0, size.height);
  }

  @override
  void didUpdateWidget(covariant MeleeBackgroundShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = AppColors.screenBg(
      melee: widget.isMelee,
      family: widget.family,
    );
    final changedMode = oldWidget.isMelee != widget.isMelee;
    final changedFamily = oldWidget.family != widget.family;

    if (changedMode || changedFamily) {
      _fromColor = Color.lerp(_fromColor, _toColor, _colorT.value) ?? _toColor;
      _toColor = next;
      _colorController.forward(from: 0);
      // Ripple on Single/Melee and on Natural/Lab Grown family switches.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _rippleOrigin = _resolveOrigin(_lastSize);
        });
        _rippleController.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final baseBg = dark ? AppColors.obsidianBg : AppColors.creamBg;

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
        animation: Listenable.merge([_colorController, _rippleController]),
        builder: (context, child) {
          final tint = dark
              ? AppColors.obsidianBg
              : (Color.lerp(_fromColor, _toColor, _colorT.value) ?? _toColor);
          final showRipple = !dark &&
              (_rippleController.isAnimating ||
                  (_rippleT.value > 0 && _rippleT.value < 1));
          return LayoutBuilder(
            builder: (context, constraints) {
              _lastSize = constraints.biggest;
              final height = _tintHeight(_lastSize);
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
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xE6FFFFFF),
                            Color(0x66FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.0, 0.42, 0.78, 1.0],
                        ).createShader(bounds);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: tint),
                          if (showRipple)
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _WaterDropPainter(
                                  progress: _rippleT.value,
                                  fillColor: _toColor,
                                  accent: widget.isMelee
                                      ? AppColors.bronzeLight
                                      : AppColors.bronze,
                                  origin: _rippleOrigin == Offset.zero
                                      ? _resolveOrigin(Size(
                                          _lastSize.width,
                                          height,
                                        ))
                                      : _rippleOrigin,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                        ],
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

class _WaterDropPainter extends CustomPainter {
  const _WaterDropPainter({
    required this.progress,
    required this.fillColor,
    required this.accent,
    required this.origin,
  });

  final double progress;
  final Color fillColor;
  final Color accent;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = origin;
    final maxRadius = math.sqrt(
          math.max(center.dx, size.width - center.dx) *
                  math.max(center.dx, size.width - center.dx) +
              math.max(center.dy, size.height - center.dy) *
                  math.max(center.dy, size.height - center.dy),
        ) *
        1.15;
    final radius = maxRadius * progress;

    final fill = Paint()
      ..color = fillColor.withValues(
        alpha: (0.55 + 0.45 * progress).clamp(0.0, 1.0),
      );
    canvas.drawCircle(center, radius, fill);

    final ringAlpha = (1.0 - progress).clamp(0.0, 1.0);
    if (ringAlpha > 0.02) {
      canvas.drawCircle(
        center,
        radius * 0.88,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28 * ringAlpha
          ..color = accent.withValues(alpha: 0.28 * ringAlpha),
      );
      canvas.drawCircle(
        center,
        radius * 1.02,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14 * ringAlpha
          ..color = fillColor.withValues(alpha: 0.35 * ringAlpha),
      );
      canvas.drawCircle(
        center,
        radius * 1.12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * ringAlpha
          ..color = accent.withValues(alpha: 0.18 * ringAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.accent != accent ||
        oldDelegate.origin != origin;
  }
}
