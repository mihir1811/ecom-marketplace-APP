import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../../../core/widgets/gem3d/gem_view.dart';
import '../../../../auction/application/auction_providers.dart';
import '../../../../auction/domain/models/auction_models.dart';
import '../../../../notifications/application/notifications_provider.dart';
import '../../../../refunds/application/refund_providers.dart';
import '../../../../refunds/domain/models/refund_request.dart';
import '../../../application/seller_orders_provider.dart';
import '../../atelier/atelier_components.dart';
import '../../atelier/atelier_motion.dart';
import '../../atelier/atelier_theme.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Onyx hero: greeting, headline value and a live 3D stone.
class DashboardHero extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.atelier;
    final name = ref.watch(
      authProvider.select((s) => s.user?.fullName.trim() ?? ''),
    );
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final date =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    final onOnyxSoft = p.onOnyx.withValues(alpha: 0.62);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final gemSize = wide ? 170.0 : 112.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AtelierRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF14120E),
              border: Border.all(
                color: p.isDark ? p.hairline : Colors.transparent,
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: AtelierAmbient(intensity: 1.4)),
                // Fine gold rule across the top.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 1.2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          p.gold.withValues(alpha: 0),
                          p.gold.withValues(alpha: 0.8),
                          p.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: wide ? 28 : 6,
                  top: wide ? 22 : 10,
                  child: Reveal(
                    delay: const Duration(milliseconds: 200),
                    child: GemView(
                      cut: GemCut.round,
                      look: GemLook.white,
                      size: gemSize,
                      spin: 0.35,
                      tilt: 0.32,
                      interactive: true,
                      semanticLabel: 'Rotating diamond. Drag to turn it.',
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 22,
                    wide ? 30 : 22,
                    wide ? 32 : 22,
                    wide ? 30 : 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Reveal(
                        child: Text(
                          date.toUpperCase(),
                          style: AtelierType.overline(p.gold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Reveal(
                        index: 1,
                        child: Padding(
                          padding: EdgeInsets.only(right: gemSize * 0.75),
                          child: Text(
                            first.isEmpty ? greeting : '$greeting,\n$first',
                            style: AtelierType.display(
                              p.onOnyx,
                              size: wide ? 44 : 32,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Reveal(
                        index: 2,
                        child: Padding(
                          padding: EdgeInsets.only(right: gemSize * 0.6),
                          child: Text(
                            context.tr(
                              RemainingL10n.welcomeBackHereSWhatSHappening,
                            ),
                            style: AtelierType.body(onOnyxSoft, size: 13.5),
                          ),
                        ),
                      ),
                      if (headlineValue != null) ...[
                        SizedBox(height: wide ? 28 : 22),
                        Reveal(
                          index: 3,
                          child: Container(
                            height: 1,
                            color: p.onOnyx.withValues(alpha: 0.1),
                          ),
                        ),
                        SizedBox(height: wide ? 20 : 16),
                        Reveal(
                          index: 4,
                          child: Text(
                            (headlineLabel ?? '').toUpperCase(),
                            style: AtelierType.overline(onOnyxSoft),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Reveal(
                          index: 5,
                          child: CountUpText(
                            headlineValue!,
                            duration: const Duration(milliseconds: 1600),
                            style: AtelierType.display(
                              p.onOnyx,
                              size: wide ? 54 : 42,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (headlineCaption != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            headlineCaption!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.caption(onOnyxSoft),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for the hero while the first snapshot loads.
class DashboardHeroSkeleton extends StatelessWidget {
  const DashboardHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      height: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.xl),
        border: Border.all(color: p.hairline),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 120, height: 10),
          SizedBox(height: 16),
          SkeletonBox(width: 220, height: 30),
          SizedBox(height: 12),
          SkeletonBox(width: 260, height: 12),
          Spacer(),
          SkeletonBox(width: 90, height: 10),
          SizedBox(height: 10),
          SkeletonBox(width: 200, height: 40),
        ],
      ),
    );
  }
}

/// "Needs your attention": the counts a seller should act on today.
class DashboardAttentionStrip extends ConsumerWidget {
  const DashboardAttentionStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onTap: () => context.switchToRoute(AppRouteNames.sellerAuctions),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          const gap = AtelierSpace.s12;
          final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < items.length; i++)
                SizedBox(
                  width: w,
                  child: Reveal(
                    index: i,
                    child: _AttentionTile(data: items[i]),
                  ),
                ),
            ],
          );
        }
        return SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AtelierSpace.s12),
            itemBuilder: (context, i) => SizedBox(
              width: 172,
              child: Reveal(
                index: i,
                horizontal: true,
                child: _AttentionTile(data: items[i]),
              ),
            ),
          ),
        );
      },
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

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.data});

  final _AttentionData data;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final count = data.count ?? 0;
    final clear = !data.loading && !data.error && count == 0;
    final tone = clear ? AtelierTone.emerald : data.tone;
    final accent = p.tone(tone);

    return AtelierCard(
      onTap: data.error ? data.onRetry : data.onTap,
      semanticLabel: data.error
          ? '${data.label}: could not load. Tap to retry.'
          : '${data.label}: $count',
      padding: const EdgeInsets.all(AtelierSpace.s16),
      borderColor: !clear && count > 0 ? accent.withValues(alpha: 0.35) : null,
      child: SizedBox(
        height: 98,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  clear ? Icons.check_circle_outline_rounded : data.icon,
                  size: 18,
                  color: accent,
                ),
                const Spacer(),
                Icon(
                  data.error
                      ? Icons.refresh_rounded
                      : Icons.arrow_outward_rounded,
                  size: 16,
                  color: p.muted,
                ),
              ],
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: AtelierMotion.base,
              child: data.loading
                  ? const SkeletonBox(width: 40, height: 28)
                  : data.error
                  ? Text('Retry', style: AtelierType.display(p.ruby, size: 26))
                  : clear
                  ? Text(
                      'All clear',
                      key: const ValueKey('clear'),
                      style: AtelierType.display(p.emerald, size: 26),
                    )
                  : CountUpText(
                      '$count',
                      key: ValueKey(count),
                      style: AtelierType.display(p.ink, size: 32),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AtelierType.caption(p.muted, size: 11.5),
            ),
          ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtelierSectionHeader(
            overline: 'Auctions',
            title: 'Auction outcomes',
            trailing: AtelierButton(
              label: context.tr(RemainingL10n.myAuctions),
              compact: true,
              variant: AtelierButtonVariant.secondary,
              onPressed: () =>
                  context.switchToRoute(AppRouteNames.sellerAuctions),
            ),
          ),
          const SizedBox(height: AtelierSpace.s20),
          standing.when(
            loading: () => const Row(
              children: [
                Expanded(child: SkeletonBox(height: 52)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 52)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 52)),
              ],
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

class _OutcomeGrid extends StatelessWidget {
  const _OutcomeGrid({required this.value});

  final SellerAuctionStanding value;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, int, AtelierTone)>[
      ('Live', value.active, AtelierTone.emerald),
      ('Upcoming', value.upcoming, AtelierTone.sapphire),
      ('Needs decision', value.needsDecision, AtelierTone.ruby),
      ('Ended', value.ended, AtelierTone.neutral),
      ('Sold', value.sold, AtelierTone.gold),
      ('Bids', value.bids, AtelierTone.amber),
      ('Total', value.total, AtelierTone.neutral),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 3;
        final w = constraints.maxWidth / columns;
        return Wrap(
          runSpacing: AtelierSpace.s16,
          children: [
            for (var i = 0; i < stats.length; i++)
              SizedBox(
                width: w,
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
      },
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
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CountUpText('$count', style: AtelierType.display(p.ink, size: 28)),
      ],
    );
  }
}
