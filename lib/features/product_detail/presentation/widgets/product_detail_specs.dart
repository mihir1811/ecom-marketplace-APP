import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/product_detail.dart';

/// Specification section. Groups always appear in the same canonical order,
/// so the position of a section is predictable across every segment.
class ProductDetailSpecSection extends StatelessWidget {
  const ProductDetailSpecSection({required this.section, super.key});

  final ProductSpecSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s4,
            bottom: AppSpacing.s12,
          ),
          child: Text(
            section.group.title.toUpperCase(),
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(AppSpacing.r20),
            border: Border.all(color: AppColors.border(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.specs.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: AppColors.border(context)),
                _SpecRow(spec: section.specs[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.spec});

  final ProductSpec spec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Expanded(
              flex: 4,
              child: Text(
                spec.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted(context),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              flex: 5,
              child: Text(
                spec.value,
                textAlign: TextAlign.right,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
