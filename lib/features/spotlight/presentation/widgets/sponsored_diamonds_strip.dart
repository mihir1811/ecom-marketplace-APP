import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../diamonds/presentation/widgets/diamond_luxe_cards.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/sponsored_diamonds_provider.dart';
import '../../application/spotlight_providers.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// The diamond search screen's sponsored stones, before any results: every
/// kind (single and melee, natural and lab), drawn as the app's own stone
/// cards with the blue Sponsored pill and outline.
class SponsoredDiamondsStrip extends ConsumerStatefulWidget {
  const SponsoredDiamondsStrip({
    super.key,
    this.gutter = 16,
    this.padding = EdgeInsets.zero,
  });

  final double gutter;
  final EdgeInsets padding;

  @override
  ConsumerState<SponsoredDiamondsStrip> createState() =>
      _SponsoredDiamondsStripState();
}

class _SponsoredDiamondsStripState
    extends ConsumerState<SponsoredDiamondsStrip> {
  final _visit = SpotlightVisit();

  @override
  Widget build(BuildContext context) {
    final stones =
        ref.watch(sponsoredDiamondsAnyKindProvider).valueOrNull ?? const [];
    if (stones.isEmpty) return const SizedBox.shrink();

    final p = LuxePalette.of(context);
    final gutter = widget.gutter;
    final among = [for (final s in stones) s.diamond];
    final width = ((MediaQuery.sizeOf(context).width - gutter - 24) / 2.2)
        .clamp(150.0, 200.0);
    final height =
        width + luxeGridCardTextExtent(MediaQuery.textScalerOf(context));

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    context.tr(SpotlightL10n.featuredPicks),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.display(22, p.ink),
                  ),
                ),
                const SizedBox(width: 10),
                const SpotlightTag(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemCount: stones.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final s = stones[i];
                return SizedBox(
                  width: width,
                  child: SpotlightImpression(
                    adId: s.adId,
                    visit: _visit,
                    child: DiamondLuxeGridCard(
                      diamond: s.diamond,
                      sponsored: true,
                      onTap: () {
                        ref.read(spotlightEventsProvider).click(s.adId);
                        openDiamondDetail(context, s.diamond, among: among);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
