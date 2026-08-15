import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shimmer placeholder for catalog grid/list loading.
class CatalogListLoading extends StatelessWidget {
  const CatalogListLoading({super.key, this.isGrid = true});

  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.s16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.s12,
          mainAxisSpacing: AppSpacing.s12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerCard(),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) => _buildShimmerRow(),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }

  Widget _buildShimmerCard() {
    const base = AppColors.sandSurface;
    const highlight = AppColors.warmWhite;

    return Container(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(color: highlight),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    Container(
                      height: 18,
                      width: 50,
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      height: 18,
                      width: 30,
                      decoration: BoxDecoration(
                        color: highlight,
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    const base = AppColors.sandSurface;
    const highlight = AppColors.warmWhite;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: highlight,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppSpacing.r12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(AppSpacing.r4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    height: 10,
                    width: 160,
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(AppSpacing.r4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(AppSpacing.r4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
