import 'package:flutter/material.dart';

import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../home/presentation/home_network_images.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

/// Public About Us page for GemWorld — mission, values, and marketplace overview.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static List<_ValueItem> _values(BuildContext context) => <_ValueItem>[
    _ValueItem(
      icon: Icons.verified_outlined,
      title: context.tr(RemainingL10n.qualityVerify),
      body: context.tr(
        RemainingL10n.everyListingHighlightsCertificationGradingAnd,
      ),
    ),
    _ValueItem(
      icon: Icons.visibility_outlined,
      title: context.tr(RemainingL10n.transparencyEveryStep),
      body: context.tr(RemainingL10n.clearPricingDetailedSpecificationsAndRich),
    ),
    _ValueItem(
      icon: Icons.support_agent_outlined,
      title: context.tr(RemainingL10n.expertGuidance),
      body: context.tr(RemainingL10n.fromComparingNaturalAndLabGrown),
    ),
    _ValueItem(
      icon: Icons.handshake_outlined,
      title: context.tr(RemainingL10n.builtForBuyersSellers),
      body: context.tr(RemainingL10n.weConnectVerifiedIndianSellersWith),
    ),
  ];

  static List<_StatItem> _stats(BuildContext context) => <_StatItem>[
    _StatItem(value: '6', label: context.tr(RemainingL10n.coreCategories)),
    _StatItem(
      value: 'Pan-India',
      label: context.tr(RemainingL10n.marketplaceReach),
    ),
    _StatItem(
      value: 'GIA · IGI',
      label: context.tr(RemainingL10n.certification),
    ),
    _StatItem(value: '24/7', label: context.tr(RemainingL10n.supportTickets)),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 720;

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: SimpleAppTopBar(
        title: context.tr(RemainingL10n.aboutGemWorld),
        backgroundColor: AppColors.bg(context),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HeroBanner(isWide: isWide)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.s48 : AppSpacing.s20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.s32),
                _Section(
                  eyebrow: context.tr(RemainingL10n.ourStory),
                  title: context.tr(RemainingL10n.trustedMarketplaceTitle),
                  body: context.tr(RemainingL10n.gemworldWasBuiltOnASimple),
                ),
                const SizedBox(height: AppSpacing.s24),
                const _PromiseSection(),
                const SizedBox(height: AppSpacing.s32),
                _StatsRow(stats: _stats(context), isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                _Section(
                  eyebrow: context.tr(RemainingL10n.whatWeDo),
                  title: context.tr(RemainingL10n.onePlatformTrade),
                  body: context.tr(
                    RemainingL10n.gemworldBringsTogetherNaturalDiamondsLab,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                _CategoryChips(isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                Text(
                  context.tr(RemainingL10n.ourValues),
                  style: AppTypography.headline.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ValuesGrid(values: _values(context), isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                _AudienceCards(isWide: isWide),
                const SizedBox(height: AppSpacing.s32),
                _TrustCard(),
                const SizedBox(height: AppSpacing.s32),
                _ContactCard(
                  onHelpTap: () =>
                      context.openRoute(AppRouteNames.buyerHelpCenter),
                  onSellTap: () => context.openRoute(AppRouteNames.login),
                ),
                const SizedBox(height: AppSpacing.s48),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final height = isWide ? 320.0 : 240.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppNetworkImage(
            url: HomeNetworkImages.hero,
            memCacheWidth: 1600,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66111827), Color(0xCC111827)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? AppSpacing.s48 : AppSpacing.s24,
              vertical: AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  context.tr(
                    RemainingL10n.expertDrivenMarketplaceForLuxuryAssetsAnd,
                  ),
                  style: AppTypography.display.copyWith(
                    color: AppColors.warmWhite,
                    fontSize: isWide ? 34 : 28,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(
                  context.tr(
                    RemainingL10n.indiaSMarketplaceForDiamondsGemstonesJewelry,
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.warmWhite.withValues(alpha: 0.88),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          title,
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          body,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondaryLight,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _PromiseSection extends StatelessWidget {
  const _PromiseSection();

  static List<({IconData icon, String title, String body})> _promises(
    BuildContext context,
  ) => [
    (
      icon: Icons.diamond_outlined,
      title: context.tr(RemainingL10n.certifiedQuality),
      body: context.tr(RemainingL10n.giaIgiAndAgsGradedDiamonds),
    ),
    (
      icon: Icons.compare_arrows_rounded,
      title: context.tr(RemainingL10n.compareConfidence),
      body: context.tr(RemainingL10n.sideBySideToolsToEvaluate),
    ),
    (
      icon: Icons.lock_outline,
      title: context.tr(RemainingL10n.secureTransactions),
      body: context.tr(
        RemainingL10n.verifiedSellersProtectedPaymentsAndDedicatedSupport,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(RemainingL10n.ourPromise),
          style: AppTypography.caption.copyWith(
            color: AppColors.bronze,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          context.tr(RemainingL10n.shopConfidence),
          style: AppTypography.headline.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (final promise in _promises(context)) ...[
          _SurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(promise.icon, color: AppColors.bronze, size: 24),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promise.title,
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        promise.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _StatItem {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.isWide});

  final List<_StatItem> stats;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s12,
      children: [
        for (final stat in stats)
          SizedBox(
            width: isWide ? 172 : (MediaQuery.sizeOf(context).width - 52) / 2,
            child: _SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    stat.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.isWide});

  final bool isWide;

  List<String> _categories(BuildContext context) => [
    context.tr(RemainingL10n.naturalDiamonds),
    context.tr(RemainingL10n.labGrown),
    context.tr(RemainingL10n.gemstones),
    context.tr(RemainingL10n.jewelry),
    context.tr(RemainingL10n.watches),
    context.tr(RemainingL10n.bullion),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        for (final label in _categories(context))
          Chip(
            label: Text(label),
            backgroundColor: AppColors.sandSurface,
            side: const BorderSide(color: AppColors.warmBorder),
            labelStyle: AppTypography.label.copyWith(
              color: AppColors.charcoal,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ValueItem {
  const _ValueItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ValuesGrid extends StatelessWidget {
  const _ValuesGrid({required this.values, required this.isWide});

  final List<_ValueItem> values;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final columns = isWide ? 2 : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.s12) / columns;

        return Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            for (final value in values)
              SizedBox(
                width: itemWidth,
                child: _SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(value.icon, color: AppColors.bronze, size: 26),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        value.title,
                        style: AppTypography.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        value.body,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AudienceCards extends StatelessWidget {
  const _AudienceCards({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final children = [
      _SurfaceCard(
        child: _AudienceBlock(
          icon: Icons.shopping_bag_outlined,
          title: context.tr(RemainingL10n.forBuyers),
          bullets: [
            context.tr(RemainingL10n.aboutBuyerSearchCompare),
            context.tr(RemainingL10n.aboutBuyerCertificationDetails),
            context.tr(RemainingL10n.aboutBuyerSecureCheckout),
            context.tr(RemainingL10n.aboutBuyerTrackedDelivery),
          ],
        ),
      ),
      _SurfaceCard(
        child: _AudienceBlock(
          icon: Icons.storefront_outlined,
          title: context.tr(RemainingL10n.forSellers),
          bullets: [
            context.tr(RemainingL10n.aboutSellerCatalog),
            context.tr(RemainingL10n.aboutSellerDashboard),
            context.tr(RemainingL10n.aboutSellerMessaging),
            context.tr(RemainingL10n.aboutSellerOnboarding),
          ],
        ),
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s12),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: AppSpacing.s12),
        Expanded(child: children[1]),
      ],
    );
  }
}

class _AudienceBlock extends StatelessWidget {
  const _AudienceBlock({
    required this.icon,
    required this.title,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.charcoal, size: 28),
        const SizedBox(height: AppSpacing.s12),
        Text(
          title,
          style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final bullet in bullets) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 6, color: AppColors.bronze),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  bullet,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ],
    );
  }
}

class _TrustCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      color: AppColors.charcoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(RemainingL10n.trustSecurity),
            style: AppTypography.title.copyWith(
              color: AppColors.warmWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            context.tr(RemainingL10n.highValueTradeDemandsMoreThan),
            style: AppTypography.body.copyWith(
              color: AppColors.bronzeLight,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onHelpTap, required this.onSellTap});

  final VoidCallback onHelpTap;
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(RemainingL10n.getInTouch),
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            context.tr(
              RemainingL10n.questionsAboutSourcingSellingOrCertification,
            ),
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            context.tr(RemainingL10n.supportGemworldCom),
            style: AppTypography.label.copyWith(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s12,
            runSpacing: AppSpacing.s12,
            children: [
              FilledButton.icon(
                onPressed: onHelpTap,
                icon: const Icon(Icons.help_outline, size: 18),
                label: Text(context.tr(RemainingL10n.helpCenter)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.charcoal,
                  foregroundColor: AppColors.warmWhite,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSellTap,
                icon: const Icon(Icons.storefront_outlined, size: 18),
                label: Text(context.tr(RemainingL10n.sellOnGemWorld)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.charcoal,
                  side: const BorderSide(color: AppColors.charcoal),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: color ?? AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: color == null
            ? const Border.fromBorderSide(
                BorderSide(color: AppColors.warmBorder),
              )
            : null,
      ),
      child: child,
    );
  }
}
