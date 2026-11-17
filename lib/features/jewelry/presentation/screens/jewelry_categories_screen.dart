import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../spotlight/application/spotlight_providers.dart';
import '../../../spotlight/presentation/widgets/jewellery_banner_carousel.dart';
import '../../../spotlight/presentation/widgets/jewellery_featured_shops.dart';
import '../../../spotlight/presentation/widgets/spotlight_impression.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../application/jewelry_home_providers.dart';
import '../../application/jewelry_premium_providers.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';
import '../widgets/jewelry_home_sections.dart';
import '../widgets/jewelry_luxe_cards.dart';

/// The jewelry home: the entry to the jewelry flow from Browse Collection.
///
/// Ordered the way leading jewelry apps (CaratLane, Tanishq, GIVA,
/// BlueStone, Mejuri) build their homes: search, round category shortcuts,
/// an editorial hero, shop by budget, trending pieces, Premium, gemstones,
/// jewelry houses, metals, styles and a reassurance close. Every shortcut
/// lands on the results page already filtered.
class JewelryCategoriesScreen extends ConsumerStatefulWidget {
  const JewelryCategoriesScreen({super.key});

  @override
  ConsumerState<JewelryCategoriesScreen> createState() =>
      _JewelryCategoriesScreenState();
}

class _JewelryCategoriesScreenState
    extends ConsumerState<JewelryCategoriesScreen> {
  final _offset = ValueNotifier<double>(0);
  final _search = TextEditingController();

  /// Paid spots count one view per ad per visit to this screen.
  final _spotlightVisit = SpotlightVisit();

  @override
  void dispose() {
    _offset.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Opens the results from a home shortcut with only that shortcut applied
  /// and [sort] (null lets the API choose).
  void _openEntry({
    String? category,
    String? metal,
    String? gemstone,
    double? priceMin,
    double? priceMax,
    JewelrySortOption? sort,
  }) {
    ref
        .read(jewelryFilterProvider.notifier)
        .openHomeEntry(
          category: category,
          metal: metal,
          gemstone: gemstone,
          priceMin: priceMin,
          priceMax: priceMax,
        );
    ref.read(jewelrySortProvider.notifier).state = sort;
    context.push(AppRouteNames.jewelryListing);
  }

  /// A style chip: its collection with that style chosen.
  void _openStyle({String? category, String? style, String? metal}) {
    ref
        .read(jewelryFilterProvider.notifier)
        .openCollection(category: category, style: style, metal: metal);
    ref.read(jewelrySortProvider.notifier).state = null;
    context.push(AppRouteNames.jewelryListing);
  }

  void _submitSearch(String query) {
    final q = query.trim();
    final n = ref.read(jewelryFilterProvider.notifier)..setSearchQuery(q);
    n.openCollection();
    ref.read(jewelrySortProvider.notifier).state = null;
    context.push(AppRouteNames.jewelryListing);
  }

  void _openHouse(MarketplaceShop house) =>
      context.push(AppRouteNames.jewelryHousePath(house.slug), extra: house);

  Future<void> _refresh() async {
    ref
      ..invalidate(jewelleryCategoriesProvider)
      ..invalidate(jewelryShopsProvider)
      ..invalidate(jewelryPremiumStripProvider)
      ..invalidate(jewelryHomeRailProvider)
      ..invalidate(spotlightProvider(JewelleryBannerCarousel.query))
      ..invalidate(spotlightProvider(JewelleryFeaturedShops.query));
    await Future.wait([
      ref
          .read(jewelleryCategoriesProvider.future)
          .catchError((_) => const <MarketplaceCategory>[]),
      ref
          .read(jewelryShopsProvider.future)
          .catchError((_) => const <MarketplaceShop>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top + 58;
    const gap = SliverToBoxAdapter(child: SizedBox(height: 32));

    SliverToBoxAdapter reveal(Widget child) =>
        SliverToBoxAdapter(child: ScrollReveal(child: child));

    Widget titled(String title, String subtitle, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JewelryHomeHeading(title: title, subtitle: subtitle),
        child,
      ],
    );

    return AppScaffold(
      backgroundColor: p.canvas,
      safeTop: false,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.depth == 0) _offset.value = n.metrics.pixels;
              return false;
            },
            child: RefreshIndicator(
              color: p.ink,
              backgroundColor: p.surface,
              edgeOffset: topInset,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topInset + 4)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: LuxeSearchField(
                        controller: _search,
                        hintText: context.tr(CatalogL10n.searchJewelry),
                        onChanged: (_) {},
                        onSubmitted: _submitSearch,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: JewelryHeroCarousel(
                      onOpen: (slug) => _openEntry(category: slug),
                    ),
                  ),
                  // Paid banners; hidden when none runs.
                  SliverToBoxAdapter(
                    child: JewelleryBannerCarousel(
                      visit: _spotlightVisit,
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
                    ),
                  ),
                  gap,
                  reveal(
                    titled(
                      context.tr(JewelryFlowL10n.homeBudgetTitle),
                      context.tr(JewelryFlowL10n.homeBudgetSubtitle),
                      JewelryBudgetGrid(
                        onOpen: (b) =>
                            _openEntry(priceMin: b.min, priceMax: b.max),
                      ),
                    ),
                  ),
                  gap,
                  reveal(
                    JewelryTrendingRail(
                      onViewAll: (sort) => _openEntry(sort: sort),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _PremiumStrip()),
                  gap,
                  reveal(
                    titled(
                      context.tr(JewelryFlowL10n.homeGemsTitle),
                      context.tr(JewelryFlowL10n.homeGemsSubtitle),
                      JewelryGemstoneRail(
                        onOpen: (g) => _openEntry(gemstone: g),
                      ),
                    ),
                  ),
                  gap,
                  reveal(
                    JewelryHouseRail(
                      onOpen: _openHouse,
                      onShowAll: () =>
                          context.push(AppRouteNames.jewelryHouses),
                    ),
                  ),
                  // Paid shop cards; hidden when none runs.
                  SliverToBoxAdapter(
                    child: JewelleryFeaturedShops(
                      visit: _spotlightVisit,
                      gutter: 12,
                      padding: const EdgeInsets.only(top: 28),
                    ),
                  ),
                  gap,
                  SliverToBoxAdapter(
                    child: _Metals(onOpen: (m) => _openEntry(metal: m)),
                  ),
                  SliverToBoxAdapter(child: _Styles(onOpen: _openStyle)),
                  gap,
                  reveal(const JewelryTrustStrip()),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40 + MediaQuery.paddingOf(context).bottom,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LuxeFloatingHeader(
              title: context.tr(CatalogL10n.fineJewelry),
              offset: _offset,
              // Always solid: the page opens on the canvas, not a stage.
              solidAfter: 0,
              actions: (glass) => [TopBarActions(glass: glass)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Popular styles across every collection; each opens its collection with
/// that style already chosen.
class _Styles extends ConsumerWidget {
  const _Styles({required this.onOpen});

  final void Function({String? category, String? style, String? metal}) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(jewelleryCategoriesProvider).value;
    if (live == null) return const SizedBox.shrink();
    final seen = <String>{};
    final styles = [
      for (final c in live)
        for (final s in c.children)
          if (seen.add(s.slug)) (category: c.slug, style: s.slug, name: s.name),
    ].take(14).toList();
    if (styles.isEmpty) return const SizedBox.shrink();

    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JewelryHomeHeading(
              title: context.tr(JewelryFlowL10n.stylesTitle),
              subtitle: context.tr(JewelryFlowL10n.stylesSubtitle),
            ),
            LuxeQuickChips<({String category, String style, String name})>(
              chips: [
                for (final s in styles) LuxeQuickChip(value: s, label: s.name),
              ],
              isSelected: (_) => false,
              onTap: (s) => onOpen(category: s.category, style: s.style),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metal tones as large polished discs; each opens every collection in
/// that metal (`metal` is the API enum, e.g. `ROSE_GOLD`).
class _Metals extends StatelessWidget {
  const _Metals({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return ScrollReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JewelryHomeHeading(
            title: context.tr(JewelryFlowL10n.metalsTitle),
            subtitle: context.tr(JewelryFlowL10n.metalsSubtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // Equal-height tiles, content pinned to the top so swatches
            // line up whether a label takes one line or two.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, metal)
                      in MarketplaceEnums.quickMetals.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _MetalTile(
                        metal: metal,
                        palette: p,
                        onTap: () => onOpen(metal),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalTile extends StatelessWidget {
  const _MetalTile({
    required this.metal,
    required this.palette,
    required this.onTap,
  });

  final String metal;
  final LuxePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final label = context.trCatalogValue(MarketplaceEnums.label(metal));
    return PressTilt(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            LuxeMetalSwatch(
              label: MarketplaceEnums.swatchLabel(metal),
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.ink, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium band: the newest pieces at or above GemWorld's Premium amount
/// (read live), with "View all". Hidden when the route isn't deployed, on
/// an error, or when no piece reaches the amount.
class _PremiumStrip extends ConsumerWidget {
  const _PremiumStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(jewelryPremiumStripProvider).value;
    if (page == null || !page.isVisible) return const SizedBox.shrink();
    final items = page.items;
    final width = LuxeListingMetrics.gridCell(context);
    final height = LuxeListingMetrics.gridExtent(context);
    final isDark = LuxePalette.of(context).isDark;
    // Deep midnight-slate band (no gold) so Premium reads as its own
    // section against the warm canvas.
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1C2230), Color(0xFF11141C)]
              : const [Color(0xFF232A38), Color(0xFF0F131A)],
        ),
        border: const Border.symmetric(
          horizontal: BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JewelryHomeHeading(
            title: context.tr(JewelryMarketL10n.premiumSegment),
            subtitle: context.tr(JewelryMarketL10n.premiumTagline),
            actionLabel: context.tr(JewelryMarketL10n.viewAll),
            onAction: () => context.push(AppRouteNames.jewelryPremium),
            onDark: true,
          ),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: LuxeListingMetrics.pad,
              ),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: LuxeListingMetrics.gap),
              itemBuilder: (context, i) => SizedBox(
                width: width,
                child: JewelryLuxeGridCard(
                  jewelry: items[i],
                  onTap: () =>
                      openJewelryDetail(context, items[i], among: items),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
