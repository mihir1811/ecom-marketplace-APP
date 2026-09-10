import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_error_state.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../domain/models/jewellery_category_admin.dart';
import '../jewellery_category_images.dart';

/// Landing shown from Browse Collection — main category grid from the API.
class JewelryCategoriesScreen extends ConsumerWidget {
  const JewelryCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(jewelleryCategoriesProvider);

    return _buildScreen(context, ref, categories);
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<JewelleryCategoryAdmin>> categories,
  ) {
    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(title: context.tr(CatalogL10n.fineJewelry)),
      body: categories.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, _) => CatalogErrorState(
          message: error is Failure
              ? error.message
              : context.tr(CatalogL10n.loadJewelryCategoriesError),
          onRetry: () => ref.invalidate(jewelleryCategoriesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return CatalogEmptyState(
              icon: Icons.diamond_outlined,
              title: context.tr(CatalogL10n.noCategories),
              message: context.tr(CatalogL10n.categoriesComing),
            );
          }
          return CustomScrollView(
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
                    context.tr(CatalogL10n.shopByCategory),
                    style: AppTypography.title.copyWith(
                      color: AppColors.textPrimary(context),
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = items[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () => context.push(
                        '${AppRouteNames.jewelryListing}?category=${Uri.encodeComponent(category.name)}',
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final JewelleryCategoryAdmin category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = AppColors.card(context);
    final border = AppColors.border(context);
    final muted = AppColors.textMuted(context);
    final styleCount = category.styleCount;
    final isAccessories =
        category.name.trim().toLowerCase() == 'accessories';
    final styleLabel = styleCount <= 0
        ? (isAccessories
              ? ''
              : context.tr(RemainingL10n.comingSoon).replaceAll('.', ''))
        : '$styleCount ${styleCount == 1 ? 'style' : 'styles'}';
    final asset = JewelleryCategoryImages.assetFor(category.name);
    final networkUrl = JewelleryCategoryImages.absoluteUrl(category.imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.r12),
          border: Border.all(color: border),
          boxShadow: isDark ? [] : AppShadows.cardLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: networkUrl == null
                  ? Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: AppColors.surface(context),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: AppColors.bronze,
                          size: 36,
                        ),
                      ),
                    )
                  : AppNetworkImage(
                      url: networkUrl,
                      error: Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: AppColors.surface(context),
                          child: const Icon(
                            Icons.diamond_outlined,
                            color: AppColors.bronze,
                            size: 36,
                          ),
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
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (styleLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      styleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
