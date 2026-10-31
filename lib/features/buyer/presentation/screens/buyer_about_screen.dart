import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';

/// Buyer About GemWorld — Maison editorial page with promises, values and CTAs.
class BuyerAboutScreen extends StatelessWidget {
  const BuyerAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
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

    final buyerBullets = [
      context.tr(RemainingL10n.aboutBuyerSearchCompare),
      context.tr(RemainingL10n.aboutBuyerCertificationDetails),
      context.tr(RemainingL10n.aboutBuyerSecureCheckout),
      context.tr(RemainingL10n.aboutBuyerTrackedDelivery),
    ];

    return MaisonLayout(
      detail: true,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 48),
        children: [
          MaisonCentered(
            maxWidth: 820,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MaisonHeader(
                  title: context.tr(RemainingL10n.aboutGemWorld),
                  cut: GemCut.oval,
                  look: GemLook.champagne,
                ),
                const SizedBox(height: 10),
                reveal(
                  Text(
                    context.tr(
                      RemainingL10n.expertDrivenMarketplaceForLuxuryAssetsAnd,
                    ),
                    style: AtelierType.body(p.inkSoft, size: 15.5),
                  ),
                ),
                const SizedBox(height: 28),
                reveal(
                  MaisonGroupLabel(
                    label: context.tr(RemainingL10n.ourStory),
                  ),
                ),
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
                const SizedBox(height: 24),
                reveal(
                  MaisonGroupLabel(
                    label: context.tr(RemainingL10n.ourPromise),
                  ),
                ),
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
                                Text(
                                  item.$2,
                                  style: AtelierType.title(p.ink, size: 15.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$3,
                                  style: AtelierType.body(
                                    p.inkSoft,
                                    size: 13.5,
                                  ),
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
                const SizedBox(height: 14),
                reveal(
                  MaisonGroupLabel(
                    label: context.tr(RemainingL10n.whatWeDo),
                  ),
                ),
                reveal(
                  Text(
                    context.tr(RemainingL10n.onePlatformTrade),
                    style: AtelierType.display(p.ink, size: wide ? 28 : 24),
                  ),
                ),
                const SizedBox(height: 10),
                reveal(
                  Text(
                    context.tr(
                      RemainingL10n.gemworldBringsTogetherNaturalDiamondsLab,
                    ),
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
                const SizedBox(height: 28),
                reveal(
                  MaisonGroupLabel(
                    label: context.tr(RemainingL10n.ourValues),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 640 ? 2 : 1;
                    const gap = 12.0;
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
                                    Text(
                                      v.$2,
                                      style: AtelierType.title(p.ink),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      v.$3,
                                      style: AtelierType.body(
                                        p.inkSoft,
                                        size: 13.5,
                                      ),
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
                const SizedBox(height: 24),
                reveal(
                  AtelierCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AtelierIconBadge(
                              icon: Icons.shopping_bag_outlined,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.tr(RemainingL10n.forBuyers),
                                style: AtelierType.title(p.ink, size: 17),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        for (final bullet in buyerBullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: p.gold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: AtelierType.body(
                                      p.inkSoft,
                                      size: 14,
                                    ),
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
                            p.isDark
                                ? p.inkSoft
                                : const Color(0xFFD5B27A),
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
                              label: context.tr(RemainingL10n.helpCenter),
                              icon: Icons.help_outline_rounded,
                              onPressed: () => context.openRoute(
                                AppRouteNames.buyerHelpCenter,
                              ),
                            ),
                            AtelierButton(
                              label: context.tr(RemainingL10n.policiesLegal),
                              variant: AtelierButtonVariant.secondary,
                              icon: Icons.menu_book_outlined,
                              onPressed: () => context.openRoute(
                                AppRouteNames.buyerPolicies,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const MaisonListFooter(
                  loadingMore: false,
                  hasMore: false,
                  onLoadMore: _noop,
                  endLabel: 'GemWorld · for collectors',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}
