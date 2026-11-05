import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/luxe_button.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../cart/domain/models/cart_product_type.dart';
import '../../../chat/presentation/open_product_seller_chat.dart';
import '../../../jewelry/application/jewelry_catalogue_providers.dart';
import '../../../jewelry_reviews/data/jewelry_review_repository.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_review_stars.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_reviews_section.dart';
import '../../../product_share/presentation/widgets/product_share_sheet.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/adapters/jewelry_product_detail.dart';
import '../../domain/models/product_bullion_detail.dart';
import '../../domain/models/product_detail.dart';
import '../../domain/models/product_price_labels.dart';
import '../widgets/luxe/luxe_detail_parts.dart';
import '../widgets/luxe/luxe_jewelry_detail.dart';
import '../widgets/luxe/luxe_purchase_bar.dart';
import '../widgets/product_detail_seller_panel.dart';
import '../widgets/product_detail_suggested_products.dart';
import '../../../spotlight/domain/spotlight_models.dart';
import '../../../spotlight/presentation/widgets/jewellery_sponsored_pieces_row.dart';
import '../../../spotlight/presentation/widgets/spotlight_product_row.dart';

/// Luxe product detail shared by natural and lab-grown diamonds,
/// gemstones, fine jewelry, watches and bullion (single and melee).
///
/// Reading order follows the buying decision: the stone (gallery), what it
/// is (title, grades, badges), what it costs (price card), why to trust it
/// (at-a-glance grades, certificate), the full record (spec tabs), who sells
/// it, then related stones. The purchase bar stays pinned.
class LuxeProductDetailScreen extends ConsumerStatefulWidget {
  const LuxeProductDetailScreen({required this.detail, super.key});

  final ProductDetail detail;

  static bool supports(ProductDetail detail) =>
      detail.segment == ProductSegment.naturalDiamond ||
      detail.segment == ProductSegment.labGrownDiamond ||
      detail.segment == ProductSegment.gemstone ||
      detail.segment == ProductSegment.jewelry ||
      detail.segment == ProductSegment.watch ||
      detail.segment == ProductSegment.bullion;

  @override
  ConsumerState<LuxeProductDetailScreen> createState() =>
      _LuxeProductDetailScreenState();
}

class _LuxeProductDetailScreenState
    extends ConsumerState<LuxeProductDetailScreen> {
  bool _recordedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  void _recordView() {
    if (_recordedView || !mounted) return;
    if (!ref.read(authProvider).isAuthenticated) return;
    _recordedView = true;
    recordRecentlyViewed(
      ref,
      productId: widget.detail.id,
      productType: widget.detail.apiProductType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final sections = luxeProductSections(context, ref, widget.detail);
    return LuxeDetailLayout(
      title: sections.title,
      media: sections.media,
      availabilityStatus: sections.availabilityStatus,
      headerActions: sections.headerActions,
      summary: sections.summary,
      record: sections.record,
      related: sections.related,
      bottomBar: sections.bottomBar,
    );
  }
}

/// The parts a luxe product page is assembled from, so the page frame (the
/// classic full screen layout or the expanding sheet) stays swappable.
class LuxeProductSections {
  const LuxeProductSections({
    required this.title,
    required this.media,
    required this.availabilityStatus,
    required this.headerActions,
    required this.summary,
    required this.record,
    required this.related,
    required this.bottomBar,
  });

  final String title;
  final ProductMedia media;
  final String? availabilityStatus;
  final List<Widget> Function(bool glass) headerActions;
  final Widget summary;
  final Widget record;

  /// Full-bleed strip below the record; frames give it only a leading
  /// gutter so it runs to the trailing edge.
  final Widget Function(double gutter) related;
  final Widget? bottomBar;
}

/// Resolves [detail] into its luxe page sections. Watches the viewer's auth
/// state, so call it from `build`.
///
/// Marketplace jewelry opens from a catalogue card; with [loadFull] the
/// product page record (description, every photo, gemstones, all SKUs) is
/// fetched by slug and replaces it once it arrives. Pass false for pages
/// not on screen: every fetch counts as a view.
LuxeProductSections luxeProductSections(
  BuildContext context,
  WidgetRef ref,
  ProductDetail detail, {
  bool loadFull = true,
}) {
  if (loadFull &&
      detail.apiProductType == CartProductType.marketplaceJewellery &&
      !(detail.jewelryDetail?.isFullRecord ?? true)) {
    final full = ref.watch(jewelryListingProvider(detail.id)).value;
    if (full != null) detail = jewelryProductDetail(full);
  }
  final auth = ref.watch(
    authProvider.select(
      (s) => (isSeller: s.isSeller, showProtected: !s.isVerificationPending),
    ),
  );
  final unitKey = detail.price.unitLabel == null
      ? null
      : catalogDisplayMessageKeys[detail.price.unitLabel!];
  final labels = ProductPriceLabels.resolve(
    detail.price,
    grouped: true,
    localizedUnit: unitKey == null
        ? detail.price.unitLabel
        : context.tr(unitKey),
  );

  return LuxeProductSections(
    title: detail.title,
    media: detail.media,
    availabilityStatus: detail.availabilityStatus,
    headerActions: (glass) => [_HeaderActions(detail: detail, glass: glass)],
    summary: _Summary(detail: detail, labels: labels),
    record: _Record(detail: detail, isSeller: auth.isSeller),
    related: (gutter) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductDetailSuggestedProducts(
          detail: detail,
          gutter: gutter,
          padding: const EdgeInsets.only(top: 36),
        ),
        // PRODUCT_SPONSORED for this product's section, never advertising
        // the product on its own page. Marketplace jewellery has its own
        // placement, drawn with the normal piece cards.
        if (detail.apiProductType == CartProductType.marketplaceJewellery)
          JewellerySponsoredPiecesRow(
            excludeListingId: _spotlightExcludeId(detail),
            gutter: gutter,
            padding: const EdgeInsets.only(top: 36),
          )
        else
          SpotlightProductRow(
            query: spotlightQuery(
              SpotlightPlacement.productSponsored,
              category: SpotlightCategory.fromSegment(detail.segment),
              excludeProductId: _spotlightExcludeId(detail),
              limit: 8,
            ),
            titleKey: SpotlightL10n.youMayAlsoLike,
            gutter: gutter,
            padding: const EdgeInsets.only(top: 36),
          ),
      ],
    ),
    bottomBar: !auth.showProtected
        ? null
        : detail.jewelryDetail != null
        ? LuxeJewelryPurchaseBar(detail: detail)
        : LuxePurchaseBar(detail: detail, priceLabels: labels),
  );
}

