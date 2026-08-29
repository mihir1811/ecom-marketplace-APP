import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Vertical histogram for price / $/ct / carat buckets.
class DiamondProjectHistogramCard extends StatelessWidget {
  const DiamondProjectHistogramCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<NamedCount> entries;

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final barColor = AppColors.textPrimary(context);
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
              title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (entries.isEmpty)
              Text(
                context.tr(CatalogL10n.projectNoData),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final entry in entries)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                          ),
                          child: _Bar(
                            entry: entry,
                            max: max == 0 ? 1 : max,
                            barColor: barColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.entry,
    required this.max,
    required this.barColor,
  });

  final NamedCount entry;
  final int max;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${entry.count}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: (entry.count / max).clamp(0.06, 1),
              widthFactor: 0.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          entry.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
