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
import '../../../../core/widgets/app_system_back_scope.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_metal_swatch.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_filter_provider.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';
import '../jewellery_category_images.dart';
import '../widgets/jewelry_showcase_stage.dart';

/// The jewelry house: the entry to the jewelry flow from Browse Collection.
///
/// An always-dark stage leads with the jewelry houses (featured, then all
/// with sort and filters), then a floating search, editorial collection
/// tiles from the marketplace category API, popular styles and metal tones —
/// every path lands on the results page already filtered.
class JewelryCategoriesScreen extends ConsumerStatefulWidget {
  const JewelryCategoriesScreen({super.key});

  @override
  ConsumerState<JewelryCategoriesScreen> createState() =>
      _JewelryCategoriesScreenState();
}

class _JewelryCategoriesScreenState
    extends ConsumerState<JewelryCategoriesScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Applies the entry selection in one update, then opens results.
  void _open({String? category, String? style, String? metal, String? shop}) {
    ref
        .read(jewelryFilterProvider.notifier)
        .openCollection(
          category: category,
          style: style,
          metal: metal,
          shop: shop,
        );
    context.push(AppRouteNames.jewelryListing);
  }

  void _submitSearch(String query) {
    final q = query.trim();
    final n = ref.read(jewelryFilterProvider.notifier)..setSearchQuery(q);
    n.openCollection();
    context.push(AppRouteNames.jewelryListing);
  }

  @override
  Widget build(BuildContext context) {
    return AppSystemBackScope(
      child: LuxeScope(child: Builder(builder: _buildScaffold)),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
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
            onRefresh: () async {
              ref
                ..invalidate(jewelleryCategoriesProvider)
                ..invalidate(jewelryShopsProvider);
              await Future.wait([
                ref
                    .read(jewelleryCategoriesProvider.future)
                    .catchError((_) => const <MarketplaceCategory>[]),
                ref
                    .read(jewelryShopsProvider.future)
                    .catchError((_) => const <MarketplaceShop>[]),
              ]);
            },
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // The search floats over the stage's lower edge. Earlier
                // slivers paint above later ones, so both share one box.
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: JewelryShowcaseStage(
                          topInset: topInset,
                          onOpenHouse: (house) => context.push(
                            AppRouteNames.jewelryHousePath(house.slug),
                            extra: house,
                          ),
                          onShowAll: () =>
                              context.push(AppRouteNames.jewelryHouses),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: p.isDark ? 0.5 : 0.18,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: LuxeSearchField(
                            controller: _search,
                            hintText: context.tr(CatalogL10n.searchJewelry),
                            onChanged: (_) {},
                            onSubmitted: _submitSearch,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ..._collections(context),
                SliverToBoxAdapter(child: _Styles(onOpen: _open)),
                SliverToBoxAdapter(
                  child: _Metals(onOpen: (m) => _open(metal: m)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LuxeFloatingHeader(
              title: context.tr(CatalogL10n.fineJewelry),
              offset: _offset,
              solidAfter: topInset + 120,
              darkBackdrop: true,
              actions: (glass) => [
                CatalogFlowActions(glass: glass, jewelryBag: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _collections(BuildContext context) {
    final categories = ref.watch(jewelleryCategoriesProvider);
    final heading = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: LuxeRowHeading(
          title: context.tr(JewelryFlowL10n.collectionsTitle),
          subtitle: context.tr(JewelryFlowL10n.collectionsSubtitle),
          actionLabel: context.tr(JewelryFlowL10n.shopAll),
          onAction: _open,
        ),
      ),
    );

    return [
      heading,
      ...categories.when(
        loading: () => [const _CollectionSkeleton()],
        error: (error, _) => [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 360,
              child: LuxeStateView(
                icon: Icons.cloud_off_rounded,
                tone: LuxeTone.error,
                title: context.tr(CatalogFlowL10n.errorTitle),
                message: error is Failure
                    ? error.message
                    : context.tr(CatalogL10n.loadJewelryCategoriesError),
                actionLabel: context.tr(CatalogL10n.retry),
                onAction: () => ref.invalidate(jewelleryCategoriesProvider),
              ),
            ),
          ),
        ],
        data: (items) {
          if (items.isEmpty) {
            return [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: LuxeStateView(
                    icon: Icons.diamond_outlined,
                    title: context.tr(CatalogL10n.noCategories),
                    message: context.tr(CatalogL10n.categoriesComing),
                  ),
                ),
              ),
            ];
          }
          return [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _CollectionGrid(
                  items: items,
                  onOpen: (c) => _open(category: c.slug),
                ),
              ),
            ),
          ];
        },
      ),
    ];
  }
}

