import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/account_nav.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_view.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../chat/application/chat_sides.dart';
import '../../../chat/domain/models/chat_product_type.dart';
import '../../../chat/domain/models/chat_thread.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import 'buyer_chat_detail_screen.dart';

/// The buyer's correspondence: every conversation with a seller about a
/// piece they're considering, unread ones flagged in gold, grouped by
/// recency. Threads about the user's own listings stay in the seller inbox.
/// On wide screens the open conversation sits beside the inbox.
class BuyerChatListScreen extends ConsumerStatefulWidget {
  const BuyerChatListScreen({super.key});

  @override
  ConsumerState<BuyerChatListScreen> createState() =>
      _BuyerChatListScreenState();
}

/// Inbox filter: everything, unread only, or one product category.
sealed class _InboxFilter {
  const _InboxFilter();
}

class _AllFilter extends _InboxFilter {
  const _AllFilter();

  @override
  bool operator ==(Object other) => other is _AllFilter;

  @override
  int get hashCode => 0;
}

class _UnreadFilter extends _InboxFilter {
  const _UnreadFilter();

  @override
  bool operator ==(Object other) => other is _UnreadFilter;

  @override
  int get hashCode => 1;
}

class _TypeFilter extends _InboxFilter {
  const _TypeFilter(this.type);

  final ChatProductType type;

  @override
  bool operator ==(Object other) => other is _TypeFilter && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

class _BuyerChatListScreenState extends ConsumerState<BuyerChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _InboxFilter _filter = const _AllFilter();

  /// Conversation shown in the side pane on wide layouts.
  String? _selectedId;

  static const _splitBreakpoint = 960.0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(chatInboxProvider.notifier).refresh();