/// The id the spotlight API knows this product by. Marketplace jewellery is
/// keyed by slug in the app, so prefer the listing's own id there.
String _spotlightExcludeId(ProductDetail detail) {
  final listingId = detail.jewelryDetail?.listingId.trim();
  return listingId != null && listingId.isNotEmpty ? listingId : detail.id;
}

/// Chat (sellers), share and save controls for the floating header.
class _HeaderActions extends ConsumerStatefulWidget {
  const _HeaderActions({required this.detail, required this.glass});

  final ProductDetail detail;
  final bool glass;

  @override
  ConsumerState<_HeaderActions> createState() => _HeaderActionsState();
}

class _HeaderActionsState extends ConsumerState<_HeaderActions> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    try {
      await openProductSellerChat(
        context,
        ref,
        productId: widget.detail.id,
        apiProductType: widget.detail.apiProductType,
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  /// Marketplace pieces share their public page on jewelry.gemworld.in.
  void _share() {
    final detail = widget.detail;
    final slug = detail.jewelryDetail?.slug;
    if (detail.apiProductType == CartProductType.marketplaceJewellery &&
        slug != null) {
      SharePlus.instance.share(
        ShareParams(
          text: [
            detail.title,
            'https://jewelry.gemworld.in/product/$slug',
          ].join('\n'),
          subject: detail.title,
        ),
      );
      return;
    }
    showProductShareSheet(
      context: context,
      ref: ref,
      productId: detail.id,
      productType: detail.apiProductType,
      productTitle: detail.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final glass = widget.glass;
    final saved = ref.watch(isInWishlistProvider(detail.id));
    // Marketplace shop chat is a separate service; seller chat is catalog-only.
    final canChat =
        ref.watch(authProvider.select((s) => s.isSeller)) &&
        detail.apiProductType != CartProductType.marketplaceJewellery;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canChat) ...[
          LuxeIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: context.tr(CatalogL10n.chatWithSeller),
            glass: glass,
            size: 42,
            loading: _openingChat,
            onPressed: _openChat,
          ),
          const SizedBox(width: 6),
        ],
        LuxeIconButton(
          icon: Icons.ios_share_rounded,
          tooltip: context.tr(CatalogL10n.share),
          glass: glass,
          size: 42,
          onPressed: _share,
        ),
        const SizedBox(width: 6),
        LuxeIconButton(
          icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          tooltip: context.tr(HomeL10n.wishlist),
          glass: glass,
          active: saved,
          activeColor: const Color(0xFFE5484D),
          size: 42,
          onPressed: () =>
              toggleWishlistItem(context, ref, detail.toWishlistItem()),
        ),
      ],
    );
  }
}

