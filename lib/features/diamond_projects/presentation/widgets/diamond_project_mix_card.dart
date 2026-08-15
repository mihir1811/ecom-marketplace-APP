import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/diamond_project_stats.dart';

/// Horizontal bar mix (shape / color / clarity).
class DiamondProjectMixCard extends StatelessWidget {
  const DiamondProjectMixCard({
    required this.title,
    required this.entries,
    super.key,
  });

  final String title;
  final List<NamedCount> entries;

  @override
  Widget build(BuildContext context) {
    final max = entries.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    return _ProjectCard(
      title: title,
      child: entries.isEmpty
          ? Text(
              'No data',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMutedLight,
              ),
            )
          : Column(
              children: [
                for (final entry in entries) ...[
                  _MixRow(entry: entry, max: max == 0 ? 1 : max),
                  const SizedBox(height: AppSpacing.s8),
                ],
              ],
            ),
    );
  }
}

class _MixRow extends StatelessWidget {
  const _MixRow({required this.entry, required this.max});

  final NamedCount entry;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            entry.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.r4),
            child: LinearProgressIndicator(
              value: entry.count / max,
              minHeight: 10,
              backgroundColor: AppColors.sandSurface,
              color: AppColors.charcoal,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '${entry.count}',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
              title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            child,
          ],
        ),
      ),
    );
  }
}
