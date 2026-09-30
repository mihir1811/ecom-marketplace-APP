import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/catalog_empty_state.dart';
import '../../../product_detail/presentation/widgets/product_detail_header.dart';
import '../../../product_detail/presentation/widgets/product_detail_media.dart';
import '../../../product_detail/presentation/widgets/product_detail_natural_specs.dart';
import '../../../product_detail/presentation/widgets/product_detail_price.dart';
import '../../../product_detail/presentation/widgets/product_detail_seller_panel.dart';
import '../../../product_detail/presentation/widgets/product_detail_specs.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../application/auction_providers.dart';
import '../../data/mappers/auction_product_detail.dart';
import '../widgets/auction_action_bar.dart';
import '../widgets/auction_bid_history.dart';
import '../widgets/auction_bid_panel.dart';

/// Auction page laid out like [ProductDetailScreen].
class AuctionDetailScreen extends ConsumerStatefulWidget {
  const AuctionDetailScreen({required this.auctionId, super.key});

  final String auctionId;

  static const double _wideBreakpoint = 900;
  static const double _maxContentWidth = 1120;

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  bool _recordedView = false;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionDetailProvider(widget.auctionId));
    final auction = state.auction;
    if (auction == null && state.isLoading) {
      return const AppScaffold(
        appBar: AppTopBar(title: 'Auction'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auction == null) {
      return AppScaffold(
        appBar: const AppTopBar(title: 'Auction'),
        body: CatalogEmptyState(
          title: 'Auction unavailable',
          message: state.errorMessage ?? 'This auction could not be loaded.',
          icon: Icons.gavel_outlined,
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(auctionDetailProvider(widget.auctionId).notifier).refresh(),
        ),
      );
    }

    final detail = auctionProductDetail(auction);
    final auth = ref.watch(
      authProvider.select(
        (s) => (
          signedIn: s.isAuthenticated,
          isSeller: s.isSeller,
          showProtected: !s.isVerificationPending,
        ),
      ),
    );
    if (auth.signedIn && !_recordedView) {
      _recordedView = true;
      final productId = detail.id;
      final productType = detail.apiProductType;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        recordRecentlyViewed(
          ref,
          productId: productId,
          productType: productType,
        );
      });
    }
    final visibleSpecs = detail.specsForViewer(isSeller: auth.isSeller);

    return AppScaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppTopBar(title: detail.segment.label),
      bottomNavigationBar: auth.showProtected
          ? AuctionActionBar(auction: auction, auctionId: widget.auctionId)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth >= AuctionDetailScreen._wideBreakpoint;
          final summary = <Widget>[
            ProductDetailHeader(detail: detail, showWishlist: false),
            const SizedBox(height: AppSpacing.s16),
            AuctionBidPanel(auction: auction),
            const SizedBox(height: AppSpacing.s24),
            ProductDetailPrice(
              detail: detail,
              amountOverride: auction.highestBidAmount,
              showCatalogDiscount: false,
              showWishlist: false,
            ),
            if (detail.listingSeller != null) ...[
              const SizedBox(height: AppSpacing.s24),
              ProductDetailSellerPanel(
                seller: detail.listingSeller!,
                showContactDetails: true,
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                state.errorMessage!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.terracotta,
                ),
              ),
            ],
          ];

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AuctionDetailScreen._maxContentWidth,
              ),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s40,
                ),
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: ProductDetailMedia(
                            media: detail.media,
                            availabilityStatus: detail.availabilityStatus,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s40),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: summary,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ProductDetailMedia(
                      media: detail.media,
                      availabilityStatus: detail.availabilityStatus,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    ...summary,
                  ],
                  const SizedBox(height: AppSpacing.s40),
                  AuctionBidHistory(auction: auction),
                  const SizedBox(height: AppSpacing.s40),
                  if (detail.naturalSpecTabs != null)
                    ProductDetailNaturalSpecs(
                      specs: detail.naturalSpecTabs!,
                      productId: detail.id,
                      lotPrice: detail.price.displayAmount,
                      currencySymbol: detail.price.currencySymbol,
                    )
                  else
                    for (final section in visibleSpecs) ...[
                      ProductDetailSpecSection(section: section),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
