import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_swatches.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/seller_inquiry.dart';

/// Step-1 category cards that load the matching inquiry form.
class InquiryCategoryPicker extends StatelessWidget {
  const InquiryCategoryPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final InquiryCategory? selected;
  final ValueChanged<InquiryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        const columns = 3;
        const gap = AppSpacing.s12;
        final tileW = (maxW - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in InquiryCategory.values)
              SizedBox(
                width: tileW,
                child: _CategoryCard(
                  category: category,
                  selected: selected == category,
                  onTap: () => onSelected(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final InquiryCategory category;
  final bool selected;
  final VoidCallback onTap;

  Color _accent(BuildContext context) => switch (category) {
    InquiryCategory.diamond => AppColors.info,
    InquiryCategory.gemstone => AppSwatches.inquiryGemstone,
    InquiryCategory.bullion => AppSwatches.inquiryBullion,
    InquiryCategory.watch => AppColors.textSecondary(context),
    InquiryCategory.jewelry => AppSwatches.inquiryJewelry,
  };

  IconData get _icon => switch (category) {
    InquiryCategory.diamond => Icons.diamond_outlined,
    InquiryCategory.gemstone => Icons.auto_awesome,
    InquiryCategory.bullion => Icons.link,
    InquiryCategory.watch => Icons.watch_outlined,
    InquiryCategory.jewelry => Icons.workspace_premium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.12)
          : AppColors.card(context),
      borderRadius: BorderRadius.circular(AppSpacing.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            border: Border.all(
              color: selected ? accent : AppColors.border(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s24,
            ),
            child: Column(
              children: [
                Icon(_icon, color: accent, size: 28),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
