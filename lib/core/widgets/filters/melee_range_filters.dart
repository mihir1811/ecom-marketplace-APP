import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_group_card.dart';
import 'filter_range_slider.dart';
import '../../../core/utils/app_currency.dart';

/// Presentational Pcs/Carat range filter group with a toggle switch.
/// State-agnostic: values and change callbacks are injected, so both the
/// diamond and gemstone screens can reuse it.
class MeleeRangeFilters extends StatefulWidget {
  const MeleeRangeFilters({
    required this.caratPerPcsMin,
    required this.caratPerPcsMax,
    required this.onCaratPerPcsChanged,
    required this.pricePerPcsMin,
    required this.pricePerPcsMax,
    required this.onPricePerPcsChanged,
    required this.totalPcsMin,
    required this.totalPcsMax,
    required this.onTotalPcsChanged,
    required this.totalPriceMin,
    required this.totalPriceMax,
    required this.onTotalPriceChanged,
    required this.pricePerCaratMin,
    required this.pricePerCaratMax,
    required this.onPricePerCaratChanged,
    required this.totalCaratMin,
    required this.totalCaratMax,
    required this.onTotalCaratChanged,
    this.caratLimits = const (0.16, 100.0),
    this.pricePerUnitLimits = const (0.0, 200000.0),
    this.pcsLimits = const (1.0, 1000000.0),
    this.totalPriceLimits = const (0.0, 1000000.0),
    super.key,
  });

  final double caratPerPcsMin;
  final double caratPerPcsMax;
  final void Function(double min, double max) onCaratPerPcsChanged;
  final double pricePerPcsMin;
  final double pricePerPcsMax;
  final void Function(double min, double max) onPricePerPcsChanged;
  final double totalPcsMin;
  final double totalPcsMax;
  final void Function(double min, double max) onTotalPcsChanged;
  final double totalPriceMin;
  final double totalPriceMax;
  final void Function(double min, double max) onTotalPriceChanged;
  final double pricePerCaratMin;
  final double pricePerCaratMax;
  final void Function(double min, double max) onPricePerCaratChanged;
  final double totalCaratMin;
  final double totalCaratMax;
  final void Function(double min, double max) onTotalCaratChanged;

  final (double, double) caratLimits;
  final (double, double) pricePerUnitLimits;
  final (double, double) pcsLimits;
  final (double, double) totalPriceLimits;

  @override
  State<MeleeRangeFilters> createState() => _MeleeRangeFiltersState();
}

class _MeleeRangeFiltersState extends State<MeleeRangeFilters> {
  bool _isPcsMode = true;

  static const _gold = Color(0xFFA57A00);
  static const _goldBorder = Color(0xFFD9C58A);
  static const _activeBg = Color(0xFF202534);

  @override
  Widget build(BuildContext context) {
    return FilterGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range Filters',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          if (_isPcsMode) ..._buildPcsFilters(),
          if (!_isPcsMode) ..._buildCaratFilters(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: _goldBorder.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildTab('Pcs', _isPcsMode, () {
            setState(() => _isPcsMode = true);
          }),
          _buildTab('Carat', !_isPcsMode, () {
            setState(() => _isPcsMode = false);
          }),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? _activeBg : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.r8 - 2),
          border: isActive ? Border.all(color: _gold, width: 1) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.white
                : Colors.black54,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPcsFilters() {
    return [
      FilterRangeSlider(
        title: 'Total Price',
        minLimit: widget.totalPriceLimits.$1,
        maxLimit: widget.totalPriceLimits.$2,
        currentMin: widget.totalPriceMin,
        currentMax: widget.totalPriceMax,
        unitSuffix: AppCurrency.symbol,
        isInteger: true,
        onChanged: widget.onTotalPriceChanged,
        onClear: () => widget.onTotalPriceChanged(
          widget.totalPriceLimits.$1,
          widget.totalPriceLimits.$2,
        ),
      ),
      const SizedBox(height: AppSpacing.s20),
      FilterRangeSlider(
        title: 'Carat / Pcs',
        minLimit: widget.caratLimits.$1,
        maxLimit: widget.caratLimits.$2,
        currentMin: widget.caratPerPcsMin,
        currentMax: widget.caratPerPcsMax,
        unitSuffix: 'ct',
        onChanged: widget.onCaratPerPcsChanged,
        onClear: () => widget.onCaratPerPcsChanged(
          widget.caratLimits.$1,
          widget.caratLimits.$2,
        ),
      ),
      const SizedBox(height: AppSpacing.s20),
      FilterRangeSlider(
        title: 'Price / Pcs',
        minLimit: widget.pricePerUnitLimits.$1,
        maxLimit: widget.pricePerUnitLimits.$2,
        currentMin: widget.pricePerPcsMin,
        currentMax: widget.pricePerPcsMax,
        unitSuffix: AppCurrency.symbol,
        isInteger: true,
        onChanged: widget.onPricePerPcsChanged,
        onClear: () => widget.onPricePerPcsChanged(
          widget.pricePerUnitLimits.$1,
          widget.pricePerUnitLimits.$2,
        ),
      ),
      const SizedBox(height: AppSpacing.s20),
      FilterRangeSlider(
        title: 'Total Pcs',
        minLimit: widget.pcsLimits.$1,
        maxLimit: widget.pcsLimits.$2,
        currentMin: widget.totalPcsMin,
        currentMax: widget.totalPcsMax,
        unitSuffix: 'pcs',
        isInteger: true,
        onChanged: widget.onTotalPcsChanged,
        onClear: () => widget.onTotalPcsChanged(
          widget.pcsLimits.$1,
          widget.pcsLimits.$2,
        ),
      ),
    ];
  }

  List<Widget> _buildCaratFilters() {
    return [
      FilterRangeSlider(
        title: 'Total Price',
        minLimit: widget.totalPriceLimits.$1,
        maxLimit: widget.totalPriceLimits.$2,
        currentMin: widget.totalPriceMin,
        currentMax: widget.totalPriceMax,
        unitSuffix: AppCurrency.symbol,
        isInteger: true,
        onChanged: widget.onTotalPriceChanged,
        onClear: () => widget.onTotalPriceChanged(
          widget.totalPriceLimits.$1,
          widget.totalPriceLimits.$2,
        ),
      ),
      const SizedBox(height: AppSpacing.s20),
      FilterRangeSlider(
        title: 'Price / Carat',
        minLimit: widget.pricePerUnitLimits.$1,
        maxLimit: widget.pricePerUnitLimits.$2,
        currentMin: widget.pricePerCaratMin,
        currentMax: widget.pricePerCaratMax,
        unitSuffix: AppCurrency.symbol,
        isInteger: true,
        onChanged: widget.onPricePerCaratChanged,
        onClear: () => widget.onPricePerCaratChanged(
          widget.pricePerUnitLimits.$1,
          widget.pricePerUnitLimits.$2,
        ),
      ),
      const SizedBox(height: AppSpacing.s20),
      FilterRangeSlider(
        title: 'Total Carat',
        minLimit: widget.caratLimits.$1,
        maxLimit: widget.caratLimits.$2,
        currentMin: widget.totalCaratMin,
        currentMax: widget.totalCaratMax,
        unitSuffix: 'ct',
        onChanged: widget.onTotalCaratChanged,
        onClear: () => widget.onTotalCaratChanged(
          widget.caratLimits.$1,
          widget.caratLimits.$2,
        ),
      ),
    ];
  }
}
