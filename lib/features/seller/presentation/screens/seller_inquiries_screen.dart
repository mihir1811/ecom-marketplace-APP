import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/widgets/navigation/top_bar/top_bar_create_action.dart';
import '../../application/inquiry_provider.dart';
import '../../domain/models/seller_inquiry.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
import '../atelier/atelier_theme.dart';

enum _ReplyFilter { all, replied, awaiting }

IconData _iconFor(InquiryCategory c) => switch (c) {
  InquiryCategory.diamond => Icons.diamond_outlined,
  InquiryCategory.gemstone => Icons.auto_awesome_outlined,
  InquiryCategory.bullion => Icons.monetization_on_outlined,
  InquiryCategory.watch => Icons.watch_outlined,
  InquiryCategory.jewelry => Icons.workspace_premium_outlined,
};

AtelierTone _toneFor(InquiryCategory c) => switch (c) {
  InquiryCategory.diamond => AtelierTone.sapphire,
  InquiryCategory.gemstone => AtelierTone.emerald,
  InquiryCategory.bullion => AtelierTone.gold,
  InquiryCategory.watch => AtelierTone.neutral,
  InquiryCategory.jewelry => AtelierTone.amber,
};

/// Seller inquiries sent to the GemWorld admin desk, by product type.
class SellerInquiriesScreen extends ConsumerStatefulWidget {
  const SellerInquiriesScreen({super.key});

  @override
  ConsumerState<SellerInquiriesScreen> createState() =>
      _SellerInquiriesScreenState();
}

class _SellerInquiriesScreenState extends ConsumerState<SellerInquiriesScreen> {
  InquiryCategory _category = InquiryCategory.diamond;
  _ReplyFilter _reply = _ReplyFilter.all;

  void _openNew() => context.openRoute(AppRouteNames.sellerInquiryNew);

