import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../buyer/presentation/widgets/buyer_drawer.dart';
import '../../../cart/application/cart_provider.dart';
import '../../application/home_search_provider.dart';
import '../home_network_images.dart';
import '../widgets/home_category_tile.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_quick_search.dart';
import '../widgets/home_search_results_list.dart';

/// GemWorld marketplace landing — minimal, image-led, one-tap catalog access.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _categories = <_HomeCategory>[
    _HomeCategory(
      title: 'Natural Diamonds',
      subtitle: 'Certified finder',
      imageUrl: HomeNetworkImages.naturalDiamonds,
      route: AppRouteNames.diamonds,
    ),
    _HomeCategory(
      title: 'Lab Grown',
      subtitle: 'CVD & HPHT',
      imageUrl: HomeNetworkImages.labGrown,
      route: AppRouteNames.labGrownDiamonds,
    ),
    _HomeCategory(
      title: 'Gemstones',
      subtitle: 'Ruby to tanzanite',
      imageUrl: HomeNetworkImages.gemstones,
      route: AppRouteNames.gemstones,
    ),
    _HomeCategory(
      title: 'Watches',
      subtitle: 'Luxury brands',
      imageUrl: HomeNetworkImages.watches,
      route: AppRouteNames.watches,
    ),
    _HomeCategory(
      title: 'Jewelry',
      subtitle: 'Rings & more',
      imageUrl: HomeNetworkImages.jewelry,
      route: AppRouteNames.jewelry,
    ),
    _HomeCategory(
      title: 'Bullion',
      subtitle: 'Gold & silver',
      imageUrl: HomeNetworkImages.bullion,
      route: AppRouteNames.bullions,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final auth = ref.watch(
      authProvider.select(
        (s) => (isAuthenticated: s.isAuthenticated, isSeller: s.isSeller),
      ),
    );
    final isSearching =
        ref.watch(homeSearchQueryProvider.select((q) => q.trim().isNotEmpty));

    return AppScaffold(
      backgroundColor: AppColors.creamBg,
      drawer: auth.isAuthenticated ? const BuyerDrawer() : null,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'GemWorld',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Compare',
            onPressed: () => context.push(AppRouteNames.comparison),
            icon: const Icon(Icons.compare_arrows_rounded),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: () => context.push(AppRouteNames.cart),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              backgroundColor: AppColors.bronze,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          if (auth.isAuthenticated && auth.isSeller) ...[
            IconButton(
              tooltip: 'Wallet',
              onPressed: () => context.push(AppRouteNames.buyerWallet),
              icon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            IconButton(
              tooltip: 'Messages',
              onPressed: () => context.push(AppRouteNames.buyerMessages),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ] else if (!auth.isAuthenticated)
            TextButton(
              onPressed: () => context.push(AppRouteNames.login),
              child: Text(
                'Login',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Account',
              onPressed: () => context.go(AppRouteNames.buyerProfile),
              icon: const Icon(Icons.person_outline),
            ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ColoredBox(
            color: AppColors.creamBg,
            child: Padding(
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
              'Shop',
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = HomeScreen._categories[index];
                return HomeCategoryTile(
                  key: ValueKey(item.route),
                  title: item.title,
                  subtitle: item.subtitle,
                  imageUrl: item.imageUrl,
                  onTap: () => context.push(item.route),
                );
              },
              childCount: HomeScreen._categories.length,
            ),
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
              'Certified stones · Transparent sellers · Worldwide shipping',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryLight,
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
                  onPressed: () => context.push(AppRouteNames.aboutUs),
                  child: Text(
                    'About GemWorld',
                    style: AppTypography.label.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(AppRouteNames.termsAndConditions),
                  child: Text(
                    'Terms & Conditions',
                    style: AppTypography.label.copyWith(
                      color: AppColors.bronze,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRouteNames.policies),
                  child: Text(
                    'Policies',
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

  Future<void> _onSellTap(BuildContext context, WidgetRef ref) async {
    if (!isAuthenticated) {
      context.push('${AppRouteNames.register}?type=business');
      return;
    }

    final goRegister = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Separate seller account required'),
        content: const Text(
          'Individual accounts cannot sell products. Create a new business '
          'account with a different email to list and sell on GemWorld. '
          'You will be signed out of this individual account first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create seller account'),
          ),
        ],
      ),
    );
    if (goRegister != true || !context.mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    context.go('${AppRouteNames.register}?type=business');
  }
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
      color: AppColors.charcoal,
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
                      'Sell on GemWorld',
                      style: AppTypography.title.copyWith(
                        color: AppColors.warmWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      isAuthenticatedIndividual
                          ? 'Selling needs a separate business account — not this individual login.'
                          : 'Register a business account to list diamonds, gems, and jewelry.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.bronzeLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.warmWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
