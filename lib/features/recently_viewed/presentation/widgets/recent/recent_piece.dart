import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/app_currency.dart';
import '../../../../../core/utils/format_catalog_price.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../buyer/domain/models/wishlist_item.dart';
import '../../../../buyer/presentation/maison/maison_kit.dart';
import '../../../../buyer/presentation/widgets/wishlist/wishlist_piece_card.dart';
import '../../../../comparison/domain/models/compare_category.dart';
import '../../../../comparison/domain/models/compare_item.dart';
import '../../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../../product_detail/product_detail_navigation.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/recently_viewed.dart';

/// Helpers shared by the recently viewed tile, row and resume card.
extension RecentPiece on RecentlyViewedEntry {
  WishlistCategory get category => FavoriteProductType.toCategory(
    productType == FavoriteProductType.meleeDiamond
        ? FavoriteProductType.diamond
        : productType,
  );

  String get typeLabel => FavoriteProductType.label(productType);

  double get priceValue =>
      double.tryParse((price ?? '').replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

  /// Formatted catalogue price, or null when the piece has none.
  String? get priceLabel {
    final value = priceValue;
    if (value <= 0) return null;
    return AppCurrency.format(formatCatalogPrice(value));
  }

  /// "2h ago" when the view time is known, else the API's date label.
  String get viewedWhen {
    if (viewedAt != null) return maisonRelative(viewedAt);
    return viewedAtLabel == '—' ? '' : viewedAtLabel;
  }

  /// Day bucket for the timeline: Today, Yesterday or the date.
  String get dayGroup =>
      viewedAt == null ? 'Earlier' : maisonDayLabel(viewedAt);

  RecentAvailability get availabilityState =>
      RecentAvailability.of(availability);

  WishlistItem toWishlistItem() => WishlistItem(
    id: productId,
    category: category,
    productType: productType.isNotEmpty
        ? productType
        : FavoriteProductType.fromCategory(category),
    title: displayTitle,
    subtitle: detailLine ?? metaLine ?? '',
    priceLabel: priceLabel ?? '',
    imageUrl: imageUrl,
  );

  /// Comparison payload for diamonds, gemstones and watches only.
  CompareItem? toCompareItem() {
    final compare = switch (productType) {
      'diamond' || 'meleeDiamond' => CompareCategory.diamond,
      'gemstone' => CompareCategory.gemstone,
      'watch' => CompareCategory.watch,
      _ => null,
    };
    if (compare == null) return null;
    final value = priceValue;
    final label = priceLabel;
    return CompareItem(
      id: productId,
      category: compare,
      title: displayTitle,
      price: value,
      imageUrl: imageUrl,
      shape: shape,
      displayValues: {
        'price': ?label,
        if (carat != null) 'carat': '${carat!.toStringAsFixed(2)}ct',
        if (shape != null && shape!.isNotEmpty) 'shape': shape!,
        if (color != null && color!.isNotEmpty) 'color': color!,
        if (clarity != null && clarity!.isNotEmpty) 'clarity': clarity!,
        if (cut != null && cut!.isNotEmpty) 'cut': cut!,
      },
      numericValues: {'price': value, 'carat': ?carat},
    );
  }
}

/// Availability folded to the four states a buyer cares about.
enum RecentAvailability {
  available(AtelierTone.emerald),
  reserved(AtelierTone.amber),
  gone(AtelierTone.ruby),
  unknown(AtelierTone.neutral);

  const RecentAvailability(this.tone);
  final AtelierTone tone;

  static RecentAvailability of(String? raw) {
    if (raw == null || raw.trim().isEmpty) return unknown;
    return switch (CatalogPurchasePolicy.normalizeCode(raw)) {
      'yes' => available,
      'hold' || 'memo' => reserved,
      'sold' || 'unavailable' || 'no' => gone,
      _ => unknown,
    };
  }

  String label(BuildContext context, String? raw) =>
      switch (CatalogPurchasePolicy.normalizeCode(raw)) {
        'yes' => context.tr(AccountCommerceL10n.available),
        'hold' => context.tr(AccountCommerceL10n.onHold),
        'memo' => context.tr(AccountCommerceL10n.onMemo),
        'sold' => context.tr(AccountCommerceL10n.sold),
        'unavailable' || 'no' => context.tr(AccountCommerceL10n.unavailable),
        _ => raw ?? '',
      };
}

/// Opens the piece: the nested catalogue payload when the API sent one,
/// else a remembered detail, else a fresh load. Returns false when the
/// product could not be opened.
Future<bool> openRecentPiece(
  BuildContext context,
  WidgetRef ref,
  RecentlyViewedEntry entry,
) async {
  if (entry.diamond case final d?) {
    openDiamondDetail(context, d);
    return true;
  }
  if (entry.gemstone case final g?) {
    openGemstoneDetail(context, g);
    return true;
  }
  if (entry.watch case final w?) {
    openWatchDetail(context, w);
    return true;
  }
  if (entry.jewelry case final j?) {
    openJewelryDetail(context, j);
    return true;
  }
  if (entry.bullion case final b?) {
    openBullionDetail(context, b);
    return true;
  }
  if (openRememberedProductDetail(context, entry.productId)) return true;
  final detail = await CatalogProductDetailLoader.load(
    ref.read,
    productType: entry.productType,
    productId: entry.productId,
  );
  if (!context.mounted || detail == null) return false;
  openProductDetail(context, detail);
  return true;
}

/// Product photo with a soft gem-tinted fallback; pieces no longer for
/// sale are quietly desaturated.
class RecentPieceImage extends StatelessWidget {
  const RecentPieceImage({
    required this.entry,
    this.iconSize = 30,
    this.memCacheWidth = 600,
    super.key,
  });

  final RecentlyViewedEntry entry;
  final double iconSize;
  final int memCacheWidth;

  static const _muted = ColorFilter.matrix([
    0.55, 0.35, 0.1, 0, 0, //
    0.25, 0.65, 0.1, 0, 0, //
    0.25, 0.35, 0.4, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [p.goldSoft, p.sunken], radius: 0.9),
      ),
      child: Center(
        child: Icon(
          wishlistCategoryIcon(entry.category),
          size: iconSize,
          color: p.gold,
        ),
      ),
    );
    final url = entry.imageUrl?.trim();
    final Widget image = url == null || url.isEmpty
        ? fallback
        : ColoredBox(
            color: p.sunken,
            child: AppNetworkImage(
              url: url,
              fit: BoxFit.cover,
              memCacheWidth: memCacheWidth,
              error: fallback,
            ),
          );
    if (entry.availabilityState != RecentAvailability.gone) return image;
    return ColorFiltered(colorFilter: _muted, child: image);
  }
}
