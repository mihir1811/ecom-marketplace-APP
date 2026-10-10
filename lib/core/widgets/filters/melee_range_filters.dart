import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'filter_group_card.dart';
import 'filter_range_slider.dart';
import 'filter_section_divider.dart';
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
    this.caratLimits = const (0.20, 50.0),
    this.caratPerPcsLimits = const (0.001, 1.0),
    this.pricePerUnitLimits = const (0.0, 5000.0),
    this.pcsLimits = const (1.0, 100000.0),
    this.totalPriceLimits = const (0.0, 250000.0),
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
  final (double, double) caratPerPcsLimits;
  final (double, double) pricePerUnitLimits;
  final (double, double) pcsLimits;
  final (double, double) totalPriceLimits;

  @override
  State<MeleeRangeFilters> createState() => _MeleeRangeFiltersState();
}

class _MeleeRangeFiltersState extends State<MeleeRangeFilters> {
  bool _isPcsMode = true;

  static Color get _gold => AppColors.bronze;
  static Color get _goldBorder => AppColors.bronzeLight;

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
                context.tr(CatalogL10n.rangeFilters),
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              _buildToggle(context),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          if (_isPcsMode) ..._buildPcsFilters(),
          if (!_isPcsMode) ..._buildCaratFilters(),
        ],
      ),
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: _goldBorder.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildTab(context, context.tr(CatalogL10n.pieces), _isPcsMode, () {
            setState(() => _isPcsMode = true);
          }),
          _buildTab(context, context.tr(CatalogL10n.carat), !_isPcsMode, () {
            setState(() => _isPcsMode = false);
          }),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.selectedFill(context)
              : AppColors.card(context),
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
                ? AppColors.onSelected(context)
                : AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPcsFilters() {
    return [
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.totalPrice),
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
      const FilterSectionDivider(),
      _caratPerPcsSlider(),
      const FilterSectionDivider(),
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.pricePerPiece),
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
      const FilterSectionDivider(),
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.totalPieces),
        minLimit: widget.pcsLimits.$1,
        maxLimit: widget.pcsLimits.$2,
        currentMin: widget.totalPcsMin,
        currentMax: widget.totalPcsMax,
        unitSuffix: 'pcs',
        isInteger: true,
        onChanged: widget.onTotalPcsChanged,
        onClear: () =>
            widget.onTotalPcsChanged(widget.pcsLimits.$1, widget.pcsLimits.$2),
      ),
    ];
  }

  Widget _caratPerPcsSlider() {
    return FilterRangeSlider(
      showRangeSummary: false,
      syncInputsWhileDragging: true,
      title: context.tr(CatalogL10n.caratPerPiece),
      minLimit: widget.caratPerPcsLimits.$1,
      maxLimit: widget.caratPerPcsLimits.$2,
      currentMin: widget.caratPerPcsMin,
      currentMax: widget.caratPerPcsMax,
      unitSuffix: 'ct',
      onChanged: widget.onCaratPerPcsChanged,
      onClear: () => widget.onCaratPerPcsChanged(
        widget.caratPerPcsLimits.$1,
        widget.caratPerPcsLimits.$2,
      ),
    );
  }

  List<Widget> _buildCaratFilters() {
    return [
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.totalPrice),
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
      const FilterSectionDivider(),
      _caratPerPcsSlider(),
      const FilterSectionDivider(),
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.pricePerCarat),
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
      const FilterSectionDivider(),
      FilterRangeSlider(
        showRangeSummary: false,
        syncInputsWhileDragging: true,
        title: context.tr(CatalogL10n.totalCarat),
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