/// Title, grades, badges, price card, at-a-glance grid and certificate.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail, required this.labels});

  final ProductDetail detail;
  final ProductPriceLabels labels;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget enter(Widget child, int i) => luxeEnter(context, child, i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(LuxeDetailEyebrow(detail: detail), 0),
        const SizedBox(height: 6),
        enter(Text(detail.title, style: LuxeType.display(36, p.ink)), 1),
        const SizedBox(height: 5),
        enter(
          Text(detail.subtitle, style: LuxeType.body(p.inkMuted, size: 15)),
          2,
        ),
        if (detail.jewelryDetail case final j?
            when j.ratingCount > 0 && j.ratingAverage != null) ...[
          const SizedBox(height: 6),
          enter(
            Row(
              children: [
                JewelryStars(rating: j.ratingAverage!, size: 16),
                const SizedBox(width: 6),
                Text(
                  jewelryAverageLabel(j.ratingAverage!),
                  style: LuxeType.label(p.ink, size: 13),
                ),
                Text(
                  ' · ${jewelryReviewCount(context, j.ratingCount)}',
                  style: LuxeType.body(p.inkMuted, size: 13),
                ),
              ],
            ),
            2,
          ),
        ],
        if (detail.badges.isNotEmpty) ...[
          const SizedBox(height: 10),
          enter(
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final b in detail.badges) LuxeDetailBadge(badge: b),
              ],
            ),
            3,
          ),
        ],
        const SizedBox(height: 14),
        if (detail.jewelryDetail != null) ...[
          // Jewelry is priced per chosen variant, so the card lives with
          // the configurator.
          enter(LuxeJewelryPurchasePanel(detail: detail), 4),
          const SizedBox(height: 18),
          enter(LuxeJewelryGlance(detail: detail), 5),
          const SizedBox(height: 12),
        ] else ...[
          enter(LuxePriceCard(labels: labels), 4),
          const SizedBox(height: 18),
          if (detail.highlights.isNotEmpty) ...[
            enter(LuxeGlance(highlights: detail.highlights), 5),
            const SizedBox(height: 12),
          ],
        ],
        if (detail.certification != null &&
            !luxeIsMissing(detail.certification!.authority))
          enter(LuxeCertificateCard(cert: detail.certification!), 6),
      ],
    );
  }
}

/// Bullion overview and specification rows as luxe spec tabs; seller info
/// is shown by the shared seller panel below.
ProductTabbedSpecs? _bullionTabs(ProductBullionDetail? bullion) {
  if (bullion == null) return null;
  return ProductTabbedSpecs(
    tabs: [
      ProductSpecTab(
        title: 'Overview',
        isComment: true,
        commentBody: bullion.overview.trim().isEmpty
            ? 'No overview available'
            : bullion.overview,
      ),
      if (bullion.specRows.isNotEmpty)
        ProductSpecTab(
          title: 'Specifications',
          rows: [
            for (final r in bullion.specRows)
              ProductSpec(r.label, r.value.trim().isEmpty ? '-' : r.value),
          ],
        ),
    ],
  );
}

/// Spec tabs, seller and note.
class _Record extends StatelessWidget {
  const _Record({required this.detail, required this.isSeller});

  final ProductDetail detail;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final specs = detail.naturalSpecTabs ?? _bullionTabs(detail.bullionDetail);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Melee pcs / ct entry lives in the sticky purchase bar.
        if (detail.jewelryDetail != null) ...[
          const SizedBox(height: 20),
          ScrollReveal(child: LuxeJewelryRecord(detail: detail)),
          JewelryReviewsSection(
            source: JewelryReviewSource.listing,
            slug: detail.jewelryDetail!.slug,
            shopName: detail.jewelryDetail!.shop?.name ?? '',
            padding: const EdgeInsets.only(top: 18),
          ),
        ] else if (specs != null && specs.tabs.isNotEmpty) ...[
          const SizedBox(height: 20),
          ScrollReveal(child: LuxeSpecTabs(specs: specs)),
        ],
        if (detail.listingSeller != null &&
            detail.listingSeller!.hasAnyData) ...[
          const SizedBox(height: 18),
          ScrollReveal(
            child: ProductDetailSellerPanel(
              seller: detail.listingSeller!,
              // Individual viewers: name only. Business viewers: full contact
              // when the listing seller is also business.
              showContactDetails: isSeller,
            ),
          ),
        ],
        if (detail.note != null) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: p.inkFaint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail.note!,
                  style: LuxeType.body(p.inkMuted, size: 12.5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
