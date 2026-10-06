import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Two-thumb drag bar that sits above a min / max field pair.
///
/// Spans wider than [_curveThreshold] (prices, piece counts) use a quadratic
/// scale so the low end, where most searches happen, gets most of the track.
/// The bar only reports on release, so dragging never rebuilds the screen
/// every frame; the thumbs show live values in their labels meanwhile.
class FilterRangeBar extends StatefulWidget {
  const FilterRangeBar({
    required this.min,
    required this.max,
    required this.minLimit,
    required this.maxLimit,
    required this.onChangeEnd,
    this.onDragUpdate,
    this.isInteger = false,
    this.fractionDigits = 2,
    this.unitPrefix = '',
    this.unitSuffix = '',
    super.key,
  });

  final double min;
  final double max;
  final double minLimit;
  final double maxLimit;

  /// Called once per drag with the new range. The thumb that was not
  /// dragged keeps its exact current value.
  final void Function(double min, double max) onChangeEnd;

  /// Live range while a thumb is being dragged (nothing is committed), so
  /// paired min / max inputs can mirror the bar in real time.
  final void Function(double min, double max)? onDragUpdate;
  final bool isInteger;
  final int fractionDigits;
  final String unitPrefix;
  final String unitSuffix;

  static const _curveThreshold = 1000.0;

  @override
  State<FilterRangeBar> createState() => _FilterRangeBarState();
}

class _FilterRangeBarState extends State<FilterRangeBar> {
  RangeValues? _drag;
  RangeValues? _dragStart;

  double get _span => widget.maxLimit - widget.minLimit;
  bool get _curved => _span > FilterRangeBar._curveThreshold;

  double _toPos(double v) {
    if (_span <= 0) return 0;
    final t = ((v - widget.minLimit) / _span).clamp(0.0, 1.0);
    return _curved ? math.sqrt(t) : t;
  }

  double _fromPos(double p) {
    if (p <= 0.001) return widget.minLimit;
    if (p >= 0.999) return widget.maxLimit;
    final raw = widget.minLimit + _span * (_curved ? p * p : p);
    if (widget.isInteger) return raw.roundToDouble();
    final f = math.pow(10, widget.fractionDigits).toDouble();
    return (raw * f).round() / f;
  }

  String _label(double v) {
    final text = widget.isInteger
        ? v.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )
        : v.toStringAsFixed(widget.fractionDigits);
    return '${widget.unitPrefix}$text${widget.unitSuffix}';
  }

  /// The range a drag at [v] means; the thumb that has not moved keeps its
  /// exact current value. Null when neither thumb moved.
  (double, double)? _rangeFor(RangeValues v) {
    final start = _dragStart;
    final minMoved = start == null || (v.start - start.start).abs() > 1e-9;
    final maxMoved = start == null || (v.end - start.end).abs() > 1e-9;
    if (!minMoved && !maxMoved) return null;
    final a = minMoved ? _fromPos(v.start) : widget.min;
    final b = maxMoved ? _fromPos(v.end) : widget.max;
    return (math.min(a, b), math.max(a, b));
  }

  void _update(RangeValues v) {
    setState(() => _drag = v);
    final range = _rangeFor(v) ?? (widget.min, widget.max);
    widget.onDragUpdate?.call(range.$1, range.$2);
  }

  void _end(RangeValues v) {
    final range = _rangeFor(v);
    setState(() {
      _drag = null;
      _dragStart = null;
    });
    if (range == null) {
      // Released where it started: put the inputs back as they were.
      widget.onDragUpdate?.call(widget.min, widget.max);
      return;
    }
    if (range.$1 == widget.min && range.$2 == widget.max) return;
    widget.onChangeEnd(range.$1, range.$2);
  }

  @override
  Widget build(BuildContext context) {
    final values =
        _drag ??
        RangeValues(
          _toPos(math.min(widget.min, widget.max)),
          _toPos(math.max(widget.min, widget.max)),
        );
    final border = AppColors.border(context);
    final muted = AppColors.textMuted(context);
    final limitStyle = AppTypography.caption.copyWith(
      fontSize: 10.5,
      color: muted,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: AppColors.bronze,
            inactiveTrackColor: border,
            thumbColor: AppColors.card(context),
            overlayColor: AppColors.bronze.withValues(alpha: 0.14),
            rangeThumbShape: const _RingThumbShape(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            showValueIndicator: ShowValueIndicator.onDrag,
            valueIndicatorColor: AppColors.charcoal,
            valueIndicatorTextStyle: AppTypography.caption.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: RangeSlider(
            values: values,
            labels: RangeLabels(
              _label(_fromPos(values.start)),
              _label(_fromPos(values.end)),
            ),
            onChangeStart: (v) {
              AppHaptics.selection();
              _dragStart = v;
            },
            onChanged: _update,
            onChangeEnd: _end,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label(widget.minLimit), style: limitStyle),
              Text(_label(widget.maxLimit), style: limitStyle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card-coloured thumb with a bronze ring, matching the luxe controls.
class _RingThumbShape extends RangeSliderThumbShape {
  const _RingThumbShape();

  static const _radius = 9.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    final r = _radius + activationAnimation.value * 2;
    canvas.drawCircle(
      center.translate(0, 1),
      r,
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()..color = sliderTheme.thumbColor ?? Colors.white,
    );
    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = sliderTheme.activeTrackColor ?? AppColors.bronze,
    );
    canvas.drawCircle(
      center,
      2.4,
      Paint()..color = sliderTheme.activeTrackColor ?? AppColors.bronze,
    );
  }
}
