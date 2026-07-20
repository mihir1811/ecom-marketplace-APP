import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/router/route_names.dart';
import '../../application/diamond_search_provider.dart';
import '../../domain/models/diamond_catalog_type.dart';

class SearchBottomBar extends ConsumerWidget {
  const SearchBottomBar({
    super.key,
    this.onClear,
    this.resultsRoute = AppRouteNames.diamondResults,
  });

  final VoidCallback? onClear;
  final String resultsRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(matchingCountProvider);
    final notifier = ref.read(diamondSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(diamondSearchProvider);
    final catalog = ref.watch(diamondCatalogTypeProvider);
    final useMelee = catalog.isLabGrown
        ? filterState.labCategory == 'Lab Melee'
        : filterState.labNatural.usesMeleeFilters;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: AppColors.surfaceBg(isDark: isDark, melee: useMelee),
      ),
      duration: AppColors.meleeBgDuration,
      curve: Curves.easeInOutCubic,
      builder: (context, color, child) {
        return Container(
          decoration: BoxDecoration(
            color: color,
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
          child: child,
        );
      },
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
              onPressed: () {
                context.push(resultsRoute);
              },
              child: Text(
                'SHOW ${count.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} DIAMONDS',
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
            onTap: () {
              notifier.reset();
              onClear?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'CLEAR ALL FILTERS',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
