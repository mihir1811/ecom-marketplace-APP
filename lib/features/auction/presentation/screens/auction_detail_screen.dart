import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_layout.dart';
import '../../../product_detail/domain/models/product_detail.dart';
import '../../../product_detail/presentation/widgets/luxe/luxe_detail_parts.dart';
import '../../../product_detail/presentation/widgets/product_detail_seller_panel.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../application/auction_providers.dart';
import '../../data/mappers/auction_product_detail.dart';
import '../../domain/models/auction_models.dart';
import '../widgets/auction_action_bar.dart';
import '../widgets/auction_bid_history.dart';
import '../widgets/auction_bid_panel.dart';

/// Auction lot on the shared luxe detail layout: gallery, what the lot is,
/// the live bid card with countdown, at-a-glance grades and certificate,
/// then bid history, specifications and seller. Bidding stays pinned.
class AuctionDetailScreen extends ConsumerStatefulWidget {
  const AuctionDetailScreen({required this.auctionId, super.key});

  final String auctionId;

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  bool _recordedView = false;

  @override
  Widget build(BuildContext context) {
    return LuxeScope(child: Builder(builder: _build));
  }

  Widget _build(BuildContext context) {
    final state = ref.watch(auctionDetailProvider(widget.auctionId));
    final notifier = ref.read(auctionDetailProvider(widget.auctionId).notifier);
    final auction = state.auction;
    if (auction == null && state.isLoading) return const _DetailSkeleton();
    if (auction == null) {
      return _Shell(
        child: LuxeStateView(
          icon: Icons.gavel_rounded,
          tone: LuxeTone.error,
          title: 'Auction unavailable',
          message: state.errorMessage ?? 'This auction could not be loaded.',
          actionLabel: context.tr(CatalogL10n.retry),
          onAction: notifier.refresh,
          secondaryLabel: MaterialLocalizations.of(context).backButtonTooltip,
          onSecondary: () => context.goBack(),
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

    return LuxeDetailLayout(
      title: detail.title,
      media: detail.media,
      availabilityStatus: detail.availabilityStatus,
      onRefresh: notifier.refresh,
      summary: _Summary(detail: detail, auction: auction),
      record: _Record(
        detail: detail,
        auction: auction,
        isSeller: auth.isSeller,
        errorMessage: state.errorMessage,
      ),
      bottomBar: auth.showProtected
          ? AuctionActionBar(auction: auction, auctionId: widget.auctionId)
          : null,
    );
  }
}

/// Lot identity, the live bid card, key grades and certificate.
class _Summary extends StatelessWidget {
  const _Summary({required this.detail, required this.auction});

  final ProductDetail detail;
  final AuctionListing auction;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget enter(Widget child, int i) => luxeEnter(context, child, i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(LuxeDetailEyebrow(detail: detail), 0),
        const SizedBox(height: 8),
        enter(Text(detail.title, style: LuxeType.display(34, p.ink)), 1),
        if (detail.subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          enter(
            Text(detail.subtitle, style: LuxeType.body(p.inkMuted, size: 15)),
            2,
          ),
        ],
        if (detail.badges.isNotEmpty) ...[
          const SizedBox(height: 14),
          enter(
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in detail.badges) LuxeDetailBadge(badge: b),
              ],
            ),
            3,
          ),
        ],
        const SizedBox(height: 20),
        enter(AuctionBidPanel(auction: auction), 4),
        const SizedBox(height: 26),
        if (detail.highlights.isNotEmpty) ...[
          enter(LuxeGlance(highlights: detail.highlights), 5),
          const SizedBox(height: 16),
        ],
        if (detail.certification != null &&
            !luxeIsMissing(detail.certification!.authority))
          enter(LuxeCertificateCard(cert: detail.certification!), 6),
      ],
    );
  }
}

/// Bid history, specifications and the seller.
class _Record extends StatelessWidget {
  const _Record({
    required this.detail,
    required this.auction,
    required this.isSeller,
    this.errorMessage,
  });

  final ProductDetail detail;
  final AuctionListing auction;
  final bool isSeller;
  final String? errorMessage;

  /// Spec sections as luxe tabs when the lot has no tabbed specs.
  ProductTabbedSpecs? _specs() {
    final tabbed = detail.naturalSpecTabs;
    if (tabbed != null) return tabbed;
    final sections = detail.specsForViewer(isSeller: isSeller);
    if (sections.isEmpty) return null;
    return ProductTabbedSpecs(
      tabs: [
        for (final s in sections)
          if (s.specs.isNotEmpty)
            ProductSpecTab(title: s.group.title, rows: s.specs),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final specs = _specs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.caution.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              border: Border.all(color: p.caution.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: p.caution),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: LuxeType.body(p.caution, size: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        AuctionBidHistory(auction: auction),
        if (specs != null && specs.tabs.isNotEmpty) ...[
          const SizedBox(height: 32),
          LuxeSpecTabs(specs: specs),
        ],
        if (detail.listingSeller != null) ...[
          const SizedBox(height: 28),
          ProductDetailSellerPanel(
            seller: detail.listingSeller!,
            showContactDetails: true,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Plain luxe frame for loading / error states (no gallery yet).
class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: LuxePalette.of(context).canvas,
      appBar: const LuxeTopBar(eyebrow: 'Auction house', title: 'Auction'),
      body: child,
    );
  }
}

/// Shimmering stand-in for the gallery, title and bid card.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return _Shell(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          LuxeSkeleton(
            height: (width - 40).clamp(0.0, 520.0),
            radius: LuxeSpace.radius,
          ),
          const SizedBox(height: 22),
          const LuxeSkeleton(width: 120, height: 11),
          const SizedBox(height: 12),
          LuxeSkeleton(width: width * 0.7, height: 28),
          const SizedBox(height: 10),
          LuxeSkeleton(width: width * 0.5, height: 14),
          const SizedBox(height: 22),
          const LuxeSkeleton(height: 190, radius: LuxeSpace.radius),
        ],
      ),
    );
  }
}
