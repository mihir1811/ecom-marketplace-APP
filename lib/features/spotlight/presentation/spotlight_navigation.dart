import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/luxe/luxe_feedback.dart';
import '../../product_detail/open_catalog_product_detail.dart';
import '../application/spotlight_providers.dart';
import '../domain/spotlight_models.dart';

/// Counts the click and opens the advertised product.
Future<void> openSpotlightProduct(
  BuildContext context,
  WidgetRef ref, {
  required String adId,
  required String productType,
  required String productId,
}) async {
  ref.read(spotlightEventsProvider).click(adId);
  final opened = await openCatalogProductDetail(
    context,
    ref,
    productType: productType,
    productId: productId,
  );
  if (opened || !context.mounted) return;
  showLuxeToast(
    context,
    context.tr(AccountCommerceL10n.productOpenFailed),
    tone: LuxeTone.error,
  );
}

/// Counts the click and opens the seller's shop. [profile] fills the shop
/// header straight away when the ad carried it.
void openSpotlightSeller(
  BuildContext context,
  WidgetRef ref, {
  required String adId,
  required String sellerId,
  SpotlightSellerProfile? profile,
  String? sellerName,
}) {
  if (sellerId.isEmpty) return;
  ref.read(spotlightEventsProvider).click(adId);
  context.push(
    AppRouteNames.sellerShopPath(sellerId),
    extra:
        profile ??
        SpotlightSellerProfile(id: sellerId, name: sellerName?.trim() ?? ''),
  );
}

/// Opens what a banner points at: its product, or the seller's shop.
Future<void> openSpotlightBanner(
  BuildContext context,
  WidgetRef ref,
  SpotlightBanner banner,
) async {
  final link = banner.link;
  if (link.opensProduct) {
    await openSpotlightProduct(
      context,
      ref,
      adId: banner.adId,
      productType: link.productType!,
      productId: link.productId!,
    );
    return;
  }
  final sellerId = link.sellerId ?? banner.seller?.id ?? '';
  openSpotlightSeller(
    context,
    ref,
    adId: banner.adId,
    sellerId: sellerId,
    sellerName: banner.seller?.name,
  );
}
