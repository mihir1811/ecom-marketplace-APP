import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A custom, highly interactive Range Slider synced with manual text inputs.
/// Conforms to the luxury design theme with Bronze accent colors and custom borders.
class FilterRangeSlider extends StatefulWidget {
  const FilterRangeSlider({
    required this.title,
    required this.minLimit,
    required this.maxLimit,
    required this.currentMin,
    required this.currentMax,
    required this.onChanged,
    required this.onClear,
    this.unitPrefix = '',
    this.unitSuffix = '',
    this.isInteger = false,
    this.showClear = false,
    super.key,
  });

  final String title;
  final double minLimit;
  final double maxLimit;
  final double currentMin;
  final double currentMax;
  final void Function(double min, double max) onChanged;
  final VoidCallback onClear;
  final String unitPrefix;
  final String unitSuffix;
  final bool isInteger;
  final bool showClear;

  @override
  State<FilterRangeSlider> createState() => _FilterRangeSliderState();
}

class _FilterRangeSliderState extends State<FilterRangeSlider> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController();
    _maxController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant FilterRangeSlider oldWidget) {
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
        controller.text = _formatValue(newExternal);
      }
      return;
    }
    final parsed = double.tryParse(
      controller.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    if (parsed == null || parsed == oldExternal) {
      if (newExternal == defaultLimit) {
        controller.clear();
      } else {
        controller.text = _formatValue(newExternal);
      }
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    if (widget.isInteger) {
      return val.round().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _formatDisplayValue(double val) {
    final formatted = widget.isInteger
        ? val.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')
        : val.toStringAsFixed(2);
    return '${widget.unitPrefix}$formatted${widget.unitSuffix}';
  }

  void _handleMinSubmitted(String text) {
    if (text.trim().isEmpty) {
      widget.onChanged(widget.minLimit, widget.currentMax);
      return;
    }
    final parsed = double.tryParse(text) ?? widget.minLimit;
    final clamped = parsed.clamp(widget.minLimit, widget.currentMax);
    widget.onChanged(clamped, widget.currentMax);
    _minController.text = _formatValue(clamped);
  }

  void _handleMaxSubmitted(String text) {
    if (text.trim().isEmpty) {
      widget.onChanged(widget.currentMin, widget.maxLimit);
      return;
    }
    final parsed = double.tryParse(text) ?? widget.maxLimit;
    final clamped = parsed.clamp(widget.currentMin, widget.maxLimit);
    widget.onChanged(widget.currentMin, clamped);
    _maxController.text = _formatValue(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (Title, Value)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  '(${_formatDisplayValue(widget.currentMin)} - ${_formatDisplayValue(widget.currentMax)})',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.showClear)
              GestureDetector(
                onTap: () {
                  _minController.clear();
                  _maxController.clear();
                  widget.onClear();
                },
                child: Text(
                  'Clear',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.bronze,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),

        // Manual Text inputs side by side
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimum (${widget.unitSuffix.isEmpty ? 'value' : widget.unitSuffix.trim()})',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SizedBox(
                    height: 40,
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _handleMinSubmitted(_minController.text);
                        }
                      },
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.body.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _formatValue(widget.minLimit),
                          hintStyle: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: AppColors.textMutedLight,
                          ),
                          filled: true,
                          fillColor: AppColors.warmWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                            vertical: AppSpacing.s8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
                          ),
                        ),
                        onSubmitted: _handleMinSubmitted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maximum (${widget.unitSuffix.isEmpty ? 'value' : widget.unitSuffix.trim()})',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  SizedBox(
                    height: 40,
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          _handleMaxSubmitted(_maxController.text);
                        }
                      },
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTypography.body.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _formatValue(widget.maxLimit),
                          hintStyle: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: AppColors.textMutedLight,
                          ),
                          filled: true,
                          fillColor: AppColors.warmWhite,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s12,
                            vertical: AppSpacing.s8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: BorderSide(
                              color: AppColors.warmBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.r8),
                            borderSide: const BorderSide(color: AppColors.bronze, width: 1.5),
                          ),
                        ),
                        onSubmitted: _handleMaxSubmitted,
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
