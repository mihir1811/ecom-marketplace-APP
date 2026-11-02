import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Project KPI tiles. Totals (stones, carat, value) lead the hero, so by
/// default this shows the three averages; pass [includeTotals] for all six.
class DiamondProjectKpiGrid extends StatelessWidget {
  const DiamondProjectKpiGrid({
    required this.stats,
    super.key,
    this.includeTotals = false,
  });

  final DiamondProjectStats stats;
  final bool includeTotals;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      if (includeTotals) ...[
        (
          context.tr(CatalogL10n.projectStonesKpi),
          '${stats.stones}',
          Icons.diamond_outlined,
        ),
        (
          context.tr(CatalogL10n.projectTotalCaratKpi),
          '${stats.totalCarat.toStringAsFixed(2)} ct',
          Icons.scale_outlined,
        ),
        (
          context.tr(CatalogL10n.projectTotalPriceKpi),
          AppCurrency.usd(stats.totalPrice, decimals: 0),
          Icons.payments_outlined,
        ),
      ],
      (
        context.tr(CatalogL10n.projectAvgCaratKpi),
        '${stats.avgCarat.toStringAsFixed(2)} ct',
        Icons.straighten_rounded,
      ),
      (
        context.tr(CatalogL10n.projectAvgPriceKpi),
        AppCurrency.usd(stats.avgPrice, decimals: 0),
        Icons.sell_outlined,
      ),
      (
        context.tr(CatalogL10n.projectAvgPpcKpi),
        AppCurrency.usd(stats.avgPpc, decimals: 0),
        Icons.query_stats_rounded,
      ),
    ];

    final rows = (tiles.length / 3).ceil();
    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: row * 3 + col < tiles.length
                        ? _KpiCard(
                            label: tiles[row * 3 + col].$1,
                            value: tiles[row * 3 + col].$2,
                            icon: tiles[row * 3 + col].$3,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 2),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: p.accent),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: LuxeType.figure(
                p.ink,
                size: 16,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(p.inkMuted, size: 11),
          ),
        ],
      ),
    );
  }
}