  bool _matchesQuery(ChatThread t) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return t.peerName.toLowerCase().contains(q) ||
        t.lastMessage.toLowerCase().contains(q) ||
        t.productId.toLowerCase().contains(q) ||
        t.productType.label.toLowerCase().contains(q) ||
        t.productNameHint.toLowerCase().contains(q);
  }

  bool _matchesFilter(ChatThread t) => switch (_filter) {
    _AllFilter() => true,
    _UnreadFilter() => t.unreadCount > 0,
    _TypeFilter(:final type) => t.productType == type,
  };

  void _open(ChatThread thread, {required bool split}) {
    if (split) {
      setState(() => _selectedId = thread.id);
      return;
    }
    context.openRoute(
      chatDetailPathFor(GoRouterState.of(context).uri.path, thread.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final view = ref.watch(buyerChatInboxProvider);
    final state = view.inbox;
    final sorted = [...view.threads]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    final visible = [
      for (final t in sorted)
        if (_matchesFilter(t) && _matchesQuery(t)) t,
    ];

    return ColoredBox(
      color: p.canvas,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= _splitBreakpoint;
          final inbox = _Inbox(
            state: state,
            resolving: view.resolving,
            all: sorted,
            visible: visible,
            query: _query,
            filter: _filter,
            selectedId: split ? _selectedId : null,
            compactHero: split,
            searchCtrl: _searchCtrl,
            onQuery: (v) => setState(() => _query = v.trim()),
            onFilter: (f) => setState(() => _filter = f),
            onClear: () {
              _searchCtrl.clear();
              setState(() {
                _query = '';
                _filter = const _AllFilter();
              });
            },
            onRefresh: _refresh,
            onOpen: (t) => _open(t, split: split),
          );
          if (!split) return inbox;

          final selected = _selectedId;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: constraints.maxWidth >= 1280 ? 440 : 380,
                child: inbox,
              ),
              Container(width: 1, color: p.hairline),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AtelierMotion.base,
                  switchInCurve: AtelierMotion.emphasized,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.015, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: selected == null
                      ? const _ConversationPlaceholder(key: ValueKey('none'))
                      : BuyerChatDetailScreen(
                          key: ValueKey(selected),
                          chatId: selected,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({
    required this.state,
    required this.resolving,
    required this.all,
    required this.visible,
    required this.query,
    required this.filter,
    required this.selectedId,
    required this.compactHero,
    required this.searchCtrl,
    required this.onQuery,
    required this.onFilter,
    required this.onClear,
    required this.onRefresh,
    required this.onOpen,
  });

  final ChatInboxState state;

  /// Product owners still loading, so the buyer's threads aren't final yet.
  final bool resolving;
  final List<ChatThread> all;
  final List<ChatThread> visible;
  final String query;
  final _InboxFilter filter;
  final String? selectedId;
  final bool compactHero;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onQuery;
  final ValueChanged<_InboxFilter> onFilter;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  final ValueChanged<ChatThread> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final gutter = compactHero
        ? AtelierSpace.s20
        : AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final unreadThreads = all.where((t) => t.unreadCount > 0).length;
    final unreadMessages = all.fold<int>(0, (s, t) => s + t.unreadCount);
    final now = DateTime.now();
    final today = all.where((t) {
      final d = t.lastMessageAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
    final types = <ChatProductType>{for (final t in all) t.productType};
    final firstLoad = (state.isLoading || resolving) && all.isEmpty;

    final segments = <AtelierSegment<_InboxFilter>>[
      AtelierSegment(
        value: const _AllFilter(),
        label: context.tr(RemainingL10n.all),
        count: firstLoad ? null : all.length,
      ),
      AtelierSegment(
        value: const _UnreadFilter(),
        label: 'Unread',
        icon: Icons.mark_chat_unread_outlined,
        count: firstLoad ? null : unreadThreads,
      ),
      if (types.length > 1)
        for (final type in ChatProductType.values)
          if (types.contains(type))
            AtelierSegment(
              value: _TypeFilter(type),
              label: type.label,
              count: all.where((t) => t.productType == type).length,
            ),
    ];

    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
        sliver: SliverToBoxAdapter(
          child: _InboxHero(
            compact: compactHero,
            unreadMessages: unreadMessages,
            unreadThreads: unreadThreads,
            total: all.length,
            today: today,
            loading: firstLoad,
          ),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: _ControlsHeader(
          gutter: gutter,
          canvas: p.canvas,
          hairline: p.hairline,
          syncing: (state.isLoading || resolving) && all.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AtelierSearchField(
                controller: searchCtrl,
                hint: context.tr(RemainingL10n.searchConversations),
                onChanged: onQuery,
              ),
              const SizedBox(height: AtelierSpace.s10),
              AtelierSegmented<_InboxFilter>(
                segments: segments,
                selected: filter,
                onChanged: onFilter,
                dense: true,
              ),
            ],
          ),
        ),
      ),
      ..._content(context, gutter, firstLoad),
    ];

    return RefreshIndicator(
      color: p.gold,
      backgroundColor: p.surface,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: slivers,
      ),
    );
  }

  List<Widget> _content(BuildContext context, double gutter, bool firstLoad) {
    Widget boxed(Widget child) => SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 48),
      sliver: SliverToBoxAdapter(child: child),
    );

    if (firstLoad) {
      return [boxed(const AtelierSkeletonList(count: 6, height: 84))];
    }
    if (state.errorMessage != null && all.isEmpty) {
      return [
        boxed(
          AtelierErrorState(
            title: 'Inbox unavailable',
            message: state.errorMessage!,
            onRetry: onRefresh,
          ),
        ),
      ];
    }
    if (all.isEmpty) {
      return [
        boxed(
          AtelierEmptyState(
            icon: Icons.forum_outlined,
            title: context.tr(RemainingL10n.noMessages),
            message:
                'Ask a seller about any piece from its page — your '
                'conversations will gather here.',
          ),
        ),
      ];
    }
    if (visible.isEmpty) {
      final unreadOnly = filter is _UnreadFilter && query.isEmpty;
      return [
        boxed(
          AtelierEmptyState(
            compact: true,
            icon: unreadOnly
                ? Icons.mark_chat_read_outlined
                : Icons.search_off_rounded,
            title: unreadOnly
                ? 'You’re all caught up'
                : context.tr(RemainingL10n.noMatches),
            message: unreadOnly
                ? 'Every conversation has been read.'
                : context.tr(RemainingL10n.differentSearch),
            actionLabel: 'Show all conversations',
            onAction: onClear,
          ),
        ),
      ];
    }

    final groups = _groupByRecency(context, visible);
    final starts = <int>[];
    var running = 0;
    for (final g in groups) {
      starts.add(running);
      running += g.threads.length;
    }
    return [
      if (state.errorMessage != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
          sliver: SliverToBoxAdapter(
            child: AtelierNotice(
              text: state.errorMessage!,
              tone: AtelierTone.ruby,
              icon: Icons.cloud_off_rounded,
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: onRefresh,
            ),
          ),
        ),
      for (var g = 0; g < groups.length; g++) ...[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter + 4, 18, gutter, 10),
          sliver: SliverToBoxAdapter(
            child: Text(
              groups[g].label.toUpperCase(),
              style: AtelierType.overline(context.atelier.muted),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverToBoxAdapter(
            child: _ThreadGroup(
              threads: groups[g].threads,
              firstIndex: starts[g],
              selectedId: selectedId,
              onOpen: onOpen,
            ),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 48)),
    ];
  }
}

