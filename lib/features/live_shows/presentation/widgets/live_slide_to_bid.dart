import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../../core/haptics/app_haptics.dart';
import 'live_stage_tokens.dart';

/// Slide-to-confirm bid: drag the champagne gavel to the end to place the
/// bid. Letting go early springs it home on a real spring. While
/// [onSubmit] runs the thumb waits at the end; it returns when done.
///
/// When [onSubmit] is `null` the track is locked and shows [lockedLabel];
/// tapping it calls [onLockedTap] (e.g. to add funds).
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

  /// A bid is in flight elsewhere.
  final bool busy;

  @override
  State<LiveSlideToBid> createState() => _LiveSlideToBidState();
}

class _LiveSlideToBidState extends State<LiveSlideToBid>
    with TickerProviderStateMixin {
  static const _height = 60.0;
  static const _pad = 5.0;
  static const _thumb = _height - _pad * 2;
  static const _commitAt = 0.88;
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 260,
    damping: 18,
  );

  static const _hintRest = Duration(milliseconds: 1600);

  /// 0 = home, 1 = end of the track; unbounded so the spring can overshoot.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
  );

  /// One sweep of the label highlight; it then rests, so the stage draws
  /// no frames for it in between.
  late final AnimationController _hint =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _restHint();
      });
  Timer? _hintTimer;

  var _submitting = false;
  var _armed = false;

  bool get _enabled => widget.onSubmit != null && !widget.busy;

  @override
  void initState() {
    super.initState();
    _restHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _pos.dispose();
    _hint.dispose();
    super.dispose();
  }

  void _restHint() {
    _hintTimer?.cancel();
    _hintTimer = Timer(_hintRest, () {
      if (!mounted) return;
      if (_enabled &&
          !_submitting &&
          !MediaQuery.disableAnimationsOf(context)) {
        unawaited(_hint.forward(from: 0));
      } else {
        _restHint();
      }
    });
  }

  void _drag(DragUpdateDetails d, double travel) {
    if (!_enabled || _submitting || travel <= 0) return;
    _pos.value = (_pos.value + d.delta.dx / travel).clamp(0.0, 1.0);
    final armed = _pos.value >= _commitAt;
    if (armed != _armed) {
      _armed = armed;
      armed ? AppHaptics.medium() : AppHaptics.selection();
    }
  }

  Future<void> _release(double velocity, double travel) async {
    if (!_enabled || _submitting) return;
    final v = travel <= 0 ? 0.0 : velocity / travel;
    if (_pos.value >= _commitAt || (_pos.value > 0.55 && v > 2.2)) {
      await _submit();
    } else {
      _armed = false;
      await _pos.animateWith(SpringSimulation(_spring, _pos.value, 0, v));
    }
  }

  Future<void> _submit() async {
    final submit = widget.onSubmit;
    if (submit == null || _submitting) return;
    setState(() => _submitting = true);
    AppHaptics.heavy();
    await _pos.animateTo(
      1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
    try {
      await submit();
    } finally {
      if (mounted) {
        _armed = false;
        setState(() => _submitting = false);
        unawaited(_pos.animateWith(SpringSimulation(_spring, 1, 0, 0)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
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
          if (locked) {
            return _Locked(text: label, onTap: widget.onLockedTap);
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => _drag(d, travel),
            onHorizontalDragEnd: (d) =>
                unawaited(_release(d.primaryVelocity ?? 0, travel)),
            onHorizontalDragCancel: () => unawaited(_release(0, travel)),
            child: AnimatedBuilder(
              animation: _pos,
              builder: (context, _) {
                final t = _pos.value.clamp(-0.05, 1.05);
                final x = _pad + travel * t;
                final fill = (x + _thumb + _pad).clamp(0.0, box.maxWidth);
                return SizedBox(
                  height: _height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: LiveStage.ink.withValues(alpha: 0.05),
                            border: Border.all(
                              color: LiveStage.champagne.withValues(
                                alpha: 0.35 + 0.4 * t.clamp(0.0, 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Champagne wash that follows the thumb.
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: fill,
                        child: Opacity(
                          opacity: (0.25 + t * 0.75).clamp(0.0, 1.0),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                              gradient: LiveStage.champagneGradient,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: _thumb + 12,
                            right: 14,
                          ),
                          child: Opacity(
                            opacity: working
                                ? 1
                                : (1 - t * 1.6).clamp(0.0, 1.0),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _hint,
                                // The sweep crosses the label between
                                // 0.1 and 0.57.
                                builder: (context, _) => _Label(
                                  text: working ? 'Placing your bid…' : label,
                                  onFill: working,
                                  shimmer: still || working
                                      ? null
                                      : 0.1 + _hint.value * 0.47,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: x,
                        top: _pad,
                        width: _thumb,
                        height: _thumb,
                        child: _Thumb(
                          working: working,
                          armed: t >= _commitAt,
                          swing: still ? 0 : t,
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

class _Locked extends StatelessWidget {
  const _Locked({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LivePressable(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: LiveStage.ink.withValues(alpha: 0.05),
          border: Border.all(color: LiveStage.hairlineStrong),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LiveStage.ink.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: LiveStage.inkMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LiveType.label(14.5),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: LiveStage.champagne,
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.onFill, this.shimmer});

  final String text;
  final bool onFill;

  /// 0..1 sweep of the highlight, or `null` for a plain label.
  final double? shimmer;

  @override
  Widget build(BuildContext context) {
    final color = onFill ? LiveStage.onChampagne : LiveStage.ink;
    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LiveType.label(
              15,
              color: color,
              weight: FontWeight.w800,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        if (!onFill) ...[
          const SizedBox(width: 5),
          Icon(
            Icons.keyboard_double_arrow_right_rounded,
            size: 18,
            color: LiveStage.champagne.withValues(alpha: 0.9),
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
          LiveStage.ink.withValues(alpha: 0.7),
          LiveStage.champagneLight,
          LiveStage.ink.withValues(alpha: 0.7),
        ],
        stops: const [0.35, 0.5, 0.65],
        begin: Alignment(-3 + s * 6, 0),
        end: Alignment(-1 + s * 6, 0),
      ).createShader(rect),
      child: label,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.working,
    required this.armed,
    required this.swing,
  });

  final bool working;
  final bool armed;

  /// Track position; tips the gavel forward as it travels.
  final double swing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: armed || working
            ? const LinearGradient(
                colors: [Colors.white, LiveStage.champagneLight],
              )
            : LiveStage.champagneGradient,
        boxShadow: [
          BoxShadow(
            color: LiveStage.champagne.withValues(alpha: armed ? 0.75 : 0.4),
            blurRadius: armed ? 26 : 14,
            spreadRadius: armed ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: working
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: LiveStage.onChampagne,
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: armed
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('ok'),
                        size: 24,
                        color: LiveStage.onChampagne,
                      )
                    : Transform.rotate(
                        key: const ValueKey('gavel'),
                        angle: -math.pi / 7 * swing.clamp(0.0, 1.0),
                        child: const Icon(
                          Icons.gavel_rounded,
                          size: 22,
                          color: LiveStage.onChampagne,
                        ),
                      ),
              ),
      ),
    );
  }
}
