import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auction/application/auction_providers.dart';
import '../../../notifications/application/notifications_provider.dart';
import '../../../refunds/application/refund_providers.dart';
import '../../application/seller_insights_provider.dart';
import '../../application/seller_orders_provider.dart';
import '../../domain/models/seller_insights.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';
import '../widgets/dashboard/dashboard_performance.dart';
import '../widgets/dashboard/dashboard_sections.dart';
import '../widgets/seller_dashboard_diamond_projects_section.dart';

/// Seller dashboard: today's priorities first, then performance, then tools.
class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  DashboardMetric _metric = DashboardMetric.totalSales;

  // The provider owns the selected range, so the selector and the chart can
  // never disagree (e.g. after this screen is rebuilt).
  Future<void> _applyRange(SalesRange range, {DateTime? start, DateTime? end}) {
    return ref
        .read(sellerDashboardProvider.notifier)
        .setParams(
          SellerDashboardParams(
            range: range,
            customStart: start,
            customEnd: end,
          ),
        );
  }

  Future<void> _onRangeSelected(SalesRange range) async {
    if (range == SalesRange.custom) {
      await _editCustomRange();
      return;
    }
    await _applyRange(range);
  }

  Future<void> _editCustomRange() async {
    final current = ref.read(sellerDashboardProvider).params;
    final picked = await pickDashboardCustomRange(
      context,
      initialStart: current.customStart,
      initialEnd: current.customEnd,
    );
    if (picked == null) return;
    await _applyRange(SalesRange.custom, start: picked.$1, end: picked.$2);
  }

  Future<void> _refresh() async {
    ref.invalidate(sellerAuctionStandingProvider);
    ref.invalidate(sellerPendingOrdersProvider);
    ref.read(notificationUnreadCountProvider.notifier).refresh();
    ref.read(sellerRefundListProvider.notifier).refresh();
    await ref.read(sellerDashboardProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(sellerDashboardProvider);
    final snapshot = state.snapshot;
    final params = state.params;
    // A failed range switch must not leave the previous range's bars under
    // the newly selected range.
    final chartIsStale = snapshot != null && snapshot.params != params;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = AtelierSpace.gutter(constraints.maxWidth);
        final wide = constraints.maxWidth >= 1100;

        Widget content;
        if (state.errorMessage != null && snapshot == null) {
          content = AtelierErrorState(
            title: 'Your dashboard is unavailable',
            message: state.errorMessage!,
            onRetry: () => ref.read(sellerDashboardProvider.notifier).refresh(),
          );
        } else if (snapshot == null) {
          content = const _DashboardSkeleton();
        } else {
          final sales = snapshot.metrics
              .where((m) => m.metric == DashboardMetric.totalSales)
              .firstOrNull;

          final performance = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardMetricGrid(
                metrics: snapshot.metrics,
                selected: _metric,
                onSelected: (m) => setState(() => _metric = m),
              ),
              const SizedBox(height: AtelierSpace.s16),
              Reveal(
                index: 2,
                child: DashboardPerformanceCard(
                  metric: _metric,
                  snapshot: snapshot,
                  params: params,
                  isRefreshing: state.isRefreshing,
                  isStale: chartIsStale,
                  errorMessage: state.errorMessage,
                  onRangeSelected: _onRangeSelected,
                  onEditCustomRange: _editCustomRange,
                  onRetry: () =>
                      ref.read(sellerDashboardProvider.notifier).refresh(),
                ),
              ),
            ],
          );

          const tools = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(text: 'Shortcuts'),
              SizedBox(height: AtelierSpace.s12),
              DashboardQuickActions(),
              SizedBox(height: AtelierSpace.s24),
              Reveal(child: DashboardAuctionOutcomes()),
            ],
          );

          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHero(
                headlineLabel: sales?.title,
                headlineValue: sales?.value,
                headlineCaption: sales?.subtitle,
              ),
              const SizedBox(height: AtelierSpace.s16),
              const DashboardAttentionStrip(),
              const SizedBox(height: AtelierSpace.s32),
              const _SectionLabel(text: 'At a glance'),
              const SizedBox(height: AtelierSpace.s12),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: performance),
                    const SizedBox(width: AtelierSpace.s24),
                    const Expanded(flex: 2, child: tools),
                  ],
                )
              else ...[
                performance,
                const SizedBox(height: AtelierSpace.s32),
                tools,
              ],
              const SizedBox(height: AtelierSpace.s32),
              const Reveal(child: SellerDashboardDiamondProjectsSection()),
            ],
          );
        }

        return RefreshIndicator(
          color: p.gold,
          backgroundColor: p.surface,
          onRefresh: _refresh,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        Text(text.toUpperCase(), style: AtelierType.overline(p.muted)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: p.hairline)),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const gap = AtelierSpace.s12;
        final w = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DashboardHeroSkeleton(),
            const SizedBox(height: AtelierSpace.s32),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < 4; i++)
                  SizedBox(
                    width: w,
                    child: const AtelierCard(
                      child: SizedBox(
                        height: 106,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 32, height: 32, radius: 16),
                            Spacer(),
                            SkeletonBox(width: 80, height: 10),
                            SizedBox(height: 8),
                            SkeletonBox(width: 110, height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AtelierSpace.s16),
            const AtelierCard(child: SkeletonBox(height: 260)),
          ],
        );
      },
    );
  }
}
