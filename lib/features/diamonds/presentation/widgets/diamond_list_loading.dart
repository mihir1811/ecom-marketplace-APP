import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DiamondListLoading extends StatelessWidget {
  final bool isGrid;

  const DiamondListLoading({super.key, this.isGrid = true});

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
        itemBuilder: (context, index) => _buildShimmerCard(context),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) => _buildShimmerRow(context),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    final base = AppColors.sandSurface;
    final highlight = AppColors.warmWhite;

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
                Container(height: 14, width: 80, decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                )),
                const SizedBox(height: AppSpacing.s8),
                Container(height: 10, width: 120, decoration: BoxDecoration(
                  color: highlight,
                  borderRadius: BorderRadius.circular(AppSpacing.r4),
                )),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    Container(height: 18, width: 50, decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(AppSpacing.r4),
                    )),
                    const SizedBox(width: AppSpacing.s8),
                    Container(height: 18, width: 30, decoration: BoxDecoration(
                      color: highlight,
                      borderRadius: BorderRadius.circular(AppSpacing.r4),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow(BuildContext context) {
    final base = AppColors.sandSurface;
    final highlight = AppColors.warmWhite;

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
            decoration: BoxDecoration(
              color: highlight,
              borderRadius: const BorderRadius.horizontal(
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
                  Container(height: 14, width: 100, decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  )),
                  const SizedBox(height: AppSpacing.s8),
                  Container(height: 10, width: 160, decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  )),
                  const SizedBox(height: AppSpacing.s8),
                  Container(height: 10, width: 80, decoration: BoxDecoration(
                    color: highlight,
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
