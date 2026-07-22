import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class JewelryMainCategory {
  const JewelryMainCategory({
    required this.title,
    required this.filterValue,
    required this.imageAsset,
    required this.styleCount,
  });

  final String title;
  final String filterValue;
  final String imageAsset;
  final int styleCount;
}

const jewelryMainCategories = [
  JewelryMainCategory(
    title: 'Accessories',
    filterValue: 'All Accessories',
    imageAsset: 'public/images/jewelryCategoryImages/set.webp',
    styleCount: 8,
  ),
  JewelryMainCategory(
    title: 'Bracelet',
    filterValue: 'Bracelets',
    imageAsset: 'public/images/jewelryCategoryImages/bracelet.webp',
    styleCount: 5,
  ),
  JewelryMainCategory(
    title: 'Chains',
    filterValue: 'Chains',
    imageAsset: 'public/images/jewelryCategoryImages/necklace.webp',
    styleCount: 1,
  ),
  JewelryMainCategory(
    title: 'Earrings',
    filterValue: 'Earrings',
    imageAsset: 'public/images/jewelryCategoryImages/earrings.webp',
    styleCount: 4,
  ),
  JewelryMainCategory(
    title: 'Necklace',
    filterValue: 'Necklaces',
    imageAsset: 'public/images/jewelryCategoryImages/necklace.webp',
    styleCount: 4,
  ),
  JewelryMainCategory(
    title: 'Ring',
    filterValue: 'Rings',
    imageAsset: 'public/images/jewelryCategoryImages/ring.webp',
    styleCount: 6,
  ),
];

/// Landing shown from Browse Collection — main category grid.
class JewelryCategoriesScreen extends StatelessWidget {
  const JewelryCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        automaticallyImplyActions: false,
        title: Text(
          'Fine Jewelry',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouteNames.home);
            }
          },
        ),
        actions: const [],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Text(
                'Shop by category',
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.s12,
                mainAxisSpacing: AppSpacing.s12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = jewelryMainCategories[index];
                  return _CategoryCard(
                    category: category,
                    onTap: () => context.push(
                      '${AppRouteNames.jewelryListing}?category=${Uri.encodeComponent(category.filterValue)}',
                    ),
                  );
                },
                childCount: jewelryMainCategories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final JewelryMainCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.warmWhite;
    final border = AppColors.warmBorder;
    final muted = AppColors.textMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: border),
          boxShadow: AppShadows.cardLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                category.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(
                  color: AppColors.sandSurface,
                  child: const Icon(
                    Icons.diamond_outlined,
                    color: AppColors.bronze,
                    size: 36,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s8,
                AppSpacing.s12,
                AppSpacing.s8,
                AppSpacing.s12,
              ),
              child: Column(
                children: [
                  Text(
                    category.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.styleCount} styles',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontSize: 12,
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
