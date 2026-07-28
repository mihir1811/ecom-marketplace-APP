import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';

/// The four value-defining attributes of the product, in a fixed grid so the
/// same screen position always answers the same kind of question.
class ProductDetailHighlights extends StatelessWidget {
  const ProductDetailHighlights({required this.highlights, super.key});

  final List<ProductHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r20),
        border: Border.all(color: AppColors.warmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520 ? highlights.length : 2;
          final rows = <List<ProductHighlight>>[];
          for (var i = 0; i < highlights.length; i += columns) {
            rows.add(
              highlights.sublist(
                i,
                (i + columns).clamp(0, highlights.length),
              ),
            );
          }

          return Column(
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0)
                  const Divider(height: 1, color: AppColors.warmBorder),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0)
                          const SizedBox(
                            width: 1,
                            child: ColoredBox(color: AppColors.warmBorder),
                          ),
                        Expanded(
                          child: c < rows[r].length
                              ? _Tile(highlight: rows[r][c])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.highlight});

  final ProductHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            highlight.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMutedLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            highlight.value,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
