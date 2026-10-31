import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../auction/application/auction_providers.dart';
import '../../../../auction/domain/models/auction_models.dart';
import '../../../../notifications/application/notifications_provider.dart';
import '../../../../refunds/application/refund_providers.dart';
import '../../../../refunds/domain/models/refund_request.dart';
import '../../../application/seller_orders_provider.dart';
import '../../atelier/atelier_components.dart';
import '../../atelier/atelier_motion.dart';
import '../../atelier/atelier_theme.dart';

/// Headline figure (e.g. total sales) as one plain card.
class DashboardHero extends StatelessWidget {
  const DashboardHero({
    required this.headlineLabel,
    required this.headlineValue,
    required this.headlineCaption,
    super.key,
  });

  final String? headlineLabel;
  final String? headlineValue;
  final String? headlineCaption;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final value = headlineValue;
    if (value == null) return const SizedBox.shrink();
    return Reveal(
      child: AtelierCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (headlineLabel ?? '').toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
            const SizedBox(height: 4),
            CountUpText(
              value,
              duration: const Duration(milliseconds: 1200),
              style: AtelierType.display(
                p.ink,
                size: 32,
                weight: FontWeight.w500,
              ),
            ),
            if (headlineCaption != null) ...[
              const SizedBox(height: 2),
              Text(
                headlineCaption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the hero while the first snapshot loads.
class DashboardHeroSkeleton extends StatelessWidget {
  const DashboardHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(height: 96, radius: AtelierRadius.lg);
  }
}

/// What a seller should act on today, as one card: "All caught up" when
/// nothing is pending, otherwise just the items that need attention.
class DashboardAttentionStrip extends ConsumerWidget {
  const DashboardAttentionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final pendingOrders = ref.watch(sellerPendingOrdersProvider);
    final refunds = ref.watch(sellerRefundListProvider);
    final standing = ref.watch(sellerAuctionStandingProvider);
    final unread = ref.watch(notificationUnreadCountProvider);

    final openRefunds = refunds.items
        .where((r) => r.status == RefundStatus.pending)
        .length;

    final items = <_AttentionData>[
      _AttentionData(
        icon: Icons.hourglass_top_rounded,
        label: 'Orders awaiting approval',
        count: pendingOrders.asData?.value.total,
        loading: pendingOrders.isLoading && !pendingOrders.hasValue,
        error: pendingOrders.hasError && !pendingOrders.hasValue,
        onRetry: () => ref.invalidate(sellerPendingOrdersProvider),
        onTap: () => context.openRoute(AppRouteNames.sellerOrders),
        tone: AtelierTone.gold,
      ),
      _AttentionData(
        icon: Icons.replay_rounded,
        label: 'Refund requests',
        count: refunds.isLoading && refunds.items.isEmpty ? null : openRefunds,
        loading: refunds.isLoading && refunds.items.isEmpty,
        error: refunds.errorMessage != null && refunds.items.isEmpty,
        onRetry: () => ref.read(sellerRefundListProvider.notifier).refresh(),
        onTap: () => context.openRoute(AppRouteNames.sellerOrders),
        tone: AtelierTone.ruby,
      ),
      _AttentionData(
        icon: Icons.gavel_rounded,
        label: 'Auctions need a decision',
        count: standing.asData?.value.needsDecision,
        loading: standing.isLoading && !standing.hasValue,
        error: standing.hasError && !standing.hasValue,
        onRetry: () => ref.invalidate(sellerAuctionStandingProvider),
        onTap: () => context.switchToRoute(
          (standing.asData?.value.needsDecision ?? 0) > 0
              ? '${AppRouteNames.sellerAuctions}?tab=decision'
              : AppRouteNames.sellerAuctions,
        ),
        tone: AtelierTone.sapphire,
      ),
      _AttentionData(
        icon: Icons.notifications_none_rounded,
        label: 'Unread notifications',
        count: unread,
        onTap: () => context.switchToRoute(AppRouteNames.sellerNotifications),
        tone: AtelierTone.amber,
      ),
    ];

    final loading = items.any((d) => d.loading);
    final needs = [
      for (final d in items)
        if (d.error || (!d.loading && (d.count ?? 0) > 0)) d,
    ];

    if (needs.isEmpty && loading) {
      return const SkeletonBox(height: 56, radius: AtelierRadius.lg);
    }

    if (needs.isEmpty) {
      return Reveal(
        child: AtelierCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: p.emerald,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All caught up',
                  style: AtelierType.title(p.ink, size: 15),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Reveal(
      child: AtelierCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < needs.length; i++) ...[
              if (i > 0) Container(height: 1, color: p.hairline),
              _AttentionRow(data: needs[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttentionData {
  const _AttentionData({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    required this.tone,
    this.loading = false,
    this.error = false,
    this.onRetry,
  });

  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;
  final AtelierTone tone;
  final bool loading;
  final bool error;
  final VoidCallback? onRetry;
}

/// One item that needs the seller: icon, label, count, open arrow.
class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.data});

  final _AttentionData data;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accent = data.error ? p.ruby : p.tone(data.tone);
    return Semantics(
      button: true,
      label: data.error
          ? '${data.label}: could not load. Tap to retry.'
          : '${data.label}: ${data.count ?? 0}',
      excludeSemantics: true,
      child: InkWell(
        onTap: data.error ? data.onRetry : data.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink, size: 13.5),
                ),
              ),
              Text(
                data.error ? 'Retry' : '${data.count ?? 0}',
                style: AtelierType.title(accent, size: 15),
              ),
              const SizedBox(width: 6),
              Icon(
                data.error
                    ? Icons.refresh_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: p.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-tap shortcuts to the tools sellers reach for most.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.add_comment_outlined,
        context.tr(RemainingL10n.newInquiry),
        () => context.openRoute(AppRouteNames.sellerInquiryNew),
      ),
      (
        Icons.gavel_outlined,
        context.tr(RemainingL10n.auctions),
        () => context.switchToRoute(AppRouteNames.sellerAuctions),
      ),
      (
        Icons.local_offer_outlined,
        context.tr(RemainingL10n.offers),
        () => context.switchToRoute(AppRouteNames.sellerOffers),
      ),
      (
        Icons.insights_outlined,
        context.tr(RemainingL10n.analytics),
        () => context.switchToRoute(AppRouteNames.sellerAnalytics),
      ),
      (
        Icons.campaign_outlined,
        context.tr(RemainingL10n.promotions),
        () => context.switchToRoute(AppRouteNames.sellerPromotions),
      ),
      (
        Icons.chat_bubble_outline_rounded,
        context.tr(RemainingL10n.chat),
        () => context.switchToRoute(AppRouteNames.sellerChat),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        const gap = AtelierSpace.s10;
        final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < actions.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  index: i,
                  child: _QuickAction(
                    icon: actions[i].$1,
                    label: actions[i].$2,
                    onTap: actions[i].$3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierCard(
      onTap: onTap,
      semanticLabel: label,
      elevated: false,
      radius: AtelierRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: p.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.label(p.ink, size: 13),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: p.muted),
        ],
      ),
    );
  }
}

/// Auction outcomes at a glance; any figure opens My Auctions.
class DashboardAuctionOutcomes extends ConsumerWidget {
  const DashboardAuctionOutcomes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final standing = ref.watch(sellerAuctionStandingProvider);
    return AtelierCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Auction outcomes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.title(p.ink, size: 16),
                ),
              ),
              AtelierButton(
                label: context.tr(RemainingL10n.myAuctions),
                compact: true,
                variant: AtelierButtonVariant.ghost,
                onPressed: () =>
                    context.switchToRoute(AppRouteNames.sellerAuctions),
              ),
            ],
          ),
          const SizedBox(height: AtelierSpace.s8),
          standing.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SkeletonBox(height: 40),
            ),
            error: (error, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    error is Failure
                        ? error.message
                        : 'Could not load auctions.',
                    style: AtelierType.caption(p.ruby),
                  ),
                ),
                AtelierButton(
                  label: 'Retry',
                  compact: true,
                  variant: AtelierButtonVariant.ghost,
                  icon: Icons.refresh_rounded,
                  onPressed: () =>
                      ref.invalidate(sellerAuctionStandingProvider),
                ),
              ],
            ),
            data: (value) => _OutcomeGrid(value: value),
          ),
        ],
      ),
    );
  }
}

/// One row of the four figures a seller checks: what is running, what is
/// queued, what sold and how much bidding there is. "Needs decision" already
/// sits in the attention strip; ended/total add little at a glance.
class _OutcomeGrid extends StatelessWidget {
  const _OutcomeGrid({required this.value});

  final SellerAuctionStanding value;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, int, AtelierTone)>[
      ('Live', value.active, AtelierTone.emerald),
      ('Upcoming', value.upcoming, AtelierTone.sapphire),
      ('Sold', value.sold, AtelierTone.gold),
      ('Bids', value.bids, AtelierTone.amber),
    ];
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++)
          Expanded(
            child: Reveal(
              index: i,
              child: Pressable(
                onTap: () =>
                    context.switchToRoute(AppRouteNames.sellerAuctions),
                semanticLabel: '${stats[i].$1}: ${stats[i].$2}',
                child: _Outcome(
                  label: stats[i].$1,
                  count: stats[i].$2,
                  tone: stats[i].$3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final AtelierTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: p.tone(tone),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        CountUpText('$count', style: AtelierType.display(p.ink, size: 21)),
      ],
    );
  }
}
