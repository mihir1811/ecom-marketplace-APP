import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/marketplace_product_card_shell.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/suggested_seller_products_provider.dart';
import '../../domain/models/product_detail.dart';
import '../../product_detail_navigation.dart';

/// Horizontally paginated "more from this seller" cards.
///
/// Place it without horizontal padding: [gutter] insets the heading and the
/// first card, while the strip runs to the trailing edge so the next card
/// peeks in and signals more to scroll.
class ProductDetailSuggestedProducts extends ConsumerStatefulWidget {
  const ProductDetailSuggestedProducts({
    required this.detail,
    super.key,
    this.gutter = 0,
    this.padding = EdgeInsets.zero,
  });

  final ProductDetail detail;

  /// Leading inset of the heading and the first card.
  final double gutter;

  /// Outer padding, applied only when the section is shown.
  final EdgeInsets padding;

  @override
  ConsumerState<ProductDetailSuggestedProducts> createState() =>
      _ProductDetailSuggestedProductsState();
}

class _ProductDetailSuggestedProductsState
    extends ConsumerState<ProductDetailSuggestedProducts> {
  final _scrollController = ScrollController();
  late final SuggestedSellerProductsQuery _query;

  /// The fractional card peeks in at the trailing edge.
  static const _visibleCards = 2.3;
  static const _maxCardWidth = 220.0;
  static const _cardGap = AppSpacing.s16;
  static const _imageAspect = 1.0;

  /// Title + 2 meta lines + price + card inset.
  static const _textBlockHeight = 118.0;

  @override
  void initState() {
    super.initState();
    _query = SuggestedSellerProductsQuery.fromDetail(widget.detail);
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
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 160) return;
    ref.read(suggestedSellerProductsProvider(_query).notifier).loadNextPage();
  }

  double _listHeightFor(double cardWidth) =>
      (cardWidth / _imageAspect) + _textBlockHeight;

  @override
  Widget build(BuildContext context) {
    if (!_query.canLoad) return const SizedBox.shrink();

    final state = ref.watch(suggestedSellerProductsProvider(_query));

    final gutter = widget.gutter;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            ((constraints.maxWidth - gutter - (_cardGap * 2)) / _visibleCards)
                .clamp(0.0, _maxCardWidth);
        final listHeight = _listHeightFor(cardWidth);

        Widget shell(Widget child) => _SuggestedSectionShell(
          padding: widget.padding,
          gutter: gutter,
          child: child,
        );

        if (state.isInitialLoading) {
          return shell(
            SizedBox(
              height: listHeight,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.bronze,
                  ),
                ),
              ),
            ),
          );
        }

        if (state.items.isEmpty) {
          if (state.errorMessage != null) {
            return shell(
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  AppSpacing.s16,
                  gutter,
                  AppSpacing.s16,
                ),
                child: Text(
                  state.errorMessage!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return shell(
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: gutter),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: _cardGap),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return SizedBox(
                    width: cardWidth * 0.45,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.bronze,
                        ),
                      ),
                    ),
                  );
                }

                final product = state.items[index];
                return SizedBox(
                  width: cardWidth,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _SuggestedProductCard(
                      key: ValueKey(product.id),
                      detail: product,
                      imageAspect: _imageAspect,
                      onTap: () => openProductDetail(context, product),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SuggestedSectionShell extends StatelessWidget {
  const _SuggestedSectionShell({
    required this.padding,
    required this.gutter,
    required this.child,
  });

  final EdgeInsets padding;
  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Text(
              context.tr(CatalogL10n.moreFromThisSeller),
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

class _SuggestedProductCard extends StatelessWidget {
  const _SuggestedProductCard({
    required this.detail,
    required this.onTap,
    required this.imageAspect,
    super.key,
  });

  final ProductDetail detail;
  final VoidCallback onTap;
  final double imageAspect;

  @override
  Widget build(BuildContext context) {
    final imageUrl = detail.media.firstNetworkUrl;
    final muted = AppColors.textSecondary(context);
    final primary = AppColors.textPrimary(context);
    final subtitle = detail.subtitle.trim();
    final reference = detail.referenceValue.trim();
    final badge = detail.badges.isEmpty ? null : detail.badges.first.label;
    final shapeName = (detail.shapeKey ?? detail.media.shapeKey)?.trim();

    return MarketplaceProductCardShell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: imageAspect,
            child: ColoredBox(
              color: AppColors.surface(context),
              child: imageUrl == null
                  ? Center(
                      child: shapeName != null && shapeName.isNotEmpty
                          ? renderShapeSvg(
                              shapeName,
                              size: 52,
                              color: AppColors.bronze,
                            )
                          : Icon(
                              detail.media.fallbackIcon,
                              color: detail.media.fallbackTint,
                              size: 40,
                            ),
                    )
                  : AppNetworkImage(
                      url: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 440,
                      error: Center(
                        child: shapeName != null && shapeName.isNotEmpty
                            ? renderShapeSvg(
                                shapeName,
                                size: 52,
                                color: AppColors.bronze,
                              )
                            : Icon(
                                detail.media.fallbackIcon,
                                color: detail.media.fallbackTint,
                                size: 40,
                              ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s16,
              AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
                if (reference.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${detail.referenceLabel}: $reference',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ] else if (badge != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s12),
                Text(
                  detail.price.display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
