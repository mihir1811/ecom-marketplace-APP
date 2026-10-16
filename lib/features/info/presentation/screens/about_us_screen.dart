import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';

/// Public About GemWorld — guest-facing editorial page (home footer, deep links).
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    var i = 1;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    final promises = [
      (
        Icons.diamond_outlined,
        context.tr(RemainingL10n.certifiedQuality),
        context.tr(RemainingL10n.giaIgiAndAgsGradedDiamonds),
      ),
      (
        Icons.compare_arrows_rounded,
        context.tr(RemainingL10n.compareConfidence),
        context.tr(RemainingL10n.sideBySideToolsToEvaluate),
      ),
      (
        Icons.lock_outline,
        context.tr(RemainingL10n.secureTransactions),
        context.tr(
          RemainingL10n.verifiedSellersProtectedPaymentsAndDedicatedSupport,
        ),
      ),
    ];

    final values = [
      (
        Icons.verified_outlined,
        context.tr(RemainingL10n.qualityVerify),
        context.tr(RemainingL10n.everyListingHighlightsCertificationGradingAnd),
      ),
      (
        Icons.visibility_outlined,
        context.tr(RemainingL10n.transparencyEveryStep),
        context.tr(RemainingL10n.clearPricingDetailedSpecificationsAndRich),
      ),
      (
        Icons.support_agent_outlined,
        context.tr(RemainingL10n.expertGuidance),
        context.tr(RemainingL10n.fromComparingNaturalAndLabGrown),
      ),
      (
        Icons.handshake_outlined,
        context.tr(RemainingL10n.builtForBuyersSellers),
        context.tr(RemainingL10n.weConnectVerifiedIndianSellersWith),
      ),
    ];

    final categories = [
      context.tr(RemainingL10n.naturalDiamonds),
      context.tr(RemainingL10n.labGrown),
      context.tr(RemainingL10n.gemstones),
      context.tr(RemainingL10n.jewelry),
      context.tr(RemainingL10n.watches),
      context.tr(RemainingL10n.bullion),
    ];

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AtelierIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.goBack(fallbackLocation: AppRouteNames.home),
          filled: true,
        ),
      ),
      body: AtelierPage(
        onRefresh: () async {},
        maxWidth: 980,
        children: [
          AtelierHero(
            title: context.tr(RemainingL10n.aboutGemWorld),
            cut: GemCut.oval,
            look: GemLook.champagne,
            action: Text(
              context.tr(
                RemainingL10n.expertDrivenMarketplaceForLuxuryAssetsAnd,
              ),
              style: AtelierType.body(
                p.onOnyx.withValues(alpha: 0.78),
                size: 14.5,
              ),
            ),
            footer: AtelierHeroStats(
              stats: [
                AtelierHeroStat(
                  value: '6',
                  label: context.tr(RemainingL10n.coreCategories),
                ),
                AtelierHeroStat(
                  value: 'Pan-IN',
                  label: context.tr(RemainingL10n.marketplaceReach),
                ),
                AtelierHeroStat(
                  value: 'GIA',
                  label: context.tr(RemainingL10n.certification),
                ),
                AtelierHeroStat(
                  value: '24/7',
                  label: context.tr(RemainingL10n.supportTickets),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          reveal(
            Text(
              context.tr(RemainingL10n.ourStory).toUpperCase(),
              style: AtelierType.overline(p.gold),
            ),
          ),
          const SizedBox(height: 8),
          reveal(
            Text(
              context.tr(RemainingL10n.trustedMarketplaceTitle),
              style: AtelierType.display(p.ink, size: wide ? 28 : 24),
            ),
          ),
          const SizedBox(height: 10),
          reveal(
            Text(
              context.tr(RemainingL10n.gemworldWasBuiltOnASimple),
              style: AtelierType.body(p.inkSoft, size: 15),
            ),
          ),
          const SizedBox(height: 22),
          reveal(
            Text(
              context.tr(RemainingL10n.ourPromise).toUpperCase(),
              style: AtelierType.overline(p.gold),
            ),
          ),
          const SizedBox(height: 8),
          reveal(
            Text(
              context.tr(RemainingL10n.shopConfidence),
              style: AtelierType.display(p.ink, size: wide ? 28 : 24),
            ),
          ),
          const SizedBox(height: 14),
          for (final item in promises) ...[
            reveal(
              AtelierCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AtelierIconBadge(icon: item.$1),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2, style: AtelierType.title(p.ink)),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: AtelierType.body(p.inkSoft, size: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          reveal(
            Text(
              context.tr(RemainingL10n.whatWeDo).toUpperCase(),
              style: AtelierType.overline(p.gold),
            ),
          ),
          const SizedBox(height: 8),
          reveal(
            Text(
              context.tr(RemainingL10n.onePlatformTrade),
              style: AtelierType.display(p.ink, size: wide ? 28 : 24),
            ),
          ),
          const SizedBox(height: 10),
          reveal(
            Text(
              context.tr(RemainingL10n.gemworldBringsTogetherNaturalDiamondsLab),
              style: AtelierType.body(p.inkSoft, size: 15),
            ),
          ),
          const SizedBox(height: 14),
          reveal(
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in categories)
                  AtelierPill(label: label, tone: AtelierTone.gold),
              ],
            ),
          ),
          const SizedBox(height: 24),
          reveal(
            Text(
              context.tr(RemainingL10n.ourValues).toUpperCase(),
              style: AtelierType.overline(p.gold),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 640 ? 2 : 1;
              final gap = 12.0;
              final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final v in values)
                    SizedBox(
                      width: w,
                      child: reveal(
                        AtelierCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AtelierIconBadge(icon: v.$1),
                              const SizedBox(height: 12),
                              Text(v.$2, style: AtelierType.title(p.ink)),
                              const SizedBox(height: 8),
                              Text(
                                v.$3,
                                style: AtelierType.body(p.inkSoft, size: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          reveal(
            AtelierCard(
              color: p.isDark ? p.surface : const Color(0xFF16140F),
              borderColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(RemainingL10n.trustSecurity),
                    style: AtelierType.title(
                      p.isDark ? p.ink : const Color(0xFFF6F3EE),
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr(RemainingL10n.highValueTradeDemandsMoreThan),
                    style: AtelierType.body(
                      p.isDark ? p.inkSoft : const Color(0xFFD5B27A),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          reveal(
            AtelierCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(RemainingL10n.getInTouch),
                    style: AtelierType.title(p.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      RemainingL10n
                          .questionsAboutSourcingSellingOrCertification,
                    ),
                    style: AtelierType.body(p.inkSoft, size: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(RemainingL10n.supportGemworldCom),
                    style: AtelierType.label(p.gold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AtelierButton(
                        label: context.tr(AccountCommerceL10n.privacyPolicy),
                        icon: Icons.privacy_tip_outlined,
                        onPressed: () =>
                            context.openRoute(AppRouteNames.privacyPolicy),
                      ),
                      AtelierButton(
                        label: context.tr(AccountCommerceL10n.termsConditions),
                        variant: AtelierButtonVariant.secondary,
                        icon: Icons.gavel_outlined,
                        onPressed: () => context.openRoute(
                          AppRouteNames.termsAndConditions,
                        ),
                      ),
                      AtelierButton(
                        label: context.tr(RemainingL10n.sellOnGemWorld),
                        variant: AtelierButtonVariant.ghost,
                        icon: Icons.storefront_outlined,
                        onPressed: () =>
                            context.openRoute(AppRouteNames.login),
                      ),
                    ],
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
