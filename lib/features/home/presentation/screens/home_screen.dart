import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/widgets/app_dialog.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:gemstone/core/widgets/app_top_bar.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../buyer/presentation/widgets/buyer_drawer.dart';
import '../../application/home_search_provider.dart';
import '../home_feed_data.dart';
import '../home_network_images.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_brand_row.dart';
import '../widgets/home_category_strip.dart';
import '../widgets/home_editors_grid.dart';
import '../widgets/home_product_rail.dart';
import '../widgets/home_promo_strip.dart';
import '../widgets/home_quick_search.dart';
import '../widgets/home_search_results_list.dart';

/// GemWorld luxury marketplace landing.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          isAuthenticated: s.isAuthenticated,
          isSeller: s.isSeller,
          canTransact: s.canTransact,
        ),
      ),
    );
    final isSearching = ref.watch(
      homeSearchQueryProvider.select((q) => q.trim().isNotEmpty),
    );

    return AppSystemBackScope(
      child: AppScaffold(
        backgroundColor: AppColors.bg(context),
        drawer: auth.isAuthenticated ? const BuyerDrawer() : null,
        appBar: AppTopBar(
          title: 'GemWorld',
          showThemeToggle: true,
          showCart: auth.isAuthenticated,
          showWallet: auth.isAuthenticated,
          showMessages: auth.isAuthenticated,
          onSellerWalletTap: () => context.openRoute(AppRouteNames.buyerWallet),
          onSellerMessagesTap: () =>
              context.openRoute(AppRouteNames.buyerMessages),
          extraActions: !auth.isAuthenticated
              ? [
                  TextButton(
                    onPressed: () => context.openRoute(AppRouteNames.login),
                    child: Text(
                      context.tr(RemainingL10n.login),
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                ]
              : [],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.bg(context),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  AppSpacing.s8,
                  AppSpacing.s20,
                  AppSpacing.s12,
                ),
                child: HomeQuickSearch(),
              ),
            ),
            Expanded(
              child: isSearching
                  ? const HomeSearchResultsList()
                  : _HomeBrowseBody(
                      isAuthenticated: auth.isAuthenticated,
                      isSeller: auth.isSeller,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBrowseBody extends ConsumerWidget {
  const _HomeBrowseBody({
    required this.isAuthenticated,
    required this.isSeller,
  });

  final bool isAuthenticated;
  final bool isSeller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = HomeFeedData.banners(
      diamondsTitle: context.tr(RemainingL10n.homeBannerDiamondsTitle),
      diamondsSubtitle: context.tr(RemainingL10n.homeBannerDiamondsSubtitle),
      jewelryTitle: context.tr(RemainingL10n.homeBannerJewelryTitle),
      jewelrySubtitle: context.tr(RemainingL10n.homeBannerJewelrySubtitle),
      watchesTitle: context.tr(RemainingL10n.homeBannerWatchesTitle),
      watchesSubtitle: context.tr(RemainingL10n.homeBannerWatchesSubtitle),
      shopTheEdit: context.tr(RemainingL10n.homeShopTheEdit),
    );
    final categories = HomeFeedData.categories(
      naturalDiamonds: context.tr(RemainingL10n.naturalDiamonds),
      labGrown: context.tr(RemainingL10n.labGrown),
      gemstones: context.tr(RemainingL10n.gemstones),
      watches: context.tr(RemainingL10n.watches),
      jewelry: context.tr(RemainingL10n.jewelry),
      bullion: context.tr(RemainingL10n.bullion),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeBannerCarousel(
            items: banners,
            onTap: (item) => context.openRoute(item.route),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: Text(
              context.tr(RemainingL10n.shop),
              style: AppTypography.headline.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s16)),
        SliverToBoxAdapter(
          child: HomeCategoryStrip(
            items: categories,
            onTap: (item) => context.openRoute(item.route),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        SliverToBoxAdapter(
          child: HomeProductRail(
            title: context.tr(RemainingL10n.homeNewArrivals),
            seeAllLabel: context.tr(RemainingL10n.homeSeeAll),
            items: HomeFeedData.newArrivals,
            onSeeAll: () => context.openRoute(AppRouteNames.jewelry),
            onItemTap: (item) => context.openRoute(item.route),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        SliverToBoxAdapter(
          child: HomePromoStrip(
            imageUrl: HomeNetworkImages.forSeed(2),
            title: context.tr(RemainingL10n.homePromoTitle),
            subtitle: context.tr(RemainingL10n.homePromoSubtitle),
            ctaLabel: context.tr(RemainingL10n.homePromoCta),
            onTap: () => context.openRoute(AppRouteNames.labGrownDiamonds),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s40)),
        SliverToBoxAdapter(
          child: HomeEditorsGrid(
            title: context.tr(RemainingL10n.homeEditorsPicks),
            items: HomeFeedData.editorsPicks,
            onItemTap: (item) => context.openRoute(item.route),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s40)),
        SliverToBoxAdapter(
          child: HomeBrandRow(
            title: context.tr(RemainingL10n.homeFeaturedHouses),
            items: HomeFeedData.brands,
            onTap: (item) => context.openRoute(item.route),
          ),
        ),
        if (!isSeller) ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: _SellerBanner(
                isAuthenticatedIndividual: isAuthenticated,
                onTap: () => _onSellTap(context, ref),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              0,
              AppSpacing.s20,
              AppSpacing.s16,
            ),
            child: Text(
              context.tr(
                RemainingL10n.certifiedStonesTransparentSellersWorldwideShipping,
              ),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.openRoute(AppRouteNames.aboutUs),
                  child: Text(
                    context.tr(RemainingL10n.aboutGemWorld),
                    style: AppTypography.label.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.openRoute(AppRouteNames.termsAndConditions),
                  child: Text(
                    context.tr(RemainingL10n.termsConditions),
                    style: AppTypography.label.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                TextButton(
                  onPressed: () => context.openRoute(AppRouteNames.policies),
                  child: Text(
                    context.tr(RemainingL10n.policies),
                    style: AppTypography.label.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s16)),
      ],
    );
  }
}

Future<void> _onSellTap(BuildContext context, WidgetRef ref) async {
  final isAuthenticated = ref.read(authProvider).isAuthenticated;
  if (!isAuthenticated) {
    context.openRoute('${AppRouteNames.register}?type=business');
    return;
  }

  final goRegister = await showAppDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr(RemainingL10n.sellerAccountRequired)),
      content: Text(context.tr(RemainingL10n.sellerAccountRequiredBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr(RemainingL10n.notNow)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr(RemainingL10n.createSellerAccount)),
        ),
      ],
    ),
  );
  if (goRegister != true || !context.mounted) return;
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  context.resetTo('${AppRouteNames.register}?type=business');
}

class _SellerBanner extends StatelessWidget {
  const _SellerBanner({
    required this.onTap,
    required this.isAuthenticatedIndividual,
  });

  final VoidCallback onTap;
  final bool isAuthenticatedIndividual;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.selectedFill(context),
      borderRadius: BorderRadius.circular(AppSpacing.r12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(RemainingL10n.sellOnGemWorld),
                      style: AppTypography.title.copyWith(
                        color: AppColors.onSelected(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      isAuthenticatedIndividual
                          ? context.tr(RemainingL10n.sellerSeparateAccountNote)
                          : context.tr(RemainingL10n.sellerRegisterNote),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronzeLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.onSelected(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
