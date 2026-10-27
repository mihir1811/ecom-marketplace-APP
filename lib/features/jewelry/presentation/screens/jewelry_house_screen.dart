import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../../jewelry_checkout/presentation/widgets/jewelry_bag_button.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_house_providers.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/marketplace_listing.dart';
import '../widgets/jewelry_filter_labels.dart';
import '../widgets/jewelry_house_parts.dart';
import '../widgets/jewelry_luxe_cards.dart';

/// One jewelry house: its banner, identity, story and policies from
/// `GET /marketplace/shops/{slug}`, then only its own pieces (paged from
/// `GET /marketplace/listings?shop=`) with sort and category chips.
class JewelryHouseScreen extends ConsumerStatefulWidget {
  const JewelryHouseScreen({required this.slug, this.preview, super.key});

  final String slug;

  /// Card data from the list, shown while the full house loads.
  final MarketplaceShop? preview;

  @override
  ConsumerState<JewelryHouseScreen> createState() => _JewelryHouseScreenState();
}

class _JewelryHouseScreenState extends ConsumerState<JewelryHouseScreen> {
  static const _sorts = [
    JewelrySortOption.newest,
    JewelrySortOption.popular,
    JewelrySortOption.priceAsc,
    JewelrySortOption.priceDesc,
  ];

  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);
  final _entered = <String>{};
  JewelrySortOption _sort = JewelrySortOption.newest;
  String? _category;

  JewelryHouseQuery get _query =>
      (shop: widget.slug, category: _category, sort: _sort);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _onScroll() {
    _offset.value = _scroll.offset;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 600) {
      ref.read(jewelryHousePiecesProvider(_query).notifier).loadNextPage();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(jewelryShopProvider(widget.slug));
    await Future.wait([
      ref.read(jewelryHousePiecesProvider(_query).notifier).refresh(),
      ref
          .read(jewelryShopProvider(widget.slug).future)
          .then<void>((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final houseAsync = ref.watch(jewelryShopProvider(widget.slug));
    final house = houseAsync.valueOrNull ?? widget.preview;
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
                    child: _Hero(house: house, topInset: topInset),
                  ),
                  SliverToBoxAdapter(child: _About(house: house)),
                  SliverToBoxAdapter(child: _Policies(house: house)),
                  SliverToBoxAdapter(
                    child: _PiecesHeader(
                      house: houseAsync.valueOrNull,
                      sorts: _sorts,
                      sort: _sort,
                      category: _category,
                      total: ref.watch(
                        jewelryHousePiecesProvider(_query).select(
                          (s) => s.isInitialLoading ? null : s.totalCount,
                        ),
                      ),
                      onSort: (s) => setState(() => _sort = s),
                      onCategory: (c) => setState(() => _category = c),
                    ),
                  ),
                  ..._pieces(context),
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
              actions: (glass) => [
                JewelryBagButton(glass: glass),
                CatalogFlowActions(glass: glass),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pieces(BuildContext context) {
    final state = ref.watch(jewelryHousePiecesProvider(_query));
    final items = state.items;
    return luxeResultSlivers(
      context: context,
      initialLoading: state.isInitialLoading,
      error: state.errorMessage,
      items: items,
      isLoadingMore: state.isLoadingMore,
      viewMode: LuxeViewMode.grid,
      idOf: (j) => j.id,
      cardOf: (j, _) => JewelryLuxeGridCard(
        jewelry: j,
        onTap: () => openJewelryDetail(context, j, among: items),
      ),
      entered: _entered,
      loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
      emptyView: LuxeStateView(
        icon: Icons.diamond_outlined,
        title: context.tr(CatalogL10n.noProducts),
        message: context.tr(JewelryFlowL10n.housePiecesEmpty),
        actionLabel: _category == null
            ? null
            : context.tr(JewelryFlowL10n.allCategories),
        onAction: _category == null
            ? null
            : () => setState(() => _category = null),
      ),
      errorView: (message) => LuxeStateView(
        icon: Icons.cloud_off_rounded,
        tone: LuxeTone.error,
        title: context.tr(CatalogFlowL10n.errorTitle),
        message: message,
        actionLabel: context.tr(CatalogL10n.retry),
        onAction: () =>
            ref.read(jewelryHousePiecesProvider(_query).notifier).refresh(),
      ),
    );
  }
}

/// Banner fading into the dark stage, then logo, name, headline and stats.
class _Hero extends StatelessWidget {
  const _Hero({required this.house, required this.topInset});

  final MarketplaceShop house;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final banner = house.bannerUrl;
    final city = JewelryHouses.cityOf(house);
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
          padding: EdgeInsets.fromLTRB(20, bannerHeight - 52, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JewelryHouseLogo(house: house, radius: 38),
              const SizedBox(height: 14),
              Text(house.name, style: LuxeType.display(34, LuxeStage.ink)),
              if (headline != null && headline.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: LuxeType.body(LuxeStage.inkMuted, size: 14),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (house.listingCount != null)
                    _StatPill(
                      icon: Icons.diamond_outlined,
                      label: context.tr(JewelryMarketL10n.shopPieces, {
                        'count': house.listingCount,
                      }),
                    ),
                  if (city != null)
                    _StatPill(icon: Icons.place_outlined, label: city),
                  if (house.showPriceBreakdown)
                    _StatPill(
                      icon: Icons.receipt_long_outlined,
                      label: context.tr(JewelryFlowL10n.priceBreakup),
                    ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const ShapeDecoration(
        color: LuxeStage.glass,
        shape: StadiumBorder(
          side: BorderSide(color: LuxeStage.glassBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LuxeStage.gold),
          const SizedBox(width: 6),
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
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
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
              const SizedBox(height: 10),
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
                      _open ? JewelryFlowL10n.readLess : JewelryFlowL10n.readMore,
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
    ('processingTime', Icons.schedule_rounded, JewelryMarketL10n.processingTime),
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
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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
            const SizedBox(height: 12),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(r.icon, size: 18, color: p.accent),
                    const SizedBox(width: 12),
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

/// "Pieces · N", sort chips and the house's own categories.
class _PiecesHeader extends ConsumerWidget {
  const _PiecesHeader({
    required this.house,
    required this.sorts,
    required this.sort,
    required this.category,
    required this.total,
    required this.onSort,
    required this.onCategory,
  });

  /// Full record (with listings) once loaded; null while previewing.
  final MarketplaceShop? house;
  final List<JewelrySortOption> sorts;
  final JewelrySortOption sort;
  final String? category;
  final int? total;
  final ValueChanged<JewelrySortOption> onSort;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final live = ref.watch(jewelleryCategoriesProvider).valueOrNull ?? const [];
    // Top-level categories this house actually sells in.
    final used = <String>{
      for (final l in house?.listings ?? const <MarketplaceListing>[]) ...[
        ?l.parentCategorySlug,
        ?l.categorySlug,
      ],
    };
    final categories = [
      for (final c in live)
        if (used.contains(c.slug) || c.children.any((s) => used.contains(s.slug)))
          c,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(JewelryFlowL10n.housePieces).toUpperCase(),
                  style: LuxeType.eyebrow(p.accent),
                ),
                if (total != null)
                  Text(
                    context.tr(JewelryFlowL10n.results, {'count': total}),
                    style: LuxeType.label(p.inkMuted, size: 12),
                  ),
              ],
            ),
          ),
          LuxeQuickChips<JewelrySortOption>(
            chips: [
              for (final s in sorts)
                LuxeQuickChip(value: s, label: jewelrySortLabel(context, s)),
            ],
            isSelected: (s) => s == sort,
            onTap: onSort,
          ),
          if (categories.length > 1) ...[
            const SizedBox(height: 10),
            LuxeQuickChips<String?>(
              dense: true,
              chips: [
                LuxeQuickChip(
                  value: null,
                  label: context.tr(JewelryFlowL10n.allCategories),
                ),
                for (final c in categories)
                  LuxeQuickChip(value: c.slug, label: c.name),
              ],
              isSelected: (c) => c == category,
              onTap: onCategory,
            ),
          ],
        ],
      ),
    );
  }
}
