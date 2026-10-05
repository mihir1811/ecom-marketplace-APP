import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_stats.dart';
import 'diamond_project_panel.dart';

/// Mean / median / mode and IQR outlier table.
class DiamondProjectPriceStatsCard extends StatelessWidget {
  const DiamondProjectPriceStatsCard({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return DiamondProjectPanel(
      title: context.tr(CatalogL10n.priceStats),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: context.tr(CatalogL10n.meanAverage),
                    value: AppCurrency.usd(stats.meanPrice, decimals: 0),
                  ),
                ),
                VerticalDivider(width: 20, color: p.hairline),
                Expanded(
                  child: _Stat(
                    label: context.tr(CatalogL10n.median),
                    value: AppCurrency.usd(stats.medianPrice, decimals: 0),
                  ),
                ),
                VerticalDivider(width: 20, color: p.hairline),
                Expanded(
                  child: _Stat(
                    label: context.tr(CatalogL10n.mode),
                    value: AppCurrency.usd(stats.modePrice, decimals: 0),
                    note: '${stats.modeCount}x',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: stats.outliers.isEmpty
                  ? p.surfaceRaised
                  : p.caution.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      stats.outliers.isEmpty
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: stats.outliers.isEmpty ? p.positive : p.caution,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr(CatalogL10n.outliers),
                      style: LuxeType.label(p.ink, size: 13.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(CatalogL10n.outliersSummary, {
                    'count': '${stats.outliers.length}',
                    'low': '${AppCurrency.usd(stats.iqrLow, decimals: 0)}/ct',
                    'high': '${AppCurrency.usd(stats.iqrHigh, decimals: 0)}/ct',
                  }),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.body(p.inkMuted, size: 12.5),
                ),
                if (stats.outliers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final outlier in stats.outliers.take(8))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              outlier.item.stockLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxeType.label(p.ink, size: 12.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              outlier.item.carat.toStringAsFixed(2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxeType.figure(p.inkMuted, size: 12.5),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${AppCurrency.usd(outlier.item.ppc, decimals: 0)}/ct',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxeType.figure(p.caution, size: 12.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: ShapeDecoration(
                              color: p.caution.withValues(alpha: 0.14),
                              shape: const StadiumBorder(),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  outlier.isHigh
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 11,
                                  color: p.caution,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  outlier.isHigh
                                      ? context.tr(CatalogL10n.outlierHigh)
                                      : context.tr(CatalogL10n.outlierLow),
                                  style: LuxeType.label(p.caution, size: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LuxeType.eyebrow(
            p.inkMuted,
          ).copyWith(fontSize: 9.5, letterSpacing: 1.6),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: LuxeType.figure(
              p.ink,
              size: 17,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (note != null)
          Text(note!, style: LuxeType.label(p.inkFaint, size: 11)),
      ],
    );
  }
}
