import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'live_stage_tokens.dart';

/// Slide-to-confirm bid track: drag the gavel to the end to place the bid.
/// Letting go early springs it back. While [onSubmit] runs the thumb stays
/// at the end with a spinner; it returns home when the future completes.
///
/// When [onSubmit] is `null` the track is locked; tapping it calls
/// [onLockedTap] (e.g. to add funds).
class LiveSlideToBid extends StatefulWidget {
  const LiveSlideToBid({
    required this.label,
    required this.onSubmit,
    this.lockedLabel,
    this.onLockedTap,
    this.busy = false,
    super.key,
  });

  final String label;
  final Future<void> Function()? onSubmit;
  final String? lockedLabel;
  final VoidCallback? onLockedTap;

  /// A bid is in flight elsewhere (e.g. from the collapsed dock).
  final bool busy;

  @override
  State<LiveSlideToBid> createState() => _LiveSlideToBidState();
}

class _LiveSlideToBidState extends State<LiveSlideToBid>
    with TickerProviderStateMixin {
  static const _height = 58.0;
  static const _pad = 4.0;
  static const _thumb = _height - _pad * 2;
  static const _commitAt = 0.86;

  /// 0 = home, 1 = end of the track.
  late final AnimationController _pos = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  var _submitting = false;
  var _armed = false;

  bool get _enabled => widget.onSubmit != null && !widget.busy;

  @override
  void dispose() {
    _pos.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, double travel) {
    if (!_enabled || _submitting || travel <= 0) return;
    _pos.value = (_pos.value + d.delta.dx / travel).clamp(0.0, 1.0);
    final armed = _pos.value >= _commitAt;
    if (armed != _armed) {
      _armed = armed;
      AppHaptics.selection();
    }
  }

  Future<void> _release() async {
    if (!_enabled || _submitting) return;
    if (_pos.value >= _commitAt) {
      await _submit();
    } else {
      _armed = false;
      await _pos.animateTo(0, curve: Curves.easeOutBack);
    }
  }

  Future<void> _submit() async {
    final submit = widget.onSubmit;
    if (submit == null || _submitting) return;
    setState(() => _submitting = true);
    AppHaptics.medium();
    await _pos.animateTo(1, curve: Curves.easeOutCubic);
    try {
      await submit();
    } finally {
      if (mounted) {
        _armed = false;
        setState(() => _submitting = false);
        unawaited(
          _pos.animateTo(
            0,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final gold = LiveStage.gold;
    final locked = widget.onSubmit == null && !widget.busy;
    final working = _submitting || widget.busy;
    final label = locked ? (widget.lockedLabel ?? widget.label) : widget.label;

    return Semantics(
      button: true,
      enabled: _enabled || locked,
      label: locked ? label : '$label. Slide right or double tap to bid.',
      onTap: locked
          ? widget.onLockedTap
          : (_enabled ? () => unawaited(_submit()) : null),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final travel = box.maxWidth - _thumb - _pad * 2;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: locked ? widget.onLockedTap : null,
            onHorizontalDragUpdate: (d) => _drag(d, travel),
            onHorizontalDragEnd: (_) => unawaited(_release()),
            onHorizontalDragCancel: () => unawaited(_release()),
            child: AnimatedBuilder(
              animation: Listenable.merge([_pos, _hint]),
              builder: (context, _) {
                final t = _pos.value;
                final x = _pad + travel * t;
                return SizedBox(
                  height: _height,
                  child: Stack(
                    children: [
                      // Track.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: locked
                                ? Colors.white.withValues(alpha: 0.06)
                                : gold.withValues(alpha: 0.14),
                            border: Border.all(
                              color: locked
                                  ? LiveStage.glassBorder
                                  : gold.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                      // Gold fill that follows the thumb.
                      if (!locked)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: x + _thumb + _pad,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: LinearGradient(
                                colors: [
                                  gold.withValues(alpha: 0.35),
                                  gold.withValues(alpha: 0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Label, fading as the thumb covers it.
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: _thumb + 14,
                            right: 18,
                          ),
                          child: Opacity(
                            opacity: working
                                ? 1
                                : (1 - t * 1.4).clamp(0.0, 1.0),
                            child: Center(
                              child: _Label(
                                text: working ? 'Placing your bid…' : label,
                                locked: locked,
                                shimmer: still || locked || working
                                    ? null
                                    : _hint.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Thumb.
                      Positioned(
                        left: x,
                        top: _pad,
                        width: _thumb,
                        height: _thumb,
                        child: _Thumb(
                          locked: locked,
                          working: working,
                          armed: t >= _commitAt,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.locked, this.shimmer});

  final String text;
  final bool locked;

  /// 0..1 sweep of the highlight, or `null` for a plain label.
  final double? shimmer;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: locked ? LiveStage.inkMuted : Colors.white,
      fontSize: 15.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locked) ...[
          Icon(Icons.lock_outline_rounded, size: 16, color: LiveStage.inkMuted),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (!locked) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_double_arrow_right_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ],
      ],
    );
    final s = shimmer;
    if (s == null) return label;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.75),
          Colors.white,
          Colors.white.withValues(alpha: 0.75),
        ],
        stops: const [0, 0.5, 1],
        begin: Alignment(-1 + s * 4 - 1.5, 0),
        end: Alignment(s * 4 - 1.5, 0),
      ).createShader(rect),
      child: label,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.locked,
    required this.working,
    required this.armed,
  });

  final bool locked;
  final bool working;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final gold = LiveStage.gold;
    const ink = Color(0xFF16140F);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? Colors.white.withValues(alpha: 0.14) : null,
        gradient: locked
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(gold, Colors.white, 0.3)!, gold],
              ),
        boxShadow: locked
            ? null
            : [
                BoxShadow(
                  color: gold.withValues(alpha: armed ? 0.7 : 0.4),
                  blurRadius: armed ? 20 : 12,
                ),
              ],
      ),
      child: Center(
        child: working
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: ink),
              )
            : Icon(
                locked
                    ? Icons.lock_rounded
                    : armed
                    ? Icons.check_rounded
                    : Icons.gavel_rounded,
                size: 22,
                color: locked ? LiveStage.inkMuted : ink,
              ),
      ),
    );
  }
}
