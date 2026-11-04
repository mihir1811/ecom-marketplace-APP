import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_actions.dart';
import '../../../product_detail/application/suggested_seller_products_provider.dart';
import '../../../product_detail/domain/models/product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import 'spotlight_shop_screen.dart';

/// "View all" from a seller's shop: every piece the seller has for sale in
/// one section, two to a row, loading more as the list nears its end.
class SpotlightShopSectionScreen extends ConsumerStatefulWidget {
  const SpotlightShopSectionScreen({
    required this.sellerId,
    required this.segment,
    super.key,
    this.sellerName,
  });

  final String sellerId;
  final ProductSegment segment;
  final String? sellerName;

  @override
  ConsumerState<SpotlightShopSectionScreen> createState() =>
      _SpotlightShopSectionScreenState();
}

class _SpotlightShopSectionScreenState
    extends ConsumerState<SpotlightShopSectionScreen> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  SuggestedSellerProductsQuery get _query => SuggestedSellerProductsQuery(
    segment: widget.segment,
    excludeProductId: '',
    sellerId: widget.sellerId,
  );

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
    if (!_scroll.hasClients) return;
    _offset.value = _scroll.offset;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - pos.viewportDimension) {
      ref.read(suggestedSellerProductsProvider(_query).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final p = LuxePalette.of(context);
    final state = ref.watch(suggestedSellerProductsProvider(_query));
    final items = state.items;
    final name = widget.sellerName?.trim() ?? '';
    final section = context.tr(spotlightShopSectionTitleKey(widget.segment));
    const pad = 12.0;
    const gap = 8.0;
    final cell = (MediaQuery.sizeOf(context).width - pad * 2 - gap) / 2;
    final extent =
        cell + spotlightShopCardTextExtent(MediaQuery.textScalerOf(context));

    final List<Widget> body;
    if (state.isInitialLoading) {
      body = [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 6, pad, 0),
          sliver: SliverToBoxAdapter(child: LuxeSkeleton(height: 320)),
        ),
      ];
    } else if (items.isEmpty) {
      body = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: state.errorMessage != null
              ? LuxeStateView(
                  icon: Icons.cloud_off_rounded,
                  tone: LuxeTone.error,
                  title: section,
                  message: state.errorMessage!,
                  actionLabel: context.tr(CatalogL10n.retry),
                  onAction: () => ref
                      .read(suggestedSellerProductsProvider(_query).notifier)
                      .loadFirstPage(),
                )
              : LuxeStateView(
                  icon: Icons.storefront_outlined,
                  title: context.tr(SpotlightL10n.shopEmpty),
                  message: context.tr(SpotlightL10n.shopEmptyBody),
                ),
        ),
      ];
    } else {
      body = [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(pad, 6, pad, 0),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: extent,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final d = items[i];
              return SpotlightShopProductCard(
                detail: d,
                onTap: () => openProductDetail(context, d),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              14,
              12,
              48 + MediaQuery.paddingOf(context).bottom,
            ),
            child: state.isLoadingMore
                ? LuxeLoadingMore(
                    label: context.tr(DiamondFlowL10n.loadingMore),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ];
    }

    return AppScaffold(
      backgroundColor: p.canvas,
      appBar: LuxeTopBar(
        title: section,
        subtitle: LuxeCountLine(
          text: [
            if (name.isNotEmpty) name,
            if (!state.isInitialLoading)
              context.tr(SpotlightL10n.piecesCount, {
                'count': formatGroupedWhole(state.totalCount.toDouble()),
              }),
          ].join(' · '),
        ),
        scrollOffset: _offset,
        actions: const [TopBarActions()],
      ),
      body: RefreshIndicator(
        color: p.ink,
        backgroundColor: p.surface,
        onRefresh: () => ref
            .read(suggestedSellerProductsProvider(_query).notifier)
            .loadFirstPage(),
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: body,
        ),
      ),
    );
  }
}
