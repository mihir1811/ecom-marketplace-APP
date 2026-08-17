import 'package:flutter/material.dart';

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
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price stats',
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(
                  label: 'MEAN (AVG)',
                  value: AppCurrency.usd(stats.meanPrice, decimals: 0),
                ),
                _Stat(
                  label: 'MEDIAN',
                  value: AppCurrency.usd(stats.medianPrice, decimals: 0),
                ),
                _Stat(
                  label: 'MODE',
                  value:
                      '${AppCurrency.usd(stats.modePrice, decimals: 0)} (${stats.modeCount}x)',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'OUTLIERS',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Count: ${stats.outliers.length}  ·  IQR fences ${AppCurrency.usd(stats.iqrLow, decimals: 0)} - ${AppCurrency.usd(stats.iqrHigh, decimals: 0)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
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
                          style: AppTypography.caption,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          outlier.item.carat.toStringAsFixed(2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppCurrency.usd(outlier.item.price, decimals: 0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        outlier.isHigh ? 'High' : 'Low',
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
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
