import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_house_providers.dart';
import '../../domain/models/marketplace_listing.dart';
import '../../../jewelry_reviews/data/jewelry_review_repository.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_review_stars.dart';
import '../../../jewelry_reviews/presentation/widgets/jewelry_reviews_section.dart';
import '../widgets/jewelry_house_collections.dart';
import '../widgets/jewelry_house_parts.dart';

/// One jewelry house: its banner, identity, story and policies from
/// `GET /marketplace/shops/{slug}`, then its collections as a carousel. A
/// collection opens that house's own collection page (pieces, styles and
/// filters for this house only).
class JewelryHouseScreen extends ConsumerStatefulWidget {
  const JewelryHouseScreen({required this.slug, this.preview, super.key});

  final String slug;

  /// Card data from the list, shown while the full house loads.
  final MarketplaceShop? preview;

  @override
  ConsumerState<JewelryHouseScreen> createState() => _JewelryHouseScreenState();
}

class _JewelryHouseScreenState extends ConsumerState<JewelryHouseScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _openCollection(String category) {
    context.push(
      AppRouteNames.jewelryHouseCollectionPath(widget.slug, category),
      extra: ref.read(jewelryShopProvider(widget.slug)).value ?? widget.preview,
    );
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(jewelryShopProvider(widget.slug))
      ..invalidate(jewelryHouseCollectionsProvider(widget.slug));
    await ref
        .read(jewelryShopProvider(widget.slug).future)
        .then<void>((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final houseAsync = ref.watch(jewelryShopProvider(widget.slug));
    final house = houseAsync.value ?? widget.preview;
    final topInset = MediaQuery.paddingOf(context).top + 64;

    return AppScaffold(
      backgroundColor: p.canvas,
      safeTop: false,
      body: Stack(
        children: [
          RefreshIndicator(
            color: p.ink,
            backgroundColor: p.surface,
            edgeOffset: topInset,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                if (house == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: houseAsync.hasError
                        ? LuxeStateView(
                            icon: Icons.cloud_off_rounded,
                            tone: LuxeTone.error,
                            title: context.tr(CatalogFlowL10n.errorTitle),
                            message: houseAsync.error is Failure
                                ? (houseAsync.error! as Failure).message
                                : context.tr(JewelryFlowL10n.housesError),
                            actionLabel: context.tr(CatalogL10n.retry),
                            onAction: () => ref.invalidate(
                              jewelryShopProvider(widget.slug),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _Hero(
                      house: house,
                      details: houseAsync.value,
                      preview: widget.preview,
                      topInset: topInset,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: JewelryHouseCollections(
                      shop: widget.slug,
                      onOpen: _openCollection,
                    ),
                  ),
                  SliverToBoxAdapter(child: _About(house: house)),
                  SliverToBoxAdapter(child: _Policies(house: house)),
                  SliverToBoxAdapter(
                    child: JewelryReviewsSection(
                      source: JewelryReviewSource.shop,
                      slug: widget.slug,
                      shopName: house.name,
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                    ),
                  ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom + 40,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LuxeFloatingHeader(
              title: house?.name ?? '',
              offset: _offset,
              solidAfter: 220,
              darkBackdrop: true,
              actions: (glass) => [TopBarActions(glass: glass)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner fading into the dark stage, then logo, name, headline and stats.
///
/// The list card ([preview]) carries the piece count but no policies, the
/// full record ([details]) the reverse, so the stats wait for the full
/// record and merge both: shown once, never swapped.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.house,
    required this.details,
    required this.preview,
    required this.topInset,
  });

  final MarketplaceShop house;
  final MarketplaceShop? details;
  final MarketplaceShop? preview;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final banner = house.bannerUrl;
    final details = this.details;
    final city = details == null ? null : JewelryHouses.cityOf(details);
    final pieces = details == null
        ? null
        : details.listingCount ??
              preview?.listingCount ??
              (details.listings.isEmpty ? null : details.listings.length);
    final headline = house.headline?.trim();
    final bannerHeight = topInset + 170;

    return Stack(
      children: [
        const Positioned.fill(child: JewelryStageBackdrop()),
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: AppNetworkImage(url: banner, error: const SizedBox()),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: bannerHeight + 1,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LuxeStage.obsidian.withValues(alpha: 0.45),
                    LuxeStage.obsidian.withValues(alpha: 0.15),
                    LuxeStage.obsidian,
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(14, bannerHeight - 52, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JewelryHouseLogo(house: house, radius: 38),
              const SizedBox(height: 10),
              Text(house.name, style: LuxeType.display(34, LuxeStage.ink)),
              if (headline != null && headline.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  headline,
                  style: LuxeType.body(LuxeStage.inkMuted, size: 14),
                ),
              ],
              const SizedBox(height: 12),
              // Space kept while the full record loads, so nothing jumps.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 30),
                child: AnimatedOpacity(
                  opacity: details == null ? 0 : 1,
                  duration: LuxeMotion.medium,
                  curve: LuxeMotion.settle,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (details != null &&
                          details.ratingCount > 0 &&
                          details.ratingAverage != null)
                        _StatPill(
                          icon: Icons.star_rounded,
                          label:
                              '${jewelryAverageLabel(details.ratingAverage!)}'
                              ' · ${jewelryReviewCount(context, details.ratingCount)}',
                        ),
                      if (pieces != null)
                        _StatPill(
                          icon: Icons.diamond_outlined,
                          label: context.tr(JewelryMarketL10n.shopPieces, {
                            'count': pieces,
                          }),
                        ),
                      if (city != null)
                        _StatPill(icon: Icons.place_outlined, label: city),
                      if (details?.showPriceBreakdown ?? false)
                        _StatPill(
                          icon: Icons.receipt_long_outlined,
                          label: context.tr(JewelryFlowL10n.priceBreakup),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const ShapeDecoration(
        color: LuxeStage.glass,
        shape: StadiumBorder(side: BorderSide(color: LuxeStage.glassBorder)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LuxeStage.gold),
          const SizedBox(width: 5),
          Text(label, style: LuxeType.label(LuxeStage.ink, size: 12)),
        ],
      ),
    );
  }
}

/// The house's own description, collapsed to a few lines.
class _About extends StatefulWidget {
  const _About({required this.house});

  final MarketplaceShop house;

  @override
  State<_About> createState() => _AboutState();
}

class _AboutState extends State<_About> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.house.description?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    final style = LuxeType.body(p.inkMuted, size: 14);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 4,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final long = painter.didExceedMaxLines;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(JewelryFlowL10n.aboutHouse).toUpperCase(),
                style: LuxeType.eyebrow(p.accent),
              ),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                alignment: Alignment.topCenter,
                child: Text(
                  text,
                  maxLines: _open ? null : 4,
                  overflow: _open ? null : TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              if (long)
                TextButton(
                  onPressed: () => setState(() => _open = !_open),
                  style: TextButton.styleFrom(
                    foregroundColor: p.accent,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    context.tr(
                      _open
                          ? JewelryFlowL10n.readLess
                          : JewelryFlowL10n.readMore,
                    ),
                    style: LuxeType.label(p.accent, size: 13),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Shop policies the house filled in (processing, shipping, returns, …).
class _Policies extends StatelessWidget {
  const _Policies({required this.house});

  final MarketplaceShop house;

  static const _known = [
    (
      'processingTime',
      Icons.schedule_rounded,
      JewelryMarketL10n.processingTime,
    ),
    ('shipping', Icons.local_shipping_outlined, JewelryMarketL10n.shipping),
    ('returns', Icons.assignment_return_outlined, JewelryMarketL10n.returns),
    ('location', Icons.place_outlined, JewelryMarketL10n.location),
  ];

  @override
  Widget build(BuildContext context) {
    final policies = house.policies;
    final rows = [
      for (final (key, icon, label) in _known)
        if (policies[key] case final value?)
          (icon: icon, label: context.tr(label), value: value),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final p = LuxePalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 5),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(JewelryMarketL10n.shopPolicies).toUpperCase(),
              style: LuxeType.eyebrow(p.accent),
            ),
            const SizedBox(height: 8),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.icon, size: 18, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label, style: LuxeType.label(p.ink, size: 13)),
                          const SizedBox(height: 2),
                          Text(
                            r.value,
                            style: LuxeType.body(p.inkMuted, size: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
