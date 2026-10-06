import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import 'filter_group_card.dart';
import 'filter_range_slider.dart';
import '../../../core/utils/app_currency.dart';

/// Standard (non-melee) catalog range filters shared by diamond and gemstone search.
///
/// Renders Total Price, Total Carat and Price / Carat, each with a drag bar.
class CatalogStandardRangeFilters extends StatelessWidget {
  const CatalogStandardRangeFilters({
    required this.totalPriceMin,
    required this.totalPriceMax,
    required this.totalPriceLimits,
    required this.onTotalPriceChanged,
    required this.totalCaratMin,
    required this.totalCaratMax,
    required this.totalCaratLimits,
    required this.onTotalCaratChanged,
    required this.pricePerCaratMin,
    required this.pricePerCaratMax,
    required this.pricePerCaratLimits,
    required this.onPricePerCaratChanged,
    this.pricePerCaratTitle,
    super.key,
  });

  final double totalPriceMin;
  final double totalPriceMax;
  final (double, double) totalPriceLimits;
  final void Function(double min, double max) onTotalPriceChanged;

  final double totalCaratMin;
  final double totalCaratMax;
  final (double, double) totalCaratLimits;
  final void Function(double min, double max) onTotalCaratChanged;

  final double pricePerCaratMin;
  final double pricePerCaratMax;
  final (double, double) pricePerCaratLimits;
  final void Function(double min, double max) onPricePerCaratChanged;
  final String? pricePerCaratTitle;

  @override
  Widget build(BuildContext context) {
    return FilterGroupCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterRangeSlider(
            showRangeSummary: false,
            syncInputsWhileDragging: true,
            title: context.tr(CatalogL10n.totalPrice),
            minLimit: totalPriceLimits.$1,
            maxLimit: totalPriceLimits.$2,
            currentMin: totalPriceMin,
            currentMax: totalPriceMax,
            unitSuffix: AppCurrency.symbol,
            isInteger: true,
            onChanged: onTotalPriceChanged,
            onClear: () =>
                onTotalPriceChanged(totalPriceLimits.$1, totalPriceLimits.$2),
          ),
          const SizedBox(height: AppSpacing.s20),
          FilterRangeSlider(
            showRangeSummary: false,
            syncInputsWhileDragging: true,
            title: context.tr(CatalogL10n.totalCarat),
            minLimit: totalCaratLimits.$1,
            maxLimit: totalCaratLimits.$2,
            currentMin: totalCaratMin,
            currentMax: totalCaratMax,
            unitSuffix: ' ct',
            onChanged: onTotalCaratChanged,
            onClear: () =>
                onTotalCaratChanged(totalCaratLimits.$1, totalCaratLimits.$2),
          ),
          const SizedBox(height: AppSpacing.s20),
          FilterRangeSlider(
            showRangeSummary: false,
            syncInputsWhileDragging: true,
            title: pricePerCaratTitle ?? context.tr(CatalogL10n.pricePerCarat),
            minLimit: pricePerCaratLimits.$1,
            maxLimit: pricePerCaratLimits.$2,
            currentMin: pricePerCaratMin,
            currentMax: pricePerCaratMax,
            unitSuffix: AppCurrency.symbol,
            isInteger: true,
            onChanged: onPricePerCaratChanged,
            onClear: () => onPricePerCaratChanged(
              pricePerCaratLimits.$1,
              pricePerCaratLimits.$2,
            ),
          ),
        ],
      ),
    );
  }
}
