import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../chat/domain/models/chat_product_type.dart';
import '../../../chat/domain/models/chat_thread.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/interested_buyers_providers.dart';
import '../../domain/models/interested_buyer.dart';
import '../widgets/interested_buyer_card.dart';
import '../widgets/interested_contact_sheets.dart';

/// Buyers who have had this seller's item in their cart for an hour or
/// more. The seller gets one message or one private offer per buyer and
/// item every 7 days, sooner once the buyer replies.
class SellerInterestedBuyersScreen extends ConsumerStatefulWidget {
  const SellerInterestedBuyersScreen({super.key});

  @override
  ConsumerState<SellerInterestedBuyersScreen> createState() =>
      _SellerInterestedBuyersScreenState();
}

class _SellerInterestedBuyersScreenState
    extends ConsumerState<SellerInterestedBuyersScreen>
    with WidgetsBindingObserver {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// The 1-hour delay and 7-day limit run on the server.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  InterestedBuyersNotifier get _list =>
      ref.read(interestedBuyersProvider.notifier);

  Future<void> _refresh() => _list.refresh();

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _list.setSearch(value),
    );
  }

  /// Shown after a failed action: a 404 drops the row; every failure
  /// reloads, because the row has changed.
  void _afterFailure(InterestedBuyer row, Failure failure) {
    AppHaptics.error();
    if (failure is NotFoundFailure) _list.drop(row.id);
    showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    _refresh();
  }

  Future<void> _message(InterestedBuyer row) async {
    final outcome = await showInterestedMessageSheet(context, row: row);
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case ContactSent():
        AppHaptics.success();
        showAtelierToast(context, 'Message sent.', tone: AtelierTone.emerald);
        _refresh();
      case ContactFailed(:final failure):
        _afterFailure(row, failure);
    }
  }

  Future<void> _offer(InterestedBuyer row) async {
    final outcome = await showInterestedOfferSheet(context, row: row);
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case ContactSent():
        AppHaptics.success();
        showAtelierToast(
          context,
          'Private offer sent. The buyer has 24 hours to answer.',
          tone: AtelierTone.emerald,
        );
        _refresh();
      case ContactFailed(:final failure):
        _afterFailure(row, failure);
    }
  }

  void _openChat(InterestedBuyer row) {
    final type = ChatProductType.fromApi(row.product.type);
    final buyerId = row.chatBuyerId;
    if (type == null || buyerId == null || row.product.id.isEmpty) {
      context.openRoute(AppRouteNames.sellerChat);
      return;
    }
    context.openRoute(
      AppRouteNames.sellerChatDetailPath(
        ChatThread.encodeId(
          productType: type,
          productId: row.product.id,
          peerUserId: buyerId,
        ),
      ),
    );
  }

  void _openOffers() =>
      context.switchToRoute('${AppRouteNames.sellerOffers}?status=PENDING');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interestedBuyersProvider);
    final summary = state.summary;

    return AtelierPage(
      onRefresh: _refresh,
      onNearEnd: _list.loadMore,
      children: [
        AtelierHero(
          title: context.tr(InterestedBuyersL10n.menu),
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Buyers',
                value: summary == null ? '—' : '${summary.buyers}',
                caption: 'With your items in cart',
              ),
              AtelierHeroStat(
                label: 'Items',
                value: summary == null ? '—' : '${summary.items}',
                caption: 'Cart lines you can see',
              ),
              AtelierHeroStat(
                label: 'Not contacted',
                value: summary == null ? '—' : '${summary.notContacted}',
                tone: (summary?.notContacted ?? 0) > 0
                    ? AtelierTone.amber
                    : null,
              ),
              AtelierHeroStat(
                label: 'Cart value',
                value: summary == null
                    ? '—'
                    : atelierMoney(summary.totalValue),
              ),
            ],
          ),
        ),
        const SizedBox(height: AtelierSpace.s16),
        Reveal(
          index: 2,
          child: AtelierSegmented<InterestedBuyersTab>(
            expand: true,
            segments: [
              for (final t in InterestedBuyersTab.values)
                AtelierSegment(
                  value: t,
                  label: t.label,
                  count: t == InterestedBuyersTab.fresh
                      ? summary?.notContacted
                      : null,
                ),
            ],
            selected: state.tab,
            onChanged: _list.setTab,
          ),
        ),
        const SizedBox(height: AtelierSpace.s12),
        Reveal(
          index: 3,
          child: AtelierSearchField(
            controller: _search,
            hint: 'Search buyer, item or stock no.',
            onChanged: _onSearch,
          ),
        ),
        const SizedBox(height: AtelierSpace.s12),
        const AtelierNotice(
          text:
              'Buyers show here 1 hour after adding your item. You can send '
              'each buyer one message or one private offer per item every 7 '
              'days, or again as soon as they reply. You see their name only.',
          icon: Icons.info_outline_rounded,
          dense: true,
        ),
        if (state.errorMessage != null && state.items.isNotEmpty) ...[
          const SizedBox(height: AtelierSpace.s12),
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
        ],
        const SizedBox(height: AtelierSpace.s12),
        AnimatedSwitcher(
          duration: AtelierMotion.base,
          switchInCurve: AtelierMotion.emphasized,
          child: KeyedSubtree(
            key: ValueKey(
              '${state.tab.name}-${state.search}-${state.isLoading}-'
              '${state.items.length}',
            ),
            child: _body(state),
          ),
        ),
      ],
    );
  }

  Widget _body(InterestedBuyersState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const AtelierSkeletonList(count: 4, height: 150);
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return AtelierErrorState(
        title: 'Interested buyers unavailable',
        message: state.errorMessage!,
        onRetry: _refresh,
      );
    }
    if (state.items.isEmpty) {
      final searching = state.search.isNotEmpty;
      return AtelierEmptyState(
        icon: searching
            ? Icons.search_off_rounded
            : Icons.shopping_cart_outlined,
        title: searching
            ? 'No matches'
            : state.tab == InterestedBuyersTab.fresh
            ? 'You’re all caught up'
            : 'No interested buyers yet',
        message: searching
            ? 'Nothing in this view matches “${state.search}”.'
            : 'Buyers appear here 1 hour after they add one of your items '
                  'to their cart.',
        actionLabel: searching ? 'Clear search' : null,
        onAction: searching
            ? () {
                _search.clear();
                _list.setSearch('');
              }
            : null,
      );
    }
    final items = state.items;
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 920 ? 2 : 1;
        const gap = AtelierSpace.s12;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  key: ValueKey(items[i].id),
                  index: i < 8 ? i : 0,
                  child: InterestedBuyerCard(
                    row: items[i],
                    onMessage: () => _message(items[i]),
                    onOffer: () => _offer(items[i]),
                    onChat: () => _openChat(items[i]),
                    onOpenOffers: _openOffers,
                  ),
                ),
              ),
          ],
        );
      },
    );
    if (!state.hasMore) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        grid,
        const SizedBox(height: AtelierSpace.s16),
        Center(
          child: AtelierButton(
            label: 'Load more',
            variant: AtelierButtonVariant.secondary,
            compact: true,
            loading: state.isLoadingMore,
            onPressed: _list.loadMore,
          ),
        ),
      ],
    );
  }
}
