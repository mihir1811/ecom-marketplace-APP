import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../buyer/presentation/maison/maison_kit.dart';
import '../../../buyer/presentation/maison/maison_layout.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/reference_providers.dart';
import '../../domain/models/reference_models.dart';
import '../widgets/buyer/circle_earnings.dart';
import '../widgets/buyer/circle_invite_card.dart';
import '../widgets/buyer/circle_people.dart';

enum _Lens { circle, requests, earnings }

/// The buyer's referral circle: their invitation pass up top, who
/// referred them, three figures that double as filters, then the circle,
/// requests awaiting an answer, or commission earned.
class BuyerReferencesScreen extends ConsumerStatefulWidget {
  const BuyerReferencesScreen({super.key});

  @override
  ConsumerState<BuyerReferencesScreen> createState() =>
      _BuyerReferencesScreenState();
}

class _BuyerReferencesScreenState extends ConsumerState<BuyerReferencesScreen> {
  _Lens _lens = _Lens.circle;
  bool _lensChosen = false;
  final _search = TextEditingController();
  final Set<String> _deciding = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(referenceHubProvider.notifier).refresh();

  void _select(_Lens lens) => setState(() {
    _lensChosen = true;
    _lens = lens;
  });

  Future<void> _share(ReferenceProfile profile, BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox?;
    final origin = box == null || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final link = profile.shareRegisterUrl.trim();
    final code = profile.referralCode.trim();
    await SharePlus.instance.share(
      ShareParams(
        text: [
          'Join me on GemWorld.',
          if (code.isNotEmpty) 'Use my referral code $code.',
          if (link.isNotEmpty) link,
        ].join(' '),
        subject: 'Join me on GemWorld',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> _decide(ReferenceRequest r, {required bool accept}) async {
    if (_deciding.contains(r.id)) return;
    if (!accept) {
      final ok = await showAtelierConfirm(
        context: context,
        title: 'Decline this request?',
        message:
            '${r.party?.displayName ?? r.partyLabel} won’t be linked to you '
            'as their reference.',
        confirmLabel: context.tr(RemainingL10n.reject),
        destructive: true,
        icon: Icons.person_remove_outlined,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _deciding.add(r.id));
    final notifier = ref.read(referenceHubProvider.notifier);
    final result = accept
        ? await notifier.accept(r.id)
        : await notifier.reject(r.id);
    if (!mounted) return;
    setState(() => _deciding.remove(r.id));
    switch (result) {
      case Success():
        accept ? AppHaptics.success() : AppHaptics.warning();
        showAtelierToast(
          context,
          accept
              ? context.tr(RemainingL10n.requestAccepted)
              : context.tr(RemainingL10n.requestRejected),
          tone: accept ? AtelierTone.emerald : AtelierTone.neutral,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(referenceHubProvider);
    final profile = state.profile;
    final pending = state.inbound
        .where((r) => r.status == ReferenceStatus.pending)
        .toList(growable: false);
    final accepted = state.inbound
        .where((r) => r.status == ReferenceStatus.accepted)
        .toList(growable: false);
    final pendingCount = profile?.inboundPendingCount ?? pending.length;
    final acceptedCount = profile?.inboundAcceptedCount ?? accepted.length;
    final earned = profile?.totalCommissionEarned ?? 0;
    // Open on the queue while someone is waiting, until the buyer chooses.
    if (!_lensChosen && profile != null && pendingCount > 0) {
      _lens = _Lens.requests;
    }
    final gutter = AtelierSpace.gutter(MediaQuery.sizeOf(context).width);
    final ready = profile != null;

    return MaisonLayout(
      detail: true,
      child: RefreshIndicator(
        color: p.gold,
        backgroundColor: p.surface,
        onRefresh: _refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (_lens == _Lens.earnings &&
                n is ScrollUpdateNotification &&
                n.metrics.maxScrollExtent > 0 &&
                n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
              ref.read(referenceHubProvider.notifier).loadMorePurchases();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 18),
                sliver: SliverToBoxAdapter(
                  child: MaisonCentered(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MaisonHeader(
                          overline: 'Referral circle',
                          title: context.tr(RemainingL10n.references),
                          subtitle: !ready
                              ? context.tr(RemainingL10n.referenceIntro)
                              : acceptedCount == 0
                              ? 'Invite collectors you trust and earn on '
                                    'their orders.'
                              : '$acceptedCount '
                                    '${acceptedCount == 1 ? 'collector' : 'collectors'}'
                                    ' in your circle · '
                                    '${atelierMoney(earned, symbol: '₹')} '
                                    'earned.',
                          cut: GemCut.heart,
                          look: GemLook.champagne,
                        ),
                        const SizedBox(height: 22),
                        if (!ready && state.isLoading)
                          const _HeadSkeleton()
                        else if (!ready && state.errorMessage != null)
                          AtelierErrorState(
                            title: 'References unavailable',
                            message: state.errorMessage!,
                            onRetry: _refresh,
                          )
                        else if (ready)
                          _Head(
                            profile: profile,
                            pendingCount: pendingCount,
                            acceptedCount: acceptedCount,
                            earned: earned,
                            lens: _lens,
                            error: state.errorMessage,
                            onRetry: _refresh,
                            onLens: _select,
                            onShare: (anchor) => _share(profile, anchor),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (ready) ...[
                MaisonPinnedBar(
                  height: 66,
                  gutter: gutter,
                  child: MaisonCentered(
                    maxWidth: 760,
                    child: AtelierSegmented<_Lens>(
                      expand: true,
                      segments: [
                        AtelierSegment(
                          value: _Lens.circle,
                          label: 'Circle',
                          icon: Icons.diversity_3_outlined,
                          count: acceptedCount,
                        ),
                        AtelierSegment(
                          value: _Lens.requests,
                          label: 'Requests',
                          icon: Icons.mark_email_unread_outlined,
                          count: pendingCount,
                        ),
                        const AtelierSegment(
                          value: _Lens.earnings,
                          label: 'Earnings',
                          icon: Icons.currency_rupee_rounded,
                        ),
                      ],
                      selected: _lens,
                      onChanged: _select,
                    ),
                  ),
                ),
                MaisonRefreshHairline(visible: state.isLoading),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 48),
                  sliver: SliverToBoxAdapter(
                    child: MaisonCentered(
                      maxWidth: 760,
                      child: AnimatedSwitcher(
                        duration: AtelierMotion.base,
                        switchInCurve: AtelierMotion.emphasized,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [...previous, ?current],
                        ),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.015),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_lens),
                          child: switch (_lens) {
                            _Lens.circle => _circle(accepted, profile),
                            _Lens.requests => _requests(pending),
                            _Lens.earnings => CircleEarningsPanel(
                              purchases: state.purchases,
                              loading: state.isLoadingPurchases,
                              loadingMore: state.isLoadingMorePurchases,
                              hasMore: state.purchasesHasMore,
                              error: state.purchasesError,
                              onRetry: _refresh,
                              onLoadMore: () => ref
                                  .read(referenceHubProvider.notifier)
                                  .loadMorePurchases(),
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(List<ReferenceRequest> accepted, ReferenceProfile profile) {
    final p = context.atelier;
    if (accepted.isEmpty) {
      return Builder(
        builder: (anchor) => AtelierEmptyState(
          icon: Icons.diversity_3_outlined,
          title: 'Your circle begins here',
          message: context.tr(RemainingL10n.noAcceptedReferences),
          actionLabel: 'Share invite',
          onAction: () => _share(profile, anchor),
        ),
      );
    }
    final q = _search.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? accepted
        : [
            for (final r in accepted)
              if ((r.party?.displayName ?? r.partyLabel).toLowerCase().contains(
                    q,
                  ) ||
                  (r.party?.email ?? '').toLowerCase().contains(q))
                r,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accepted.length > 5) ...[
          AtelierSearchField(
            controller: _search,
            hint: 'Search name or email',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
        ],
        MaisonGroupLabel(
          label: context.tr(RemainingL10n.acceptedReferences),
          count: shown.length,
        ),
        if (shown.isEmpty)
          AtelierEmptyState(
            compact: true,
            icon: Icons.search_off_rounded,
            title: 'No matches',
            message: 'No one in your circle matches “${_search.text.trim()}”.',
            actionLabel: 'Clear search',
            onAction: () => setState(_search.clear),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AtelierRadius.lg),
              border: Border.all(color: p.hairline),
              boxShadow: p.softShadow,
            ),
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const AtelierHairline(),
                  Reveal(
                    key: ValueKey('circle-${shown[i].id}'),
                    index: i < 8 ? i : 0,
                    offset: 6,
                    child: CirclePersonRow(request: shown[i]),
                  ),
                ],
              ],
            ),
          ),
        if (shown.isNotEmpty)
          MaisonListFooter(
            loadingMore: false,
            hasMore: false,
            onLoadMore: _refresh,
            endLabel: 'Everyone you’ve welcomed',
          ),
      ],
    );
  }

  Widget _requests(List<ReferenceRequest> pending) {
    if (pending.isEmpty) {
      return AtelierEmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'You’re all caught up',
        message: context.tr(RemainingL10n.noPendingRequests),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaisonGroupLabel(
          label: context.tr(RemainingL10n.requestsToAccept),
          count: pending.length,
        ),
        for (var i = 0; i < pending.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Reveal(
              key: ValueKey('request-${pending[i].id}'),
              index: i < 8 ? i : 0,
              child: CircleRequestCard(
                request: pending[i],
                busy: _deciding.contains(pending[i].id),
                onDecide: ({required accept}) =>
                    _decide(pending[i], accept: accept),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pass, sponsor, notices and figures; two columns on wide screens.
class _Head extends StatelessWidget {
  const _Head({
    required this.profile,
    required this.pendingCount,
    required this.acceptedCount,
    required this.earned,
    required this.lens,
    required this.onRetry,
    required this.onLens,
    required this.onShare,
    this.error,
  });

  final ReferenceProfile profile;
  final int pendingCount;
  final int acceptedCount;
  final double earned;
  final _Lens lens;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<_Lens> onLens;
  final void Function(BuildContext anchor) onShare;

  @override
  Widget build(BuildContext context) {
    final pass = Reveal(
      index: 2,
      child: CircleInviteCard(profile: profile, onShare: onShare),
    );
    final sponsor = Reveal(
      index: 3,
      child: CircleSponsorTile(
        profile: profile,
        onOpen: () => showCircleSponsorSheet(context),
      ),
    );
    final stats = Reveal(
      index: 4,
      child: MaisonStatStrip(
        stats: [
          MaisonStat(
            label: 'Circle',
            value: '$acceptedCount',
            caption: 'Accepted',
            selected: lens == _Lens.circle,
            onTap: () => onLens(_Lens.circle),
          ),
          MaisonStat(
            label: 'Awaiting',
            value: '$pendingCount',
            caption: 'Need your answer',
            tone: pendingCount > 0 ? AtelierTone.amber : null,
            pulse: pendingCount > 0,
            selected: lens == _Lens.requests,
            onTap: () => onLens(_Lens.requests),
          ),
          MaisonStat(
            label: context.tr(RemainingL10n.commission),
            value: atelierMoney(earned, symbol: '₹'),
            caption: 'Earned',
            tone: AtelierTone.emerald,
            selected: lens == _Lens.earnings,
            onTap: () => onLens(_Lens.earnings),
          ),
        ],
      ),
    );
    final notices = [
      if (error != null) ...[
        AtelierNotice(
          text: 'Showing your last loaded circle — $error',
          tone: AtelierTone.ruby,
          icon: Icons.cloud_off_rounded,
          actionLabel: context.tr(RemainingL10n.retry),
          onAction: onRetry,
        ),
        const SizedBox(height: 14),
      ],
      if (pendingCount > 0 && lens != _Lens.requests) ...[
        AtelierNotice(
          text: pendingCount == 1
              ? '1 person is waiting for you to accept their request.'
              : '$pendingCount people are waiting for your answer.',
          tone: AtelierTone.amber,
          icon: Icons.mark_email_unread_outlined,
          actionLabel: 'Review',
          onAction: () => onLens(_Lens.requests),
        ),
        const SizedBox(height: 14),
      ],
    ];

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              pass,
              const SizedBox(height: 14),
              sponsor,
              const SizedBox(height: 14),
              ...notices,
              stats,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: pass),
                const SizedBox(width: 20),
                Expanded(
                  flex: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sponsor,
                      const SizedBox(height: 16),
                      ...notices,
                      stats,
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeadSkeleton extends StatelessWidget {
  const _HeadSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonBox(height: 320, radius: AtelierRadius.xl),
        SizedBox(height: 14),
        SkeletonBox(height: 76, radius: AtelierRadius.lg),
        SizedBox(height: 14),
        SkeletonBox(height: 92, radius: AtelierRadius.lg),
        SizedBox(height: 22),
        AtelierSkeletonList(count: 3, height: 72),
      ],
    );
  }
}
