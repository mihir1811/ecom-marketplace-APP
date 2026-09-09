import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/jewellery_category_admin.dart';
import '../../domain/models/jewelry_filter_state.dart';

/// Style sub-filters for the current parent category — names from the API only.
class JewelryCategoryChips extends ConsumerWidget {
  const JewelryCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(jewelryFilterProvider);
    final liveAsync = ref.watch(jewelleryCategoriesProvider);
    final parent = JewelryFilterState.parentCategoryOrDefault(filters.category);
    final allLabel = JewelryFilterState.allSubCategoryLabel(parent);

    return liveAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox.shrink(),
      data: (live) {
        final matched = JewelleryCategoryMatch.find(live, filters.category);
        final List<String> subs;
        if (matched != null) {
          subs = [
            for (final sub in matched.subcategories)
              if (sub.isActive && sub.name.trim().isNotEmpty) sub.name,
          ];
        } else if (parent == 'All Accessories') {
          // Aggregate every active backend style under the accessories landing.
          final seen = <String>{};
          subs = [
            for (final cat in live)
              for (final sub in cat.subcategories)
                if (sub.isActive &&
                    sub.name.trim().isNotEmpty &&
                    seen.add(sub.name.trim()))
                  sub.name.trim(),
          ];
        } else {
          subs = const [];
        }

        final selected = filters.subCategories;
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
                final active =
                    isAll ? selected.isEmpty : selected.contains(label);
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.selectedFill(context)
                          : AppColors.card(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? AppColors.selectedFill(context)
                            : AppColors.border(context),
                      ),
                    ),
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? AppColors.onSelected(context)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