class _RecencyGroup {
  _RecencyGroup(this.label);

  final String label;
  final threads = <ChatThread>[];
}

List<_RecencyGroup> _groupByRecency(
  BuildContext context,
  List<ChatThread> threads,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final groups = <String, _RecencyGroup>{};
  for (final t in threads) {
    final d = t.lastMessageAt.toLocal();
    final day = DateTime(d.year, d.month, d.day);
    final age = today.difference(day).inDays;
    final label = age <= 0
        ? context.tr(RemainingL10n.today)
        : age == 1
        ? context.tr(RemainingL10n.yesterday)
        : age < 7
        ? 'This week'
        : 'Earlier';
    groups.putIfAbsent(label, () => _RecencyGroup(label)).threads.add(t);
  }
  return groups.values.toList();
}

/// Onyx band with the inbox's headline numbers.
class _InboxHero extends StatelessWidget {
  const _InboxHero({
    required this.compact,
    required this.unreadMessages,
    required this.unreadThreads,
    required this.total,
    required this.today,
    required this.loading,
  });

  final bool compact;
  final int unreadMessages;
  final int unreadThreads;
  final int total;
  final int today;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final subtitle = loading
        ? 'Gathering your conversations…'
        : unreadThreads == 0
        ? 'You’re all caught up — nothing new from sellers.'
        : '$unreadThreads ${unreadThreads == 1 ? 'seller has' : 'sellers have'} written back.';
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy = constraints.maxWidth >= 560;
        return AtelierHero(
          overline: 'Your correspondence',
          title: context.tr(CoreL10n.messages),
          subtitle: subtitle,
          cut: compact ? null : GemCut.pear,
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Unread',
                value: loading ? '—' : '$unreadMessages',
                caption: unreadMessages == 1 ? 'new message' : 'new messages',
                tone: unreadMessages > 0 ? AtelierTone.gold : null,
              ),
              AtelierHeroStat(
                label: 'Conversations',
                value: loading ? '—' : '$total',
                caption: 'With sellers',
              ),
              if (roomy)
                AtelierHeroStat(
                  label: 'Active today',
                  value: loading ? '—' : '$today',
                  caption: today == 1 ? 'thread moved' : 'threads moved',
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Pinned search + filter bar; gains a hairline once content slides under.
class _ControlsHeader extends SliverPersistentHeaderDelegate {
  _ControlsHeader({
    required this.child,
    required this.gutter,
    required this.canvas,
    required this.hairline,
    required this.syncing,
  });

  final Widget child;
  final double gutter;
  final Color canvas;
  final Color hairline;
  final bool syncing;

  // search + gap + filters + padding + bottom hairline.
  static const _height = 46.0 + 10 + 36 + 16 + 14 + 1;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final p = context.atelier;
    return AnimatedContainer(
      duration: AtelierMotion.base,
      decoration: BoxDecoration(
        color: canvas,
        border: Border(
          bottom: BorderSide(
            color: overlaps ? hairline : hairline.withValues(alpha: 0),
          ),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 14),
            child: child,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              duration: AtelierMotion.base,
              opacity: syncing ? 1 : 0,
              child: LinearProgressIndicator(
                minHeight: 1.5,
                color: p.gold,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ControlsHeader old) =>
      old.child != child ||
      old.gutter != gutter ||
      old.canvas != canvas ||
      old.syncing != syncing;
}

/// One recency group, drawn as a single quiet surface with hairline rows.
class _ThreadGroup extends StatelessWidget {
  const _ThreadGroup({
    required this.threads,
    required this.firstIndex,
    required this.selectedId,
    required this.onOpen,
  });

  final List<ChatThread> threads;
  final int firstIndex;
  final String? selectedId;
  final ValueChanged<ChatThread> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
        boxShadow: p.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < threads.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 76),
                child: Container(height: 1, color: p.hairline),
              ),
            Reveal(
              index: firstIndex + i,
              offset: 10,
              child: _ThreadRow(
                key: ValueKey(threads[i].id),
                thread: threads[i],
                selected: threads[i].id == selectedId,
                onTap: () => onOpen(threads[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThreadRow extends StatefulWidget {
  const _ThreadRow({
    required this.thread,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ChatThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThreadRow> createState() => _ThreadRowState();
}

class _ThreadRowState extends State<_ThreadRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final t = widget.thread;
    final unread = t.unreadCount > 0;
    final bg = widget.selected
        ? p.goldSoft
        : _hover
        ? p.sunken.withValues(alpha: 0.6)
        : Colors.transparent;
    final preview = t.lastMessage.trim().isEmpty
        ? context.tr(RemainingL10n.photo)
        : t.lastMessage.trim();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Pressable(
        onTap: widget.onTap,
        scale: 0.99,
        semanticLabel: [
          t.peerName,
          t.listingLabel,
          if (unread) '${t.unreadCount} unread',
          preview,
        ].join(', '),
        borderRadius: BorderRadius.zero,
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PeerAvatar(name: t.peerName, url: t.peerAvatar, ring: unread),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.peerName.trim().isEmpty
                                ? context.tr(RemainingL10n.conversation)
                                : t.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.title(p.ink, size: 15).copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(context, t.lastMessageAt),
                          style: AtelierType.caption(
                            unread ? p.gold : p.muted,
                            size: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_typeIcon(t.productType), size: 12, color: p.gold),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            t.listingLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.caption(p.inkSoft, size: 11.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AtelierType.body(
                                  unread ? p.ink : p.muted,
                                  size: 13,
                                ).copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  height: 1.4,
                                ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 10),
                          CountBubble(count: t.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seller avatar (logo or photo when available, monogram otherwise) with a gold
/// ring while they are waiting on a reply.
class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.name, required this.url, this.ring = false});

  final String name;
  final String url;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    const size = 46.0;
    final monogram = AtelierMonogram(name: name, size: size);
    final link = url.trim();
    final face = link.isEmpty
        ? monogram
        : ClipOval(
            child: AppNetworkImage(
              url: link,
              width: size,
              height: size,
              memCacheWidth: (size * 3).round(),
              error: monogram,
            ),
          );
    return AnimatedContainer(
      duration: AtelierMotion.base,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ring ? p.gold : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: face,
    );
  }
}

/// Right pane before any conversation is chosen (wide layouts).
class _ConversationPlaceholder extends StatelessWidget {
  const _ConversationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Stack(
      children: [
        const Positioned.fill(child: AtelierAmbient(intensity: 0.7)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AtelierSpace.s32),
            child: Reveal(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GemView(
                    cut: GemCut.pear,
                    size: 150,
                    spin: 0.28,
                    interactive: true,
                    semanticLabel: 'Rotating gem. Drag to turn it.',
                  ),
                  const SizedBox(height: AtelierSpace.s24),
                  Text('CORRESPONDENCE', style: AtelierType.overline(p.gold)),
                  const SizedBox(height: 10),
                  Text(
                    'Choose a conversation',
                    textAlign: TextAlign.center,
                    style: AtelierType.display(p.ink, size: 30),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      'Pick a seller from the inbox to read the thread, see '
                      'the piece you asked about and reply.',
                      textAlign: TextAlign.center,
                      style: AtelierType.body(p.muted, size: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

IconData _typeIcon(ChatProductType type) => switch (type) {
  ChatProductType.diamond => Icons.diamond_outlined,
  ChatProductType.meleeDiamond => Icons.grain_rounded,
  ChatProductType.gemstone => Icons.hexagon_outlined,
  ChatProductType.jewellery => Icons.auto_awesome_outlined,
  ChatProductType.watch => Icons.watch_outlined,
  ChatProductType.bullion => Icons.view_module_outlined,
};

String _relativeTime(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return context.tr(RemainingL10n.now);
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}';
}
