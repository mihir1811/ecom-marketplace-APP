import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Mean / median / mode and IQR outlier table.
class DiamondProjectPriceStatsCard extends StatelessWidget {
  const DiamondProjectPriceStatsCard({required this.stats, super.key});

  final DiamondProjectStats stats;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(CatalogL10n.priceStats),
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(
                  label: context.tr(CatalogL10n.meanAverage),
                  value: AppCurrency.usd(stats.meanPrice, decimals: 0),
                ),
                _Stat(
                  label: context.tr(CatalogL10n.median),
                  value: AppCurrency.usd(stats.medianPrice, decimals: 0),
                ),
                _Stat(
                  label: context.tr(CatalogL10n.mode),
                  value:
                      '${AppCurrency.usd(stats.modePrice, decimals: 0)} (${stats.modeCount}x)',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              context.tr(CatalogL10n.outliers),
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              context.tr(CatalogL10n.outliersSummary, {
                'count': '${stats.outliers.length}',
                'low': '${AppCurrency.usd(stats.iqrLow, decimals: 0)}/ct',
                'high': '${AppCurrency.usd(stats.iqrHigh, decimals: 0)}/ct',
              }),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            if (stats.outliers.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s12),
              for (final outlier in stats.outliers.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          outlier.item.stockLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          outlier.item.carat.toStringAsFixed(2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${AppCurrency.usd(outlier.item.ppc, decimals: 0)}/ct',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        outlier.isHigh
                            ? context.tr(CatalogL10n.outlierHigh)
                            : context.tr(CatalogL10n.outlierLow),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
