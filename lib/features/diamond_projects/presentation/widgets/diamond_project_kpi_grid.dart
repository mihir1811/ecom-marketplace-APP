import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Six KPI tiles in a compact 3×2 grid.
class DiamondProjectKpiGrid extends StatelessWidget {
  const DiamondProjectKpiGrid({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (context.tr(CatalogL10n.projectStonesKpi), '${stats.stones}'),
      (
        context.tr(CatalogL10n.projectTotalCaratKpi),
        '${stats.totalCarat.toStringAsFixed(2)} ct',
      ),
      (
        context.tr(CatalogL10n.projectAvgCaratKpi),
        '${stats.avgCarat.toStringAsFixed(2)} ct',
      ),
      (
        context.tr(CatalogL10n.projectTotalPriceKpi),
        AppCurrency.usd(stats.totalPrice, decimals: 0),
      ),
      (
        context.tr(CatalogL10n.projectAvgPriceKpi),
        AppCurrency.usd(stats.avgPrice, decimals: 0),
      ),
      (
        context.tr(CatalogL10n.projectAvgPpcKpi),
        AppCurrency.usd(stats.avgPpc, decimals: 0),
      ),
    ];

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _KpiCard(
                    label: tiles[row * 3 + col].$1,
                    value: tiles[row * 3 + col].$2,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
