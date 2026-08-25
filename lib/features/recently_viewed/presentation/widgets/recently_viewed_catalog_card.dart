import 'package:flutter/material.dart';

import '../../../bullions/presentation/widgets/billion_card.dart';
import '../../../diamonds/presentation/widgets/diamond_cards.dart';
import '../../../gemstones/presentation/widgets/gemstone_card.dart';
import '../../../jewelry/presentation/widgets/jewelry_product_card.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../watches/presentation/widgets/watch_card_grid.dart';
import '../../domain/models/recently_viewed.dart';

/// Renders the same catalog card used on listing screens when the nested
/// product payload can be mapped; otherwise [fallback].
class RecentlyViewedCatalogCard extends StatelessWidget {
  const RecentlyViewedCatalogCard({
    required this.entry,
    required this.isGrid,
    required this.fallback,
    super.key,
  });

  final RecentlyViewedEntry entry;
  final bool isGrid;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final diamond = entry.diamond;
    if (diamond != null) {
      return isGrid
          ? DiamondCardGrid(
              diamond: diamond,
              onTap: () => openDiamondDetail(context, diamond),
            )
          : DiamondCardList(
              diamond: diamond,
              onTap: () => openDiamondDetail(context, diamond),
            );
    }

    final gemstone = entry.gemstone;
    if (gemstone != null) {
      return isGrid
          ? GemstoneCardGrid(
              gemstone: gemstone,
              onTap: () => openGemstoneDetail(context, gemstone),
            )
          : GemstoneCardList(
              gemstone: gemstone,
              onTap: () => openGemstoneDetail(context, gemstone),
            );
    }

    final watch = entry.watch;
    if (watch != null) {
      return isGrid
          ? WatchCardGrid(
              watch: watch,
              onTap: () => openWatchDetail(context, watch),
            )
          : WatchCardList(
              watch: watch,
              onTap: () => openWatchDetail(context, watch),
            );
    }

    final jewelry = entry.jewelry;
    if (jewelry != null) {
      return isGrid
          ? JewelryProductCard(
              item: jewelry,
              compact: true,
              onTap: () => openJewelryDetail(context, jewelry),
            )
          : JewelryProductListCard(
              item: jewelry,
              onTap: () => openJewelryDetail(context, jewelry),
            );
    }

    final bullion = entry.bullion;
    if (bullion != null) {
      return isGrid
          ? BullionCardGrid(
              bullion: bullion,
              onTap: () => openBullionDetail(context, bullion),
            )
          : BullionCardList(
              bullion: bullion,
              onTap: () => openBullionDetail(context, bullion),
            );
    }

    return fallback;
  }
}
