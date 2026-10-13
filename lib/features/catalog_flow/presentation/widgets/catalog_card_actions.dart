import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';

/// Heart toggle for any catalog item, styled for imagery (glass) or rows.
class CatalogSaveButton extends ConsumerWidget {
  const CatalogSaveButton({
    required this.item,
    super.key,
    this.onAdded,
    this.onLight = false,
  });

  final WishlistItem item;

  /// Called once the item is saved (e.g. to cache its detail page).
  final VoidCallback? onAdded;

  /// True when placed on a card surface rather than over the photo.
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWishlistProvider(item.id));
    return LuxeMiniCircle(
      tooltip: context.tr(HomeL10n.wishlist),
      glass: !onLight,
      onTap: () => toggleWishlistItem(context, ref, item, onAdded: onAdded),
      child: AnimatedSwitcher(
        duration: LuxeMotion.fast,
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(saved),
          size: 17,
          color: saved
              ? const Color(0xFFE5484D)
              : LuxeMiniCircle.restingIconColor(context, glass: !onLight),
        ),
      ),
    );
  }
}

/// Compare toggle for any catalog item (adds to the comparison tray).
class CatalogCompareButton extends ConsumerWidget {
  const CatalogCompareButton({
    required this.item,
    super.key,
    this.onAdded,
    this.onLight = false,
  });

  final CompareItem item;

  /// Called once the item joins the comparison (e.g. to cache its detail).
  final VoidCallback? onAdded;
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final inCompare = ref.watch(isInComparisonProvider(item.id));
    return LuxeMiniCircle(
      tooltip: context.tr(CatalogL10n.compare),
      glass: !onLight,
      active: inCompare,
      onTap: () {
        handleCompareToggle(context, ref, item);
        if (ref.read(isInComparisonProvider(item.id))) onAdded?.call();
      },
      child: Icon(
        inCompare ? Icons.check_rounded : Icons.compare_arrows_rounded,
        size: 17,
        color: inCompare
            ? p.canvas
            : LuxeMiniCircle.restingIconColor(context, glass: !onLight),
      ),
    );
  }
}
