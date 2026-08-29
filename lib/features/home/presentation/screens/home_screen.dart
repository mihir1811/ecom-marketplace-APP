import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gemstone/core/widgets/app_dialog.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:gemstone/core/widgets/app_top_bar.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../buyer/presentation/widgets/buyer_drawer.dart';
import '../../application/home_search_provider.dart';
import '../home_network_images.dart';
import '../widgets/home_category_tile.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_quick_search.dart';
import '../widgets/home_search_results_list.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// GemWorld marketplace landing — minimal, image-led, one-tap catalog access.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static List<_HomeCategory> _categories(BuildContext context) =>
      <_HomeCategory>[
        _HomeCategory(
          title: context.tr(RemainingL10n.naturalDiamonds),
          subtitle: context.tr(RemainingL10n.certifiedFinder),
          imageUrl: HomeNetworkImages.naturalDiamonds,
          route: AppRouteNames.diamonds,
        ),
        _HomeCategory(
          title: context.tr(RemainingL10n.labGrown),
          subtitle: context.tr(RemainingL10n.cvdHpht),
          imageUrl: HomeNetworkImages.labGrown,
          route: AppRouteNames.labGrownDiamonds,
        ),
        _HomeCategory(
          title: context.tr(RemainingL10n.gemstones),
          subtitle: context.tr(RemainingL10n.rubyToTanzanite),
          imageUrl: HomeNetworkImages.gemstones,
          route: AppRouteNames.gemstones,
        ),
        _HomeCategory(
          title: context.tr(RemainingL10n.watches),
          subtitle: context.tr(RemainingL10n.luxuryBrands),
          imageUrl: HomeNetworkImages.watches,
          route: AppRouteNames.watches,
        ),
        _HomeCategory(
          title: context.tr(RemainingL10n.jewelry),
          subtitle: context.tr(RemainingL10n.ringsAndMore),
          imageUrl: HomeNetworkImages.jewelry,
          route: AppRouteNames.jewelry,
        ),
        _HomeCategory(
          title: context.tr(RemainingL10n.bullion),
          subtitle: context.tr(RemainingL10n.goldSilver),
          imageUrl: HomeNetworkImages.bullion,
          route: AppRouteNames.bullions,
        ),
      ];

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

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      drawer: auth.isAuthenticated ? BuyerDrawer() : null,
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
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeHero(
            imageUrl: HomeNetworkImages.hero,
            onPrimary: (ctx) => ctx.push(AppRouteNames.diamonds),
            onSecondary: (ctx) => ctx.push(AppRouteNames.jewelry),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
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
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.s12,
              crossAxisSpacing: AppSpacing.s12,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = HomeScreen._categories(context)[index];
              return HomeCategoryTile(
                key: ValueKey(item.route),
                title: item.title,
                subtitle: item.subtitle,
                imageUrl: item.imageUrl,
                onTap: () => context.openRoute(item.route),
              );
            }, childCount: HomeScreen._categories(context).length),
          ),
        ),
        if (!isSeller) ...[
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s24)),
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
                RemainingL10n
                    .certifiedStonesTransparentSellersWorldwideShipping,
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

class _HomeCategory {
  const _HomeCategory({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String route;
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
