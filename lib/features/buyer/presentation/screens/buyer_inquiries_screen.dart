import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_create_action.dart';
import '../../../seller/application/inquiry_provider.dart';
import '../../../seller/domain/models/seller_inquiry.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../maison/maison_kit.dart';
import '../maison/maison_layout.dart';

enum _Reply {
  all('All'),
  awaiting('Awaiting'),
  replied('Replied');

  const _Reply(this.label);
  final String label;

  bool matches(SellerInquiry i) => switch (this) {
    _Reply.all => true,
    _Reply.awaiting => !i.hasAdminReply,
    _Reply.replied => i.hasAdminReply,
  };
}

IconData _categoryIcon(InquiryCategory c) => switch (c) {
  InquiryCategory.diamond => Icons.diamond_outlined,
  InquiryCategory.gemstone => Icons.auto_awesome_outlined,
  InquiryCategory.bullion => Icons.toll_outlined,
  InquiryCategory.watch => Icons.watch_outlined,
  InquiryCategory.jewelry => Icons.workspace_premium_outlined,
};

/// Buyer inquiries: requests sent to the Gemworld team, per category, with
/// reply status, search and a quick way to start a new one.
class BuyerInquiriesScreen extends ConsumerStatefulWidget {
  const BuyerInquiriesScreen({super.key});

  @override
  ConsumerState<BuyerInquiriesScreen> createState() =>
      _BuyerInquiriesScreenState();
}

class _BuyerInquiriesScreenState extends ConsumerState<BuyerInquiriesScreen> {
  final _search = TextEditingController();
  InquiryCategory _category = InquiryCategory.diamond;
  _Reply _reply = _Reply.all;
  bool _oldestFirst = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  InquiryListNotifier get _notifier =>
      ref.read(inquiryListProvider(_category).notifier);

  Future<void> _refresh() => _notifier.refresh();

  void _loadMore() => _notifier.loadMore();

  bool _onScroll(ScrollNotification n) {
    final s = ref.read(inquiryListProvider(_category));
    if (n.metrics.axis == Axis.vertical &&
        n.metrics.maxScrollExtent > 0 &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 320 &&
        s.hasMore &&
        !s.isLoadingMore) {
      _loadMore();
    }
    return false;
  }

  void _newInquiry() => context.openRoute(AppRouteNames.buyerInquiryNew);

  List<SellerInquiry> _view(List<SellerInquiry> items) {
    final q = _search.text.trim().toLowerCase();
    final out = [
      for (final i in items)
        if (_reply.matches(i) &&
            (q.isEmpty ||
                i.summary.toLowerCase().contains(q) ||
                i.id.toLowerCase().contains(q)))
          i,
    ];
    return _oldestFirst ? out.reversed.toList() : out;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(inquiryListProvider(_category));
    final items = state.items;
    final counts = {
      for (final r in _Reply.values) r: items.where(r.matches).length,
    };
    final visible = _view(items);
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);

    return MaisonLayout(
      child: TopBarCreateAction(
        create: TopBarCreate(
          label: 'Inquiry',
          tooltip: context.tr(AccountCommerceL10n.newInquiry),
          onPressed: _newInquiry,
        ),
        child: RefreshIndicator(
          color: p.gold,
          backgroundColor: p.surface,
          onRefresh: _refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                MaisonPinnedBar(
                  height: 178,
                  gutter: gutter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: InquiryCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final c = InquiryCategory.values[index];
                            return AtelierChoiceChip(
                              label: c.label,
                              icon: _categoryIcon(c),
                              selected: c == _category,
                              onTap: () => setState(() {
                                _category = c;
                                _reply = _Reply.all;
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      AtelierSegmented<_Reply>(
                        dense: true,
                        segments: [
                          for (final r in _Reply.values)
                            AtelierSegment(
                              value: r,
                              label: r.label,
                              count: counts[r],
                            ),
                        ],
                        selected: _reply,
                        onChanged: (r) => setState(() => _reply = r),
                      ),
                      const SizedBox(height: 8),
                      MaisonSearchRow(
                        controller: _search,
                        hint: 'Search your inquiries',
                        onChanged: (_) => setState(() {}),
                        sortLabel: _oldestFirst
                            ? 'Oldest first'
                            : 'Newest first',
                        sortActive: _oldestFirst,
                        onSort: () =>
                            setState(() => _oldestFirst = !_oldestFirst),
                      ),
                    ],
                  ),
                ),
                MaisonRefreshHairline(
                  visible: state.isLoading && items.isNotEmpty,
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 5, gutter, 20),
                  sliver: _body(context, state, visible),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    InquiryListState state,
    List<SellerInquiry> visible,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: MaisonCentered(
          child: AtelierSkeletonList(count: 3, height: 150),
        ),
      );
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierErrorState(
          title: 'Inquiries unavailable',
          message: state.errorMessage!,
          onRetry: _refresh,
        ),
      );
    }
    if (state.items.isEmpty) {
      return SliverToBoxAdapter(
        child: MaisonEmptyState(
          title: 'No ${_category.label.toLowerCase()} inquiries',
          message:
              'Ask for a stone, piece or price you cannot find and our team '
              'will get back to you.',
          actionLabel: context.tr(AccountCommerceL10n.newInquiry),
          actionIcon: Icons.add_rounded,
          onAction: _newInquiry,
        ),
      );
    }
    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: AtelierEmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No matches',
          message: 'No inquiries match your search.',
          actionLabel: 'Clear filters',
          onAction: () {
            _search.clear();
            setState(() => _reply = _Reply.all);
          },
        ),
      );
    }

    final rows = <Widget>[
      for (var i = 0; i < visible.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Reveal(
            key: ValueKey(visible[i].id),
            index: i < 8 ? i : 0,
            child: _InquiryCard(inquiry: visible[i]),
          ),
        ),
      MaisonListFooter(
        loadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        errorMessage: state.errorMessage,
        onLoadMore: _loadMore,
        endLabel: 'That’s every inquiry',
      ),
    ];
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => MaisonCentered(child: rows[index]),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry});

  final SellerInquiry inquiry;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final replied = inquiry.hasAdminReply;
    final tone = replied ? AtelierTone.emerald : AtelierTone.amber;
    final accent = p.tone(tone);

    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        side: BorderSide(
          color: replied ? p.hairline : accent.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        onTap: () => context.openRoute(
          '/buyer/inquiries/${inquiry.category.name}/${inquiry.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AtelierIconBadge(
                    icon: _categoryIcon(inquiry.category),
                    tone: AtelierTone.neutral,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${inquiry.category.label} inquiry'.toUpperCase(),
                          style: AtelierType.overline(p.muted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${maisonShortId(inquiry.id)} · ${inquiry.createdAtLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.figure(p.inkSoft, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  AtelierPill(
                    label: replied ? 'Replied' : 'Awaiting reply',
                    tone: tone,
                    icon: replied
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_top_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                inquiry.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.body(p.ink, size: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'View details',
                    style: AtelierType.title(p.gold, size: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: p.gold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
