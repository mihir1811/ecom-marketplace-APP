import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Seller About GemWorld — Atelier studio page focused on trading with buyers.
class SellerAboutScreen extends StatelessWidget {
  const SellerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final wide = MediaQuery.sizeOf(context).width >= 720;
    var i = 1;
    Widget reveal(Widget child) => Reveal(index: i++, child: child);

    final promises = [
      (
        Icons.storefront_outlined,
        context.tr(RemainingL10n.aboutSellerCatalog),
        context.tr(
          RemainingL10n.verifiedSellersProtectedPaymentsAndDedicatedSupport,
        ),
      ),
      (
        Icons.insights_outlined,
        context.tr(RemainingL10n.aboutSellerDashboard),
        context.tr(RemainingL10n.sideBySideToolsToEvaluate),
      ),
      (
        Icons.forum_outlined,
        context.tr(RemainingL10n.aboutSellerMessaging),
        context.tr(RemainingL10n.fromComparingNaturalAndLabGrown),
      ),
    ];

    final sellerBullets = [
      context.tr(RemainingL10n.aboutSellerCatalog),
      context.tr(RemainingL10n.aboutSellerDashboard),
      context.tr(RemainingL10n.aboutSellerMessaging),
      context.tr(RemainingL10n.aboutSellerOnboarding),
    ];

    final categories = [
      context.tr(RemainingL10n.naturalDiamonds),
      context.tr(RemainingL10n.labGrown),
      context.tr(RemainingL10n.gemstones),
      context.tr(RemainingL10n.jewelry),
      context.tr(RemainingL10n.watches),
      context.tr(RemainingL10n.bullion),
    ];

    return AtelierPage(
      onRefresh: () async {},
      maxWidth: 980,
      children: [
        AtelierHero(
          title: context.tr(RemainingL10n.aboutGemWorld),
          cut: GemCut.radiant,
          look: GemLook.champagne,
          action: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AtelierButton(
                label: context.tr(RemainingL10n.helpCenter),
                icon: Icons.support_agent_outlined,
                onPressed: () =>
                    context.openRoute(AppRouteNames.sellerHelpCenter),
              ),
              AtelierButton(
                label: context.tr(RemainingL10n.policiesLegal),
                variant: AtelierButtonVariant.secondary,
                icon: Icons.menu_book_outlined,
                onPressed: () =>
                    context.openRoute(AppRouteNames.sellerPolicies),
              ),
            ],
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
                value: 'GIA · IGI',
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
        reveal(AtelierSectionHeader(title: context.tr(RemainingL10n.ourStory))),
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
          AtelierSectionHeader(title: context.tr(RemainingL10n.ourPromise)),
        ),
        const SizedBox(height: 12),
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
        reveal(AtelierSectionHeader(title: context.tr(RemainingL10n.whatWeDo))),
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
          AtelierCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AtelierIconBadge(icon: Icons.storefront_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(RemainingL10n.forSellers),
                        style: AtelierType.title(p.ink, size: 17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final bullet in sellerBullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Icon(Icons.circle, size: 6, color: p.gold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: AtelierType.body(p.inkSoft, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                    RemainingL10n.questionsAboutSourcingSellingOrCertification,
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
                          context.openRoute(AppRouteNames.sellerPrivacy),
                    ),
                    AtelierButton(
                      label: context.tr(AccountCommerceL10n.termsConditions),
                      variant: AtelierButtonVariant.secondary,
                      icon: Icons.gavel_outlined,
                      onPressed: () =>
                          context.openRoute(AppRouteNames.sellerTerms),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