  void _openDetail(SellerInquiry inquiry) => context.openRoute(
    AppRouteNames.sellerInquiryDetailPath(inquiry.category.name, inquiry.id),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final listState = ref.watch(inquiryListProvider(_category));
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final replied = listState.items.where((i) => i.hasAdminReply).length;
    final items = [
      for (final i in listState.items)
        if (_reply == _ReplyFilter.all ||
            (_reply == _ReplyFilter.replied) == i.hasAdminReply)
          i,
    ];

    final children = <Widget>[
      Reveal(index: 1, child: AtelierSectionHeader(title: _category.listTitle)),
      const SizedBox(height: AtelierSpace.s12),
      Reveal(
        index: 2,
        child: AtelierSegmented<InquiryCategory>(
          segments: [
            for (final c in InquiryCategory.values)
              AtelierSegment(value: c, label: c.label, icon: _iconFor(c)),
          ],
          selected: _category,
          onChanged: (c) => setState(() {
            _category = c;
            _reply = _ReplyFilter.all;
          }),
        ),
      ),
      const SizedBox(height: AtelierSpace.s12),
      Reveal(
        index: 3,
        child: Row(
          children: [
            Expanded(
              child: AtelierSegmented<_ReplyFilter>(
                dense: true,
                segments: [
                  AtelierSegment(
                    value: _ReplyFilter.all,
                    label: context.tr(RemainingL10n.all),
                    count: listState.items.length,
                  ),
                  AtelierSegment(
                    value: _ReplyFilter.replied,
                    label: context.tr(RemainingL10n.adminReplied),
                    count: replied,
                  ),
                  AtelierSegment(
                    value: _ReplyFilter.awaiting,
                    label: context.tr(RemainingL10n.awaitingAdmin),
                    count: listState.items.length - replied,
                  ),
                ],
                selected: _reply,
                onChanged: (r) => setState(() => _reply = r),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AtelierSpace.s10),
      Text(
        listState.isLoading
            ? context.tr(RemainingL10n.loadingEllipsis)
            : listState.items.isEmpty
            ? context.tr(RemainingL10n.showingZeroOfZero)
            : context.tr(RemainingL10n.showingRangeOfTotal, {
                'from': '1',
                'to': '${listState.items.length}',
                'total': '${listState.total}',
              }),
        style: AtelierType.caption(p.muted, size: 11.5),
      ),
      const SizedBox(height: AtelierSpace.s12),
      if (listState.errorMessage != null && listState.items.isNotEmpty) ...[
        AtelierNotice(
          text: listState.errorMessage!,
          tone: AtelierTone.ruby,
          icon: Icons.error_outline_rounded,
          actionLabel: context.tr(RemainingL10n.retry),
          onAction: () =>
              ref.read(inquiryListProvider(_category).notifier).refresh(),
        ),
        const SizedBox(height: AtelierSpace.s12),
      ],
    ];

    Widget list;
    if (listState.isLoading && listState.items.isEmpty) {
      list = const AtelierSkeletonList(count: 3, height: 128);
    } else if (listState.errorMessage != null && listState.items.isEmpty) {
      list = AtelierErrorState(
        compact: true,
        title: 'Couldn’t load inquiries',
        message: listState.errorMessage!,
        onRetry: () =>
            ref.read(inquiryListProvider(_category).notifier).refresh(),
      );
    } else if (items.isEmpty) {
      list = AtelierEmptyState(
        compact: true,
        icon: _iconFor(_category),
        title: listState.items.isEmpty ? 'No inquiries yet' : 'Nothing here',
        message: listState.items.isEmpty
            ? context.tr(RemainingL10n.noCategoryInquiries, {
                'category': _category.label.toLowerCase(),
              })
            : 'No inquiries match this status.',
        actionLabel: listState.items.isEmpty
            ? context.tr(RemainingL10n.newInquiry)
            : null,
        onAction: listState.items.isEmpty ? _openNew : null,
      );
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Reveal(
                key: ValueKey('${_category.name}-${items[i].id}'),
                index: i < 8 ? i : 0,
                child: _InquiryCard(
                  inquiry: items[i],
                  onTap: () => _openDetail(items[i]),
                ),
              ),
            ),
          if (listState.hasMore)
            Center(
              child: AtelierButton(
                label: context.tr(RemainingL10n.loadMore),
                compact: true,
                variant: AtelierButtonVariant.secondary,
                loading: listState.isLoadingMore,
                onPressed: listState.isLoadingMore
                    ? null
                    : () => ref
                          .read(inquiryListProvider(_category).notifier)
                          .loadMore(),
              ),
            ),
        ],
      );
    }

    return TopBarCreateAction(
      create: TopBarCreate(
        label: 'Inquiry',
        tooltip: context.tr(RemainingL10n.newInquiry),
        onPressed: _openNew,
      ),
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: () =>
            ref.read(inquiryListProvider(_category).notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 6, gutter, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  AnimatedSwitcher(
                    duration: AtelierMotion.base,
                    child: KeyedSubtree(
                      key: ValueKey('${_category.name}-${_reply.name}'),
                      child: list,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry, required this.onTap});

  final SellerInquiry inquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final tone = _toneFor(inquiry.category);
    final replied = inquiry.hasAdminReply;
    final shortId = inquiry.id.length > 8
        ? inquiry.id.substring(0, 8)
        : inquiry.id;

    return AtelierCard(
      onTap: onTap,
      semanticLabel:
          '${inquiry.category.label} inquiry $shortId, ${inquiry.summary}',
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      borderColor: replied ? p.gold.withValues(alpha: 0.4) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AtelierIconBadge(icon: _iconFor(inquiry.category), tone: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#$shortId',
                      style: AtelierType.figure(p.muted, size: 11.5),
                    ),
                    const Spacer(),
                    Text(
                      inquiry.createdAtLabel,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  inquiry.buyerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.title(p.ink, size: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  inquiry.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.body(p.inkSoft, size: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AtelierPill(
                      label: replied
                          ? context.tr(RemainingL10n.adminReplied)
                          : context.tr(RemainingL10n.awaitingAdmin),
                      tone: replied ? AtelierTone.gold : AtelierTone.neutral,
                      icon: replied
                          ? Icons.mark_chat_read_outlined
                          : Icons.schedule_rounded,
                      dense: true,
                    ),
                    const Spacer(),
                    Text(
                      context.tr(RemainingL10n.viewDetails),
                      style: AtelierType.label(p.gold, size: 12),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: p.gold),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
