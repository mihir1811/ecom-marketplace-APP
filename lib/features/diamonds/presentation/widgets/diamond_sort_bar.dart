import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/diamond_list_provider.dart';

class DiamondSortBar extends ConsumerWidget {
  const DiamondSortBar({super.key});

  static const _options = <_SortOption>[
    _SortOption(DiamondSortField.priceLowHigh, 'Price: Low to High'),
    _SortOption(DiamondSortField.priceHighLow, 'Price: High to Low'),
    _SortOption(DiamondSortField.caratLowHigh, 'Carat: Low to High'),
    _SortOption(DiamondSortField.caratHighLow, 'Carat: High to Low'),
    _SortOption(DiamondSortField.pricePerCaratLowHigh, 'PPC: Low to High'),
    _SortOption(DiamondSortField.pricePerCaratHighLow, 'PPC: High to Low'),
    _SortOption(DiamondSortField.discountHighLow, 'Discount: High to Low'),
    _SortOption(DiamondSortField.popularity, 'Popularity'),
    _SortOption(DiamondSortField.newest, 'Newest'),
    _SortOption(DiamondSortField.cutBestWorst, 'Cut: Best to Worst'),
    _SortOption(DiamondSortField.colorBestWorst, 'Color: Best to Worst'),
    _SortOption(DiamondSortField.clarityBestWorst, 'Clarity: Best to Worst'),
    _SortOption(DiamondSortField.shapeAZ, 'Shape: A to Z'),
  ];

  String _labelFor(DiamondSortField sort) {
    return _options.firstWhere((o) => o.sort == sort).label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primarySort = ref.watch(diamondPrimarySortProvider);
    final secondarySort = ref.watch(diamondSecondarySortProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: 2,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.sort, size: 13, color: mutedColor),
            const SizedBox(width: 4),
            _SortDropdown(
              value: primarySort,
              label: _labelFor(primarySort),
              isDark: isDark,
              onSelected: (sort) {
                if (sort != primarySort) {
                  ref.read(diamondPrimarySortProvider.notifier).state = sort;
                  ref.read(diamondListProvider.notifier).applyFiltersAndSort();
                }
              },
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_downward, size: 10, color: mutedColor),
            const SizedBox(width: 2),
            Text(
              'then',
              style: AppTypography.caption.copyWith(
                color: mutedColor,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 2),
            _SortDropdown(
              value: secondarySort,
              label: _labelFor(secondarySort),
              isDark: isDark,
              onSelected: (sort) {
                if (sort != secondarySort) {
                  ref.read(diamondSecondarySortProvider.notifier).state = sort;
                  ref.read(diamondListProvider.notifier).applyFiltersAndSort();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final DiamondSortField value;
  final String label;
  final bool isDark;
  final ValueChanged<DiamondSortField> onSelected;

  const _SortDropdown({
    required this.value,
    required this.label,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return PopupMenuButton<DiamondSortField>(
      initialValue: value,
      tooltip: 'Change sort order',
      onSelected: onSelected,
      itemBuilder: (context) => DiamondSortBar._options.map((opt) {
        return PopupMenuItem<DiamondSortField>(
          value: opt.sort,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          child: Row(
            children: [
              Icon(
                opt.sort == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 14,
                color: opt.sort == value ? AppColors.bronze : mutedColor,
              ),
              const SizedBox(width: 8),
              Text(
                opt.label,
                style: AppTypography.caption.copyWith(
                  fontWeight: opt.sort == value ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slateSurface : AppColors.warmWhite,
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          border: Border.all(
            color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.bronze,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: AppColors.bronze,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption {
  final DiamondSortField sort;
  final String label;
  const _SortOption(this.sort, this.label);
}
