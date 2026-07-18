import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/gemstone_search_provider.dart';

/// Sticky bottom action bar with the primary "Search Gemstones" button and
/// a secondary "Clear Filters" action. Mirrors the diamond search bottom bar.
class GemstoneSearchBottomBar extends ConsumerWidget {
  const GemstoneSearchBottomBar({super.key, this.onSearch});

  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(matchingGemstoneCountProvider);
    final notifier = ref.read(gemstoneSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formattedCount = count.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoalDark : AppColors.creamBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.slateBorder : AppColors.warmBorder,
          ),
        ),
        boxShadow: AppShadows.modalLight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s24,
        vertical: AppSpacing.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: AppColors.warmWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r8),
                ),
              ),
              onPressed: onSearch,
              child: Text(
                'SEARCH $formattedCount GEMSTONES',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warmWhite,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          GestureDetector(
            onTap: () => notifier.reset(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'CLEAR FILTERS',
                style: AppTypography.caption.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
