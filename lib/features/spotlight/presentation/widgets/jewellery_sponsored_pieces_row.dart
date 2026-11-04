import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../jewelry/presentation/widgets/jewelry_luxe_cards.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_impression.dart';

/// JEWELLERY_PRODUCT_SPONSORED: "Sponsored pieces" on a jewellery product
/// page, after "Similar pieces". Up to 4 pieces, never [excludeListingId]
/// (the piece on screen). The whole block, [padding] included, is skipped
/// when nothing is running.
class JewellerySponsoredPiecesRow extends ConsumerStatefulWidget {
  const JewellerySponsoredPiecesRow({
    required this.excludeListingId,
    super.key,
    this.gutter = 16,
    this.padding = EdgeInsets.zero,
  });

  final String excludeListingId;
  final double gutter;
  final EdgeInsets padding;

  static const limit = 4;

  @override
  ConsumerState<JewellerySponsoredPiecesRow> createState() =>
      _JewellerySponsoredPiecesRowState();
}

class _JewellerySponsoredPiecesRowState
    extends ConsumerState<JewellerySponsoredPiecesRow> {
  final _visit = SpotlightVisit();

  @override
  Widget build(BuildContext context) {
    final exclude = widget.excludeListingId.trim();
    final query = spotlightQuery(
      SpotlightPlacement.jewelleryProductSponsored,
      excludeProductId: exclude.isEmpty ? null : exclude,
      limit: JewellerySponsoredPiecesRow.limit,
    );
    final items = [
      for (final ad in spotlightItemsOf<SpotlightSponsoredListing>(
        ref.watch(spotlightProvider(query)),
      ))
        if (ad.listingId != exclude) ad,
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    final pieces = [for (final ad in items) ad.piece];
    final width = LuxeListingMetrics.gridCell(context);
    final height = LuxeListingMetrics.gridExtent(context);
    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuxeRowHeading(
            title: context.tr(SpotlightL10n.sponsoredPieces),
            subtitle: context.tr(SpotlightL10n.fromGemWorldSellers),
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: widget.gutter),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: LuxeListingMetrics.gap),
              itemBuilder: (context, i) {
                final ad = items[i];
                return SizedBox(
                  width: width,
                  child: SpotlightImpression(
                    adId: ad.adId,
                    visit: _visit,
                    child: JewelryLuxeGridCard(
                      jewelry: ad.piece,
                      sponsored: true,
                      onTap: () => openSpotlightPiece(
                        context,
                        ref,
                        adId: ad.adId,
                        piece: ad.piece,
                        among: pieces,
                      ),
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
