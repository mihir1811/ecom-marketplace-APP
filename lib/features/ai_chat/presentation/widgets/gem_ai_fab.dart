import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Circular Gem AI launcher — drag to reposition; tap to open/close.
class GemAiFab extends StatefulWidget {
  const GemAiFab({
    super.key,
    required this.onPressed,
    required this.onDrag,
    required this.onDragEnd,
    this.isOpen = false,
  });

  final VoidCallback onPressed;
  final void Function(Offset delta) onDrag;
  final VoidCallback onDragEnd;
  final bool isOpen;

  static const double size = 64;

  @override
  State<GemAiFab> createState() => _GemAiFabState();
}

class _GemAiFabState extends State<GemAiFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Offset _panDelta = Offset.zero;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.isOpen ? 'Close Gem AI' : 'Open Gem AI',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pulse.value);
          final scale =
              (_dragging || widget.isOpen) ? 1.0 : 1.0 + 0.03 * t;
          final glow = widget.isOpen ? 8.0 : 12.0 + 10.0 * t;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: GemAiFab.size,
              height: GemAiFab.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bronze.withValues(alpha: 0.3 + 0.18 * t),
                    blurRadius: glow,
                    spreadRadius: widget.isOpen ? 0 : 1.0 + 1.5 * t,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_dragging) return;
              widget.onPressed();
            },
            onPanStart: (_) {
              _panDelta = Offset.zero;
              _dragging = false;
            },
            onPanUpdate: (details) {
              _panDelta += details.delta;
              if (!_dragging && _panDelta.distance > 6) {
                _dragging = true;
              }
              if (_dragging) {
                widget.onDrag(details.delta);
              }
            },
            onPanEnd: (_) {
              final wasDragging = _dragging;
              _dragging = false;
              _panDelta = Offset.zero;
              if (wasDragging) {
                widget.onDragEnd();
              }
            },
            onPanCancel: () {
              _dragging = false;
              _panDelta = Offset.zero;
            },
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF243041),
                    AppColors.charcoal,
                    Color(0xFF6E4C2E),
                  ],
                  stops: [0, 0.52, 1],
                ),
                border: Border.all(
                  color: AppColors.bronzeLight.withValues(alpha: 0.55),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: widget.isOpen
                      ? const Icon(
                          Icons.close_rounded,
                          key: ValueKey('close'),
                          color: AppColors.warmWhite,
                          size: 28,
                        )
                      : const _FabIdleContent(key: ValueKey('idle')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FabIdleContent extends StatelessWidget {
  const _FabIdleContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.diamond_outlined,
          color: AppColors.bronzeLight,
          size: 16,
        ),
        const SizedBox(height: 2),
        Text(
          'Gem Ai',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.warmWhite,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            height: 1,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

/// Positions the FAB; [offset] is top-left in screen coordinates.
class GemAiDraggableFabHost extends StatelessWidget {
  const GemAiDraggableFabHost({
    super.key,
    required this.isOpen,
    required this.onPressed,
    required this.offset,
    required this.onOffsetChanged,
    required this.onDragDelta,
  });

  final bool isOpen;
  final VoidCallback onPressed;
  final Offset? offset;
  final ValueChanged<Offset> onOffsetChanged;
  final void Function(Offset delta) onDragDelta;

  static Offset defaultOffset(Size screen, EdgeInsets padding) {
    const margin = 20.0;
    return Offset(
      screen.width - padding.right - GemAiFab.size - margin,
      screen.height - padding.bottom - GemAiFab.size - margin,
    );
  }

  static Offset clampToScreen(
    Offset raw,
    Size screen,
    EdgeInsets padding,
  ) {
    final minX = padding.left + 8;
    final minY = padding.top + 8;
    final maxX = screen.width - padding.right - GemAiFab.size - 8;
    final maxY = screen.height - padding.bottom - GemAiFab.size - 8;
    return Offset(
      raw.dx.clamp(minX, maxX < minX ? minX : maxX),
      raw.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final padding = media.padding;
    final resolved = clampToScreen(
      offset ?? defaultOffset(screen, padding),
      screen,
      padding,
    );

    return Positioned(
      left: resolved.dx,
      top: resolved.dy,
      child: GemAiFab(
        isOpen: isOpen,
        onPressed: onPressed,
        onDrag: onDragDelta,
        onDragEnd: () {
          onOffsetChanged(clampToScreen(resolved, screen, padding));
        },
      ),
    );
  }
}
