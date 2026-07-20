import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dispatched from melee / lot-type toggles so the screen ripple starts
/// at the exact press location.
class MeleeRippleOriginNotification extends Notification {
  const MeleeRippleOriginNotification(this.globalPosition);

  final Offset globalPosition;
}

/// Full-screen background that crossfades between default and melee colors
/// and plays a water-drop circular reveal when [isMelee] changes.
///
/// The reveal origin is the last reported tap (via
/// [MeleeRippleOriginNotification]); falls back to screen center.
class MeleeBackgroundShell extends StatefulWidget {
  const MeleeBackgroundShell({
    required this.isMelee,
    required this.isDark,
    required this.child,
    super.key,
  });

  final bool isMelee;
  final bool isDark;
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

  @override
  void initState() {
    super.initState();
    _fromColor = AppColors.screenBg(isDark: widget.isDark, melee: widget.isMelee);
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

  @override
  void didUpdateWidget(covariant MeleeBackgroundShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = AppColors.screenBg(isDark: widget.isDark, melee: widget.isMelee);
    final changedMode = oldWidget.isMelee != widget.isMelee;
    final changedTheme = oldWidget.isDark != widget.isDark;

    if (changedMode || changedTheme) {
      _fromColor = Color.lerp(_fromColor, _toColor, _colorT.value) ?? _toColor;
      _toColor = next;
      _colorController.forward(from: 0);
      if (changedMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _rippleOrigin = _resolveOrigin(_lastSize);
          });
          _rippleController.forward(from: 0);
        });
      }
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
    return NotificationListener<MeleeRippleOriginNotification>(
      onNotification: (notification) {
        _pendingGlobalOrigin = notification.globalPosition;
        return true;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_colorController, _rippleController]),
        builder: (context, child) {
          final bg = Color.lerp(_fromColor, _toColor, _colorT.value) ?? _toColor;
          final showRipple = _rippleController.isAnimating ||
              (_rippleT.value > 0 && _rippleT.value < 1);
          return Stack(
            key: _stackKey,
            fit: StackFit.expand,
            children: [
              ColoredBox(color: bg),
              if (showRipple)
                IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _lastSize = constraints.biggest;
                      return CustomPaint(
                        painter: _WaterDropPainter(
                          progress: _rippleT.value,
                          fillColor: _toColor,
                          accent: widget.isMelee
                              ? AppColors.bronzeLight
                              : AppColors.bronze,
                          origin: _rippleOrigin == Offset.zero
                              ? _resolveOrigin(_lastSize)
                              : _rippleOrigin,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              child!,
            ],
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
