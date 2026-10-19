import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/navigation/app_tab_top_bar.dart';
import '../../../catalog_flow/presentation/widgets/catalog_flow_actions.dart';
import '../../application/auction_providers.dart';
import '../../domain/models/auction_models.dart';
import '../widgets/auction_card.dart';
import '../widgets/auction_standing_strip.dart';

/// Live auctions, my activity, or my wins on the shared luxe listing
/// layout: standing / outcome filters scroll away, the product-type chips
/// and grid / list switch stay pinned, cards carry live countdowns.
class AuctionsListScreen extends ConsumerStatefulWidget {
  const AuctionsListScreen({
    required this.kind,
    required this.title,
    this.outcomes = const [],
    super.key,
  });

  final AuctionFeedKind kind;
  final String title;
  final List<String> outcomes;

  @override
  ConsumerState<AuctionsListScreen> createState() => _AuctionsListScreenState();
}

class _AuctionsListScreenState extends ConsumerState<AuctionsListScreen>
    with LuxeListingMixin {
  static const _productTypes = [
    'all',
    'diamond',
    'gemstone',
    'meleeDiamond',
    'jewellery',
  ];

  String? _productType;
  String _outcome = 'all';
  LuxeViewMode _viewMode = LuxeViewMode.list;

  AuctionFeedQuery get _query => AuctionFeedQuery(
    kind: widget.kind,
    outcome: _outcome,
    productType: _productType,
  );

  @override
  void initState() {
    super.initState();
    initListing();
  }

  @override
  void dispose() {
    disposeListing();
    super.dispose();
  }

  @override
  bool get listingCanLoadMore {
    final s = ref.read(auctionFeedProvider(_query));
    return s.hasMore && !s.isLoadingMore && !s.isLoading;
  }

  @override
  void listingLoadMore() =>
      ref.read(auctionFeedProvider(_query).notifier).loadMore();

  @override
  int get listingItemCount =>
      ref.read(auctionFeedProvider(_query)).items.length;

  @override
  LuxeViewMode get listingViewMode => _viewMode;

  @override
  void listingApplyViewMode(LuxeViewMode mode) =>
      setState(() => _viewMode = mode);

  void _setOutcome(String value) {
    if (value == _outcome) return;
    setState(() => _outcome = value);
    _toTop();
  }

  void _setProductType(String value) {
    final next = value == 'all' ? null : value;
    if (next == _productType) return;
    setState(() => _productType = next);
    _toTop();
  }

  /// A new filter starts a fresh feed; show it from the top.
  void _toTop() {
    if (listingScroll.hasClients && listingScroll.offset > 0) {
      listingScroll.jumpTo(0);
    }
  }

  static String _typeLabel(String type) => switch (type) {
    'all' => 'All',
    'diamond' => 'Diamonds',
    'gemstone' => 'Gemstones',
    'meleeDiamond' => 'Melee',
    'jewellery' => 'Jewellery',
    _ => type,
  };

  static String _outcomeLabel(String outcome) => switch (outcome) {
    'all' => 'All',
    'participating' => 'In progress',
    'won' => 'Won',
    'lost' => 'Lost',
    _ => outcome,
  };

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _buildScaffold));
  }

  Widget _buildScaffold(BuildContext context) {
    final p = LuxePalette.of(context);
    final feed = ref.watch(auctionFeedProvider(_query));
    final notifier = ref.read(auctionFeedProvider(_query).notifier);

    return AppScaffold(
      // Runs on behind the floating dock; the scroll view clears it.
      safeBottom: false,
      backgroundColor: p.canvas,
      // Live auctions is a bottom-nav tab: it takes the shared tab bar.
      appBar: widget.kind == AuctionFeedKind.live
          ? const AppTabTopBar()
          : LuxeTopBar(
              title: widget.title,
              scrollOffset: listingOffset,
              actions: const [CatalogFlowActions()],
            ),
      body: LuxeListingScrollView(
        controller: listingScroll,
        offset: listingOffset,
        onRefresh: notifier.refresh,
        onBackToTop: listingBackToTop,
        backToTopLabel: context.tr(DiamondFlowL10n.backToTop),
        slivers: [
          SliverToBoxAdapter(
            child: KeyedSubtree(key: listingHeaderKey, child: _header(feed)),
          ),
          LuxePinnedBar(
            child: Row(
              children: [
                Expanded(
                  child: LuxeQuickChips<String>(
                    chips: [
                      for (final t in _productTypes)
                        LuxeQuickChip(value: t, label: _typeLabel(t)),
                    ],
                    isSelected: (t) => t == (_productType ?? 'all'),
                    onTap: _setProductType,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: LuxeViewToggle(
                    viewMode: _viewMode,
                    onChanged: switchListingViewMode,
                    gridLabel: context.tr(DiamondFlowL10n.grid),
                    listLabel: context.tr(DiamondFlowL10n.list),
                  ),
                ),
              ],
            ),
          ),
          ...luxeResultSlivers<AuctionListing>(
            context: context,
            initialLoading: feed.isLoading && feed.items.isEmpty,
            error: feed.errorMessage,
            items: feed.items,
            isLoadingMore: feed.isLoadingMore,
            viewMode: _viewMode,
            idOf: (a) => a.id,
            cardOf: (a, mode) =>
                AuctionCard(auction: a, grid: mode == LuxeViewMode.grid),
            entered: listingEntered,
            loadingMoreLabel: context.tr(DiamondFlowL10n.loadingMore),
            emptyView: LuxeStateView(
              icon: Icons.gavel_rounded,
              title: 'No auctions',
              message: 'Nothing matches this filter yet.',
              actionLabel: _productType != null || _outcome != 'all'
                  ? context.tr(CatalogL10n.clearAll)
                  : null,
              onAction: () => setState(() {
                _productType = null;
                _outcome = 'all';
              }),
            ),
            errorView: (message) => LuxeStateView(
              icon: Icons.cloud_off_rounded,
              tone: LuxeTone.error,
              title: 'Auctions unavailable',
              message: message,
              actionLabel: context.tr(CatalogL10n.retry),
              onAction: notifier.refresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AuctionFeedState feed) {
    final summary = feed.summary;
    if (widget.kind == AuctionFeedKind.activity && summary != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: AuctionStandingStrip(
          selectedId: _outcome,
          onSelected: _setOutcome,
          items: [
            AuctionStandingItem(
              id: 'all',
              label: 'Participated',
              count: summary.participated,
            ),
            AuctionStandingItem(
              id: 'participating',
              label: 'In progress',
              count: summary.participating,
            ),
            AuctionStandingItem(id: 'won', label: 'Won', count: summary.won),
            AuctionStandingItem(id: 'lost', label: 'Lost', count: summary.lost),
          ],
        ),
      );
    }
    if (widget.outcomes.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
        child: LuxeQuickChips<String>(
          chips: [
            for (final o in widget.outcomes)
              LuxeQuickChip(value: o, label: _outcomeLabel(o)),
          ],
          isSelected: (o) => o == _outcome,
          onTap: _setOutcome,
        ),
      );
    }
    if (widget.kind == AuctionFeedKind.live) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text(
          context.tr(NavL10n.liveAuctions),
          style: LuxeType.display(26, LuxePalette.of(context).ink),
        ),
      );
    }
    return const SizedBox(height: 4);
  }
}
