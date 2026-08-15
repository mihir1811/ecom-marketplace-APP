import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class FilterAdvancedRangeInput extends StatefulWidget {
  const FilterAdvancedRangeInput({
    required this.title,
    required this.currentMin,
    required this.currentMax,
    required this.minLimit,
    required this.maxLimit,
    required this.infoText,
    this.unit = '',
    required this.onMinChanged,
    required this.onMaxChanged,
    super.key,
  });

  final String title;
  final double currentMin;
  final double currentMax;
  final double minLimit;
  final double maxLimit;
  final String infoText;
  final String unit;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  @override
  State<FilterAdvancedRangeInput> createState() => _FilterAdvancedRangeInputState();
}

class _FilterAdvancedRangeInputState extends State<FilterAdvancedRangeInput> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController();
    _maxController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant FilterAdvancedRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMin != widget.currentMin) {
      _syncControllerFromExternal(
        controller: _minController,
        oldExternal: oldWidget.currentMin,
        newExternal: widget.currentMin,
        defaultLimit: widget.minLimit,
      );
    }
    if (oldWidget.currentMax != widget.currentMax) {
      _syncControllerFromExternal(
        controller: _maxController,
        oldExternal: oldWidget.currentMax,
        newExternal: widget.currentMax,
        defaultLimit: widget.maxLimit,
      );
    }
  }

  void _syncControllerFromExternal({
    required TextEditingController controller,
    required double oldExternal,
    required double newExternal,
    required double defaultLimit,
  }) {
    if (controller.text.isEmpty) {
      if (newExternal != defaultLimit) {
        controller.text = newExternal.toStringAsFixed(1);
      }
      return;
    }
    final parsed = double.tryParse(controller.text);
    if (parsed == null || parsed == oldExternal) {
      if (newExternal == defaultLimit) {
        controller.clear();
      } else {
        controller.text = newExternal.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _handleMinSubmitted(String text) {
    if (text.trim().isEmpty) {
      if (widget.currentMin != widget.minLimit) {
        widget.onMinChanged(widget.minLimit);
      }
      return;
    }
    final parsed = double.tryParse(text) ?? widget.minLimit;
    final clamped = parsed.clamp(widget.minLimit, widget.currentMax);
    if (clamped != widget.currentMin) {
      widget.onMinChanged(clamped);
    }
    _minController.text = clamped.toStringAsFixed(1);
  }

  void _handleMaxSubmitted(String text) {
    if (text.trim().isEmpty) {
      if (widget.currentMax != widget.maxLimit) {
        widget.onMaxChanged(widget.maxLimit);
      }
      return;
    }
    final parsed = double.tryParse(text) ?? widget.maxLimit;
    final clamped = parsed.clamp(widget.currentMin, widget.maxLimit);
    if (clamped != widget.currentMax) {
      widget.onMaxChanged(clamped);
    }
    _maxController.text = clamped.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${widget.title} ${widget.unit.isNotEmpty ? "(${widget.unit})" : ""}',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: widget.infoText,
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: false,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 13),
              child: const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.bronze,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Minimum', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 38,
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _handleMinSubmitted(_minController.text);
                        }
                      },
                      child: TextFormField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        style: AppTypography.caption,
                        decoration: InputDecoration(
                          hintText: widget.minLimit.toStringAsFixed(1),
                          hintStyle: AppTypography.caption.copyWith(
                            color: AppColors.textMutedLight,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          filled: true,
                          fillColor: AppColors.warmWhite,
                        ),
                        onFieldSubmitted: _handleMinSubmitted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Maximum', style: TextStyle(fontSize: 11, color: Colors.black54)),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 38,
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _handleMaxSubmitted(_maxController.text);
                        }
                      },
                      child: TextFormField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                        style: AppTypography.caption,
                        decoration: InputDecoration(
                          hintText: widget.maxLimit.toStringAsFixed(1),
                          hintStyle: AppTypography.caption.copyWith(
                            color: AppColors.textMutedLight,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          filled: true,
                          fillColor: AppColors.warmWhite,
                        ),
                        onFieldSubmitted: _handleMaxSubmitted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
