import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../catalog_flow/presentation/widgets/catalog_card_actions.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/diamond_project_listing_pick_provider.dart';
import '../../application/diamond_selection.dart';

/// The one select control on a diamond card.
///
/// Buyers and sellers alike: a tap picks the stone for the insight strip
/// (and, for sellers, the diamond project) and, while at most four are
/// picked, for comparison too. Stones without an id fall back to a plain
/// compare toggle.
class DiamondSelectionToggle extends ConsumerWidget {
  const DiamondSelectionToggle({
    required this.diamond,
    super.key,
    this.onLight = false,
  });

  final Diamond diamond;

  /// True when placed on a card surface rather than over the photo.
  final bool onLight;

  void _remember() => rememberProductDetail(diamondProductDetail(diamond));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (diamond.id.isEmpty) {
      return CatalogCompareButton(
        item: CompareItem.fromDiamond(diamond),
        onAdded: _remember,
        onLight: onLight,
      );
    }

    final p = LuxePalette.of(context);
    final picked = ref.watch(isDiamondProjectPickedProvider(diamond.id));
    // Same look as the gemstone card's compare button.
    return LuxeMiniCircle(
      tooltip: context.tr(
        picked
            ? AccountCommerceL10n.compareDeselect
            : AccountCommerceL10n.compareSelect,
      ),
      glass: !onLight,
      active: picked,
      onTap: () => _toggle(context, ref),
      child: Icon(
        picked ? Icons.check_rounded : Icons.compare_arrows_rounded,
        size: 17,
        color: picked
            ? p.canvas
            : LuxeMiniCircle.restingIconColor(context, glass: !onLight),
      ),
    );
  }

  void _toggle(BuildContext context, WidgetRef ref) {
    final outcome = DiamondSelection.toggle(ref, diamond);
    if (outcome != DiamondSelectionOutcome.removed) _remember();
    switch (outcome) {
      case DiamondSelectionOutcome.switchedCategory:
        AppHaptics.warning();
        showCompareFeedback(
          context,
          context.tr(AccountCommerceL10n.compareSwitched),
        );
      case DiamondSelectionOutcome.added ||
          DiamondSelectionOutcome.addedOverLimit ||
          DiamondSelectionOutcome.removed:
        break;
    }
  }
}
