import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewelry_filter_state.dart';

/// Style sub-filters for the current parent category on the listing screen.
class JewelryCategoryChips extends ConsumerWidget {
  const JewelryCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jewelryFilterProvider);
    final parent = JewelryFilterState.parentCategoryOrDefault(filters.category);
    final subs = JewelryFilterState.subCategoriesFor(parent);
    final allLabel = JewelryFilterState.allSubCategoryLabel(parent);
    final selected = filters.subCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = [allLabel, ...subs];

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, index) {
            final label = chips[index];
            final isAll = index == 0;
            final active = isAll
                ? selected.isEmpty
                : selected.contains(label);
            return GestureDetector(
              onTap: () {
                final n = ref.read(jewelryFilterProvider.notifier);
                if (isAll) {
                  n.clearSubCategories();
                } else {
                  n.toggleSubCategory(label);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.charcoal
                      : (isDark ? AppColors.obsidianBg : AppColors.warmWhite),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppColors.charcoal
                        : (isDark
                            ? AppColors.slateBorder
                            : AppColors.warmBorder),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.warmWhite
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