/// Editorial collection layout: the first collection as a wide feature
/// tile, the rest in a two-column grid. Tiles tilt toward the finger and
/// reveal as they scroll in.
class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({required this.items, required this.onOpen});

  final List<MarketplaceCategory> items;
  final ValueChanged<MarketplaceCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cell = (w - gap) / 2;
        final rest = items.skip(1).toList();
        return Column(
          children: [
            ScrollReveal(
              child: SizedBox(
                height: w * 0.72,
                child: _CollectionTile(
                  category: items.first,
                  feature: true,
                  onTap: () => onOpen(items.first),
                ),
              ),
            ),
            if (rest.isNotEmpty) const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < rest.length; i++)
                  ScrollReveal(
                    delay: Duration(milliseconds: (i % 2) * 90),
                    child: SizedBox(
                      width: cell,
                      height: cell * 1.28,
                      child: _CollectionTile(
                        category: rest[i],
                        onTap: () => onOpen(rest[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.category,
    required this.onTap,
    this.feature = false,
  });

  final MarketplaceCategory category;
  final VoidCallback onTap;
  final bool feature;

  String _styleLabel(BuildContext context) {
    final count = category.children.length;
    if (count <= 0) return '';
    return count == 1
        ? context.tr(JewelryFlowL10n.styleOne)
        : context.tr(JewelryFlowL10n.styleCount, {'count': count});
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final asset = JewelleryCategoryImages.assetFor(category.slug);
    final networkUrl = JewelleryCategoryImages.absoluteUrl(category.imageUrl);
    final fallback = Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: p.surfaceRaised,
        child: Icon(Icons.diamond_outlined, color: p.accent, size: 36),
      ),
    );
    final styles = _styleLabel(context);

    return PressTilt(
      semanticLabel: category.name,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            networkUrl == null
                ? fallback
                : AppNetworkImage(url: networkUrl, error: fallback),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x14000000),
                    Color(0xB3000000),
                  ],
                  stops: [0.35, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: feature ? 20 : 14,
              right: feature ? 20 : 14,
              bottom: feature ? 18 : 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(
                            feature ? 34 : 24,
                            LuxeStage.ink,
                          ),
                        ),
                        if (styles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            styles.toUpperCase(),
                            style: LuxeType.eyebrow(
                              LuxeStage.gold,
                            ).copyWith(fontSize: 9.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: feature ? 40 : 32,
                    height: feature ? 40 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuxeStage.glass,
                      border: Border.all(color: LuxeStage.glassBorder),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: feature ? 18 : 15,
                      color: LuxeStage.ink,
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

class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 32;
    final cell = (w - 12) / 2;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            LuxeSkeleton(
              width: double.infinity,
              height: w * 0.72,
              radius: LuxeSpace.radius,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                LuxeSkeleton(
                  width: cell,
                  height: cell * 1.28,
                  radius: LuxeSpace.radius,
                ),
                const SizedBox(width: 12),
                LuxeSkeleton(
                  width: cell,
                  height: cell * 1.28,
                  radius: LuxeSpace.radius,
                ),
              ],
            ),
          ],
        ),
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
    final live = ref.watch(jewelleryCategoriesProvider).valueOrNull;
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
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LuxeRowHeading(
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
      child: Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LuxeRowHeading(
              title: context.tr(JewelryFlowL10n.metalsTitle),
              subtitle: context.tr(JewelryFlowL10n.metalsSubtitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (i, metal)
                      in MarketplaceEnums.quickMetals.indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
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
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          children: [
            LuxeMetalSwatch(
              label: MarketplaceEnums.swatchLabel(metal),
              size: 44,
            ),
            const SizedBox(height: 10),
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
