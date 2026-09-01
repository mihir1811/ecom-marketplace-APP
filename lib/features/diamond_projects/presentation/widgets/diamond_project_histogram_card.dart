import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/chart_value_tooltip.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Vertical histogram for price / $/ct / carat buckets.
class DiamondProjectHistogramCard extends StatefulWidget {
  const DiamondProjectHistogramCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<NamedCount> entries;

  @override
  State<DiamondProjectHistogramCard> createState() =>
      _DiamondProjectHistogramCardState();
}

class _DiamondProjectHistogramCardState
    extends State<DiamondProjectHistogramCard> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant DiamondProjectHistogramCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.entries.fold<int>(
      0,
      (m, e) => e.count > m ? e.count : m,
    );
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
              widget.title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (widget.entries.isEmpty)
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
                    for (var i = 0; i < widget.entries.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s4,
                          ),
                          child: _Bar(
                            entry: widget.entries[i],
                            max: max == 0 ? 1 : max,
                            barColor: barColor,
                            selected: _selectedIndex == i,
                            showTooltip: _selectedIndex == i,
                            onTap: () {
                              setState(() {
                                _selectedIndex =
                                    _selectedIndex == i ? null : i;
                              });
                            },
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
    required this.selected,
    required this.showTooltip,
    required this.onTap,
  });

  final NamedCount entry;
  final int max;
  final Color barColor;
  final bool selected;
  final bool showTooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              Text(
                '${entry.count}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.info
                      : AppColors.textPrimary(context),
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
                        color: selected
                            ? barColor.withValues(alpha: 0.85)
                            : barColor,
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                        border: selected
                            ? Border.all(color: AppColors.info, width: 2)
                            : null,
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
          ),
          if (showTooltip)
            Positioned(
              top: -36,
              child: ChartValueTooltip(
                label: entry.label,
                value: '${entry.count}',
              ),
            ),
        ],
      ),
    );
  }
}
