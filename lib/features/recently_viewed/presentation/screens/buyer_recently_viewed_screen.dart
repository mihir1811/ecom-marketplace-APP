import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/catalog_content_sized_grid.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../../core/widgets/catalog_missing_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../../core/widgets/view_mode_toggle.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_category.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/recently_viewed_list_provider.dart';
import '../../application/recently_viewed_providers.dart';
import '../../domain/models/recently_viewed.dart';
import '../widgets/../../../buyer/presentation/widgets/buyer_layout.dart';
import '../widgets/recently_viewed_badge.dart';

enum _ViewMode { grid, list }

class BuyerRecentlyViewedScreen extends ConsumerStatefulWidget {
  const BuyerRecentlyViewedScreen({super.key});

  @override
  ConsumerState<BuyerRecentlyViewedScreen> createState() =>
      _BuyerRecentlyViewedScreenState();
}

class _BuyerRecentlyViewedScreenState
    extends ConsumerState<BuyerRecentlyViewedScreen> {
  final ScrollController _scrollController = ScrollController();
  _ViewMode _viewMode = _ViewMode.grid;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final page = ref.read(recentlyViewedListProvider).valueOrNull;
    if (page == null || !page.hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(recentlyViewedListProvider.notifier).loadMore();
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all recently viewed?'),
        content: const Text(
          'This will remove all items from your recently viewed history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    try {
      await ref.read(recentlyViewedListProvider.notifier).clearAll();
      ref.read(recentlyViewedIdsProvider.notifier).clearLocal();
      if (!mounted) return;
      ref.invalidate(recentlyViewedListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recently viewed items cleared'),
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(recentlyViewedListProvider);
    final mutedColor = AppColors.textSecondary(context);

    return BuyerLayout(
      title: 'Recently Viewed',
      child: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.terracotta,
                ),
                const SizedBox(height: AppSpacing.s24),
                Text(
                  'Failed to load recently viewed items.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.terracotta),
                ),
                const SizedBox(height: AppSpacing.s24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(recentlyViewedListProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const CatalogEmptyState(
              icon: Icons.history,
              title: 'No recently viewed items',
              message:
                  'Items you view will appear here so you can find them again.',
            );
          }
          return Column(
            children: [
              _buildHeader(page, mutedColor),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(recentlyViewedListProvider.notifier).refresh(),
                  child: _viewMode == _ViewMode.grid
                      ? _buildGrid(page)
                      : _buildList(page),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(RecentlyViewedListPage page, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Row(
        children: [
          Text(
            '${page.total} item${page.total == 1 ? '' : 's'}',
            style: AppTypography.caption.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ViewModeToggle(
            isGrid: _viewMode == _ViewMode.grid,
            onGrid: () => setState(() => _viewMode = _ViewMode.grid),
            onList: () => setState(() => _viewMode = _ViewMode.list),
          ),
          const SizedBox(width: AppSpacing.s8),
          if (_clearing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear all'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                textStyle: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(RecentlyViewedListPage page) {
    return CatalogContentSizedGrid(
      controller: _scrollController,
      itemCount: page.items.length,
      isLoadingMore: page.hasMore,
      itemBuilder: (context, index) =>
          _RecentlyViewedGridCard(entry: page.items[index]),
    );
  }

  Widget _buildList(RecentlyViewedListPage page) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s8,
        bottom: AppSpacing.s24,
      ),
      itemCount: page.items.length + (page.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= page.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Text(
                  'Loading more...',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s12),
          child: _RecentlyViewedListCard(entry: page.items[index]),
        );
      },
    );
  }
}

/// Grid card matching [GemstoneCardGrid] / [DiamondCardGrid] layout + actions.
class _RecentlyViewedGridCard extends ConsumerWidget {
  const _RecentlyViewedGridCard({required this.entry});

  final RecentlyViewedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = AppColors.textPrimary(context);
    final mutedColor = AppColors.textSecondary(context);
    final wishlistItem = _wishlistItemFor(entry);
    final compareItem = _compareItemFor(entry);
    final inCompare = compareItem == null
        ? false
        : ref.watch(isInComparisonProvider(entry.productId));
    final priceLabel = _formattedPrice(entry);
    final gradesLine = entry.detailLine;
    final metaLine = entry.metaLine;

    return MarketplaceProductCardShell(
      onTap: () => _openProduct(context, ref, entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.05,
            child: Stack(
              children: [
                Positioned.fill(child: _ProductThumb(entry: entry)),
                Positioned(
                  top: AppSpacing.s4,
                  right: AppSpacing.s4,
                  child: WishlistToggleButton(
                    item: wishlistItem,
                    size: 18,
                  ),
                ),
                if (compareItem != null)
                  Positioned(
                    bottom: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: CompareAddButton(
                      isSelected: inCompare,
                      onPressed: () => handleCompareToggle(
                        context,
                        ref,
                        compareItem,
                      ),
                    ),
                  ),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: AvailabilityStatusBadge(
                    status: entry.availability,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
                AppSpacing.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTitle,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (gradesLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      gradesLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (metaLine != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      metaLine,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      if (priceLabel != null)
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.bronze,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// List card matching [GemstoneCardList] / [DiamondCardList] layout + actions.
class _RecentlyViewedListCard extends ConsumerWidget {
  const _RecentlyViewedListCard({required this.entry});

  final RecentlyViewedEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = AppColors.textPrimary(context);
    final mutedColor = AppColors.textSecondary(context);
    final wishlistItem = _wishlistItemFor(entry);
    final compareItem = _compareItemFor(entry);
    final inCompare = compareItem == null
        ? false
        : ref.watch(isInComparisonProvider(entry.productId));
    final priceLabel = _formattedPrice(entry);
    final meta = entry.metaLine;

    return MarketplaceProductCardShell(
      onTap: () => _openProduct(context, ref, entry),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _ProductThumb(entry: entry, cover: true),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  left: AppSpacing.s8,
                  child: AvailabilityStatusBadge(
                    status: entry.availability,
                  ),
                ),
                Positioned(
                  top: AppSpacing.s8,
                  right: AppSpacing.s8,
                  child: WishlistToggleButton(
                    item: wishlistItem,
                    size: 18,
                  ),
                ),
                if (compareItem != null)
                  Positioned(
                    bottom: AppSpacing.s8,
                    right: AppSpacing.s8,
                    child: CompareAddButton(
                      size: 32,
                      isSelected: inCompare,
                      onPressed: () => handleCompareToggle(
                        context,
                        ref,
                        compareItem,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.listTitle,
                    style: AppTypography.label.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.cardLineGap),
                  Text(
                    entry.listDetailLine,
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: AppSpacing.cardLineGap),
                    Text(
                      meta,
                      style: AppTypography.caption.copyWith(
                        color: mutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.cardPriceGap),
                  Row(
                    children: [
                      if (priceLabel != null)
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ).copyWith(color: textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: AppColors.bronze,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.entry, this.cover = false});

  final RecentlyViewedEntry entry;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final url = entry.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ColoredBox(
        color: AppColors.surface(context),
        child: AppNetworkImage(
          url: url,
          fit: cover ? BoxFit.cover : BoxFit.contain,
          memCacheWidth: cover ? 280 : 400,
          error: _buildFallback(context),
        ),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface(context),
      child: Center(
        child: CatalogMissingImage(
          padding: cover ? AppSpacing.s16 : AppSpacing.s24,
        ),
      ),
    );
  }
}

WishlistItem _wishlistItemFor(RecentlyViewedEntry entry) {
  final category = FavoriteProductType.toCategory(
    entry.productType == 'meleeDiamond'
        ? FavoriteProductType.diamond
        : entry.productType,
  );
  final productType = entry.productType.isNotEmpty
      ? entry.productType
      : FavoriteProductType.fromCategory(category);
  return WishlistItem(
    id: entry.productId,
    category: category,
    productType: productType,
    title: entry.displayTitle,
    subtitle: entry.detailLine ?? entry.metaLine ?? '',
    priceLabel: _formattedPrice(entry) ?? '',
    imageUrl: entry.imageUrl,
  );
}

CompareItem? _compareItemFor(RecentlyViewedEntry entry) {
  final category = switch (entry.productType) {
    'diamond' || 'meleeDiamond' => CompareCategory.diamond,
    'gemstone' => CompareCategory.gemstone,
    'watch' => CompareCategory.watch,
    _ => null,
  };
  if (category == null) return null;

  final price = double.tryParse(entry.price ?? '') ?? 0;
  final displayValues = <String, String>{
    if (_formattedPrice(entry) != null) 'price': _formattedPrice(entry)!,
    if (entry.carat != null) 'carat': '${entry.carat!.toStringAsFixed(2)}ct',
    if (entry.shape != null && entry.shape!.isNotEmpty) 'shape': entry.shape!,
    if (entry.color != null && entry.color!.isNotEmpty) 'color': entry.color!,
    if (entry.clarity != null && entry.clarity!.isNotEmpty)
      'clarity': entry.clarity!,
    if (entry.cut != null && entry.cut!.isNotEmpty) 'cut': entry.cut!,
  };
  return CompareItem(
    id: entry.productId,
    category: category,
    title: entry.displayTitle,
    price: price,
    imageUrl: entry.imageUrl,
    shape: entry.shape,
    displayValues: displayValues,
    numericValues: {
      'price': price,
      if (entry.carat != null) 'carat': entry.carat,
    },
  );
}

String? _formattedPrice(RecentlyViewedEntry entry) {
  final raw = entry.price;
  if (raw == null || raw.trim().isEmpty) return null;
  final value = double.tryParse(raw.replaceAll(RegExp(r'[^\d.]'), ''));
  if (value == null || value <= 0) return null;
  return AppCurrency.format(formatCatalogPrice(value));
}

Future<void> _openProduct(
  BuildContext context,
  WidgetRef ref,
  RecentlyViewedEntry entry,
) async {
  if (openRememberedProductDetail(context, entry.productId)) return;

  final detail = await CatalogProductDetailLoader.load(
    ref.read,
    productType: entry.productType,
    productId: entry.productId,
  );
  if (!context.mounted) return;
  if (detail == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open this product right now.'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }
  openProductDetail(context, detail);
}
