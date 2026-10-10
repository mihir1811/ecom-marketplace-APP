import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/reference_providers.dart';
import '../../domain/models/reference_models.dart';

enum _Tab { accepted, pending, commission }

enum _PurchaseRange { all, d7, d15, d30, custom }

/// Seller referral circle: invite code, people who chose you as their
/// reference, requests awaiting you, commission earned and your own
/// reference. (Buyers have their own BuyerReferencesScreen.)
class SellerReferencesScreen extends ConsumerStatefulWidget {
  const SellerReferencesScreen({super.key});

  @override
  ConsumerState<SellerReferencesScreen> createState() =>
      _SellerReferencesScreenState();
}

class _SellerReferencesScreenState
    extends ConsumerState<SellerReferencesScreen> {
  _Tab _tab = _Tab.accepted;
  bool _tabChosen = false;
  final _request = TextEditingController();
  bool _requestBusy = false;
  String? _requestError;
  final Set<String> _deciding = {};

  @override
  void dispose() {
    _request.dispose();
    super.dispose();
  }

  Future<void> _refresh() => ref.read(referenceHubProvider.notifier).refresh();

  Future<void> _submitRequest() async {
    final value = _request.text.trim();
    if (_requestBusy) return;
    if (value.isEmpty) {
      setState(() => _requestError = 'Enter an email or referral code.');
      return;
    }
    setState(() {
      _requestBusy = true;
      _requestError = null;
    });
    final result = await ref.read(referenceHubProvider.notifier).request(value);
    if (!mounted) return;
    setState(() => _requestBusy = false);
    switch (result) {
      case Success():
        AppHaptics.success();
        _request.clear();
        showAtelierToast(
          context,
          context.tr(RemainingL10n.referenceSent),
          tone: AtelierTone.emerald,
        );
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        setState(() => _requestError = failure.message);
    }
  }

  Future<void> _decide(ReferenceRequest r, {required bool accept}) async {
    if (!accept) {
      final ok = await showAtelierConfirm(
        context: context,
        title: 'Reject this request?',
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
      case ResultFailure(failure: final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  Future<void> _share(ReferenceProfile profile, BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox?;
    final origin = box == null
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceHubProvider);
    final profile = state.profile;
    final pendingCount = profile?.inboundPendingCount ?? 0;
    // Open on the pending queue when someone is waiting, until the seller
    // picks a tab themselves.
    if (!_tabChosen && profile != null && pendingCount > 0) {
      _tab = _Tab.pending;
    }

    if (state.isLoading && profile == null) {
      return AtelierPage(
        onRefresh: _refresh,
        children: const [
          SkeletonBox(height: 300, radius: AtelierRadius.xl),
          SizedBox(height: 20),
          AtelierSkeletonList(count: 3, height: 92),
        ],
      );
    }
    if (state.errorMessage != null && profile == null) {
      return AtelierPage(
        onRefresh: _refresh,
        children: [
          AtelierErrorState(
            title: 'References unavailable',
            message: state.errorMessage!,
            onRetry: _refresh,
          ),
        ],
      );
    }

    final tiles = AtelierTileGrid(
      columns: 3,
      minTileWidth: 104,
      children: [
        AtelierStatTile(
          label: context.tr(RemainingL10n.accepted),
          value: '${profile?.inboundAcceptedCount ?? 0}',
          icon: Icons.people_outline_rounded,
          selected: _tab == _Tab.accepted,
          onTap: () => _select(_Tab.accepted),
        ),
        AtelierStatTile(
          label: context.tr(RemainingL10n.pending),
          value: '$pendingCount',
          icon: Icons.schedule_rounded,
          tone: AtelierTone.amber,
          attention: pendingCount > 0,
          selected: _tab == _Tab.pending,
          onTap: () => _select(_Tab.pending),
        ),
        AtelierStatTile(
          label: context.tr(RemainingL10n.commission),
          value: atelierMoney(profile?.totalCommissionEarned ?? 0, symbol: '₹'),
          icon: Icons.currency_rupee_rounded,
          tone: AtelierTone.emerald,
          selected: _tab == _Tab.commission,
          onTap: () => _select(_Tab.commission),
        ),
      ],
    );

    final panel = AnimatedSwitcher(
      duration: AtelierMotion.base,
      switchInCurve: AtelierMotion.emphasized,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_tab),
        child: switch (_tab) {
          _Tab.accepted => _AcceptedPanel(inbound: state.inbound),
          _Tab.pending => _PendingPanel(
            inbound: state.inbound,
            deciding: _deciding,
            onDecide: _decide,
          ),
          _Tab.commission => _PurchasesPanel(
            purchases: state.purchases,
            isLoadingMore: state.isLoadingMorePurchases,
            isLoadingPurchases: state.isLoadingPurchases,
            error: state.purchasesError,
            hasMore: state.purchasesHasMore,
          ),
        },
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (profile != null)
          Reveal(
            index: 3,
            child: _InviteCard(profile: profile, onShare: _share),
          ),
        const SizedBox(height: AtelierSpace.s20),
        Reveal(
          index: 4,
          child: _MyReferenceCard(
            profile: profile,
            controller: _request,
            busy: _requestBusy,
            error: _requestError,
            onSubmit: _submitRequest,
            onEdited: () {
              if (_requestError != null) setState(() => _requestError = null);
            },
          ),
        ),
      ],
    );

    return AtelierPage(
      onRefresh: _refresh,
      onNearEnd: _tab == _Tab.commission
          ? () => ref.read(referenceHubProvider.notifier).loadMorePurchases()
          : null,
      children: [
        AtelierHero(
          title: context.tr(RemainingL10n.references),
          cut: GemCut.heart,
          action: profile == null
              ? null
              : Builder(
                  builder: (anchor) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AtelierButton(
                        label: 'Share invite',
                        icon: Icons.ios_share_rounded,
                        variant: AtelierButtonVariant.gold,
                        onPressed: () => _share(profile, anchor),
                      ),
                      if (profile.referralCode.isNotEmpty)
                        _OnyxCodeButton(code: profile.referralCode),
                    ],
                  ),
                ),
          footer: AtelierHeroStats(
            stats: [
              AtelierHeroStat(
                label: 'Commission earned',
                value: atelierMoney(
                  profile?.totalCommissionEarned ?? 0,
                  symbol: '₹',
                ),
              ),
              AtelierHeroStat(
                label: context.tr(RemainingL10n.accepted),
                value: '${profile?.inboundAcceptedCount ?? 0}',
                caption: 'People you refer',
              ),
              AtelierHeroStat(
                label: context.tr(RemainingL10n.pending),
                value: '$pendingCount',
                caption: 'Awaiting your answer',
                tone: pendingCount > 0 ? AtelierTone.amber : null,
              ),
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: AtelierSpace.s12),
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
        ],
        const SizedBox(height: AtelierSpace.s24),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < 980) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tiles,
                  const SizedBox(height: AtelierSpace.s16),
                  panel,
                  const SizedBox(height: AtelierSpace.s24),
                  side,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      tiles,
                      const SizedBox(height: AtelierSpace.s16),
                      panel,
                    ],
                  ),
                ),
                const SizedBox(width: AtelierSpace.s24),
                SizedBox(width: 400, child: side),
              ],
            );
          },
        ),
      ],
    );
  }

  void _select(_Tab tab) => setState(() {
    _tabChosen = true;
    _tab = tab;
  });
}

/// Referral code as a quiet outlined chip on the onyx hero; tap copies.
class _OnyxCodeButton extends StatelessWidget {
  const _OnyxCodeButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: () async {
        await atelierCopy(code);
        if (context.mounted) showAtelierToast(context, 'Referral code copied');
      },
      semanticLabel: 'Copy referral code $code',
      borderRadius: BorderRadius.circular(AtelierRadius.pill),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(color: p.onOnyx.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: AtelierType.label(
                p.onOnyx,
                size: 14,
              ).copyWith(letterSpacing: 2),
            ),
            const SizedBox(width: 10),
            Icon(Icons.copy_rounded, size: 15, color: p.gold),
          ],
        ),
      ),
    );
  }
}

class _AcceptedPanel extends StatelessWidget {
  const _AcceptedPanel({required this.inbound});

  final List<ReferenceRequest> inbound;

  @override
  Widget build(BuildContext context) {
    final items = inbound
        .where((r) => r.status == ReferenceStatus.accepted)
        .toList(growable: false);
    return AtelierPanel(
      overline: 'Your circle',
      title: context.tr(RemainingL10n.acceptedReferences),
      child: items.isEmpty
          ? AtelierEmptyState(
              compact: true,
              icon: Icons.people_outline_rounded,
              title: 'No one yet',
              message: context.tr(RemainingL10n.noAcceptedReferences),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const AtelierHairline(vertical: 10),
                  Reveal(
                    index: i < 8 ? i : 0,
                    offset: 6,
                    child: _PersonRow(
                      request: items[i],
                      tone: AtelierTone.emerald,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.request, required this.tone});

  final ReferenceRequest request;
  final AtelierTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final party = request.party;
    final when = request.acceptedAtLabel ?? request.createdAtLabel;
    return Row(
      children: [
        AtelierMonogram(name: party?.displayName ?? request.partyLabel),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                party?.displayName ?? request.partyLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.label(p.ink, size: 13.5),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (party != null &&
                      party.email.trim().isNotEmpty &&
                      party.email != party.displayName)
                    party.email,
                  if (when.isNotEmpty && when != '—') when,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtelierType.caption(p.muted, size: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AtelierPill(label: request.status.label, tone: tone, dense: true),
      ],
    );
  }
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel({
    required this.inbound,
    required this.deciding,
    required this.onDecide,
  });

  final List<ReferenceRequest> inbound;
  final Set<String> deciding;
  final Future<void> Function(ReferenceRequest r, {required bool accept})
  onDecide;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final items = inbound
        .where((r) => r.status == ReferenceStatus.pending)
        .toList(growable: false);
    return AtelierPanel(
      overline: 'Awaiting you',
      title: context.tr(RemainingL10n.requestsToAccept),
      child: items.isEmpty
          ? AtelierEmptyState(
              compact: true,
              icon: Icons.mark_email_read_outlined,
              title: 'You’re all caught up',
              message: context.tr(RemainingL10n.noPendingRequests),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Reveal(
                      key: ValueKey(items[i].id),
                      index: i < 8 ? i : 0,
                      offset: 6,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.sunken.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AtelierRadius.md),
                          border: Border.all(
                            color: p.amber.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                AtelierMonogram(
                                  name:
                                      items[i].party?.displayName ??
                                      items[i].partyLabel,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        items[i].party?.nameWithEmail ??
                                            items[i].partyLabel,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AtelierType.label(
                                          p.ink,
                                          size: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr(
                                          RemainingL10n.requestedDate,
                                          {'date': items[i].createdAtLabel},
                                        ),
                                        style: AtelierType.caption(
                                          p.muted,
                                          size: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AtelierButton(
                                    label: context.tr(RemainingL10n.reject),
                                    compact: true,
                                    variant: AtelierButtonVariant.secondary,
                                    onPressed: deciding.contains(items[i].id)
                                        ? null
                                        : () =>
                                              onDecide(items[i], accept: false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: AtelierButton(
                                    label: context.tr(RemainingL10n.accept),
                                    icon: Icons.check_rounded,
                                    compact: true,
                                    variant: AtelierButtonVariant.gold,
                                    loading: deciding.contains(items[i].id),
                                    onPressed: () =>
                                        onDecide(items[i], accept: true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PurchasesPanel extends ConsumerStatefulWidget {
  const _PurchasesPanel({
    required this.purchases,
    required this.isLoadingMore,
    required this.isLoadingPurchases,
    required this.hasMore,
    this.error,
  });

  final List<ReferencePurchase> purchases;
  final bool isLoadingMore;
  final bool isLoadingPurchases;
  final bool hasMore;
  final String? error;

  @override
  ConsumerState<_PurchasesPanel> createState() => _PurchasesPanelState();
}

class _PurchasesPanelState extends ConsumerState<_PurchasesPanel> {
  _PurchaseRange _range = _PurchaseRange.all;
  DateTimeRange? _custom;

  List<ReferencePurchase> get _filtered {
    final now = DateTime.now().toUtc();
    DateTime? start;
    DateTime? end;
    switch (_range) {
      case _PurchaseRange.all:
        return widget.purchases;
      case _PurchaseRange.d7:
        start = now.subtract(const Duration(days: 7));
      case _PurchaseRange.d15:
        start = now.subtract(const Duration(days: 15));
      case _PurchaseRange.d30:
        start = now.subtract(const Duration(days: 30));
      case _PurchaseRange.custom:
        final c = _custom;
        if (c == null) return widget.purchases;
        start = DateTime(c.start.year, c.start.month, c.start.day).toUtc();
        end = DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59).toUtc();
    }
    return widget.purchases
        .where((p) {
          final at = p.commissionAt?.toUtc();
          if (at == null) return true;
          if (at.isBefore(start!)) return false;
          if (end != null && at.isAfter(end)) return false;
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _onRange(_PurchaseRange range) async {
    if (range != _PurchaseRange.custom) {
      setState(() => _range = range);
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _custom,
      helpText: context.tr(RemainingL10n.customDateRange),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = _PurchaseRange.custom;
      _custom = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final filtered = _filtered;
    final total = filtered.fold<double>(0, (s, e) => s + e.commissionInr);

    Widget body;
    if (widget.isLoadingPurchases && widget.purchases.isEmpty) {
      body = const AtelierSkeletonList(count: 3, height: 78);
    } else if (widget.error != null && widget.purchases.isEmpty) {
      body = AtelierErrorState(
        compact: true,
        title: 'Purchases unavailable',
        message: widget.error!,
        onRetry: () => ref.read(referenceHubProvider.notifier).refresh(),
      );
    } else if (filtered.isEmpty) {
      body = AtelierEmptyState(
        compact: true,
        icon: Icons.receipt_long_outlined,
        title: 'No commission here',
        message: context.tr(RemainingL10n.noCommissionPurchases),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < filtered.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Reveal(
                key: ValueKey(filtered[i].id),
                index: i < 8 ? i : 0,
                offset: 6,
                child: _PurchaseRow(purchase: filtered[i]),
              ),
            ),
          if (widget.isLoadingMore)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: p.gold,
                  ),
                ),
              ),
            )
          else if (widget.error != null)
            AtelierNotice(
              text: widget.error!,
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              actionLabel: context.tr(RemainingL10n.retry),
              onAction: () =>
                  ref.read(referenceHubProvider.notifier).loadMorePurchases(),
            )
          else if (widget.hasMore)
            Center(
              child: AtelierButton(
                label: context.tr(RemainingL10n.loadMore),
                compact: true,
                variant: AtelierButtonVariant.ghost,
                onPressed: () =>
                    ref.read(referenceHubProvider.notifier).loadMorePurchases(),
              ),
            ),
        ],
      );
    }

    String fmt(DateTime d) => atelierDate(d);
    return AtelierPanel(
      overline: 'Earnings',
      title: context.tr(RemainingL10n.referralPurchases),
      subtitle: context.tr(RemainingL10n.diamondAndMeleeOrdersThatEarned),
      trailing: filtered.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('IN VIEW', style: AtelierType.overline(p.muted)),
                const SizedBox(height: 4),
                Text(
                  atelierMoney(total, symbol: '₹'),
                  style: AtelierType.figure(
                    total < 0 ? p.ruby : p.emerald,
                    size: 15,
                  ),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtelierSegmented<_PurchaseRange>(
            dense: true,
            segments: const [
              AtelierSegment(value: _PurchaseRange.all, label: 'All time'),
              AtelierSegment(value: _PurchaseRange.d7, label: '7 days'),
              AtelierSegment(value: _PurchaseRange.d15, label: '15 days'),
              AtelierSegment(value: _PurchaseRange.d30, label: '30 days'),
              AtelierSegment(
                value: _PurchaseRange.custom,
                label: 'Custom',
                icon: Icons.date_range_rounded,
              ),
            ],
            selected: _range,
            onChanged: _onRange,
          ),
          if (_range == _PurchaseRange.custom && _custom != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                AtelierFilterTag(
                  label: '${fmt(_custom!.start)} → ${fmt(_custom!.end)}',
                  onRemove: () => setState(() {
                    _range = _PurchaseRange.all;
                    _custom = null;
                  }),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: AtelierMotion.base,
            child: KeyedSubtree(
              key: ValueKey('$_range-${filtered.length}'),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.purchase});

  final ReferencePurchase purchase;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final reversed = purchase.commissionInr < 0;
    final amountColor = reversed ? p.ruby : p.emerald;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: amountColor.withValues(alpha: p.isDark ? 0.16 : 0.08),
                ),
                child: Icon(
                  reversed
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  size: 16,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.buyerLabel ?? purchase.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.label(p.ink, size: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (purchase.metaLabel.isNotEmpty) purchase.metaLabel,
                        if (purchase.createdAtLabel.isNotEmpty)
                          purchase.createdAtLabel,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                purchase.signedAmountLabel,
                style: AtelierType.figure(amountColor, size: 15),
              ),
            ],
          ),
          if (reversed) ...[
            const SizedBox(height: 10),
            Text(
              'Commission reversed (seller rejected the order)',
              style: AtelierType.caption(p.ruby, size: 11.5),
            ),
          ],
          if (purchase.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in purchase.items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.sunken,
                      borderRadius: BorderRadius.circular(AtelierRadius.pill),
                    ),
                    child: Text(
                      item.lineLabel,
                      style: AtelierType.caption(p.inkSoft, size: 11),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.profile, required this.onShare});

  final ReferenceProfile profile;
  final Future<void> Function(ReferenceProfile, BuildContext) onShare;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierPanel(
      overline: 'Invite',
      title: context.tr(RemainingL10n.shareReference),
      subtitle: context.tr(RemainingL10n.othersCanUseYourEmailOrCode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.goldSoft, p.goldSoft.withValues(alpha: 0.35)],
              ),
              borderRadius: BorderRadius.circular(AtelierRadius.md),
              border: Border.all(color: p.gold.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Text(
                  context.tr(RemainingL10n.yourCode).toUpperCase(),
                  style: AtelierType.overline(p.gold),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    profile.referralCode.isEmpty ? '—' : profile.referralCode,
                    style: AtelierType.display(
                      p.ink,
                      size: 34,
                    ).copyWith(letterSpacing: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CopyRow(
            label: context.tr(RemainingL10n.yourCode),
            value: profile.referralCode,
            icon: Icons.tag_rounded,
          ),
          _CopyRow(
            label: context.tr(RemainingL10n.yourEmail),
            value: profile.email,
            icon: Icons.alternate_email_rounded,
          ),
          _CopyRow(
            label: context.tr(RemainingL10n.shareLink),
            value: profile.shareRegisterUrl,
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (anchor) => AtelierButton(
              label: context.tr(RemainingL10n.shareLink),
              icon: Icons.ios_share_rounded,
              variant: AtelierButtonVariant.secondary,
              expand: true,
              onPressed:
                  profile.shareRegisterUrl.isEmpty &&
                      profile.referralCode.isEmpty
                  ? null
                  : () => onShare(profile, anchor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final empty = value.trim().isEmpty;
    return Pressable(
      onTap: empty
          ? null
          : () async {
              await atelierCopy(value);
              if (context.mounted) showAtelierToast(context, '$label copied');
            },
      semanticLabel: 'Copy $label',
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: p.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AtelierType.overline(p.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    empty ? '—' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 13),
                  ),
                ],
              ),
            ),
            if (!empty) ...[
              const SizedBox(width: 8),
              Text(
                context.tr(RemainingL10n.copy),
                style: AtelierType.label(p.gold, size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MyReferenceCard extends StatelessWidget {
  const _MyReferenceCard({
    required this.profile,
    required this.controller,
    required this.busy,
    required this.error,
    required this.onSubmit,
    required this.onEdited,
  });

  final ReferenceProfile? profile;
  final TextEditingController controller;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final active = profile?.activeOutbound;
    final history = profile?.outboundHistory ?? const <ReferenceRequest>[];

    return AtelierPanel(
      overline: 'Your reference',
      title: context.tr(RemainingL10n.myReference2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.sunken.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AtelierRadius.md),
              ),
              child: Row(
                children: [
                  AtelierMonogram(
                    name: active.party?.displayName ?? active.partyLabel,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(RemainingL10n.referrer).trim(),
                          style: AtelierType.overline(p.muted),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          active.party?.nameWithEmail ?? active.partyLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.label(p.ink, size: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AtelierPill(
                    label: active.status.label,
                    tone: switch (active.status) {
                      ReferenceStatus.accepted => AtelierTone.emerald,
                      ReferenceStatus.pending => AtelierTone.amber,
                      ReferenceStatus.rejected => AtelierTone.ruby,
                    },
                    dense: true,
                  ),
                ],
              ),
            )
          else ...[
            Text(
              context.tr(RemainingL10n.addSomeoneAsYourReferenceUsingTheir),
              style: AtelierType.caption(p.inkSoft, size: 12.5),
            ),
            const SizedBox(height: 14),
            AtelierTextField(
              controller: controller,
              label: 'Email or referral code',
              hint: context.tr(RemainingL10n.emailReferralCode),
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              error: error,
              onChanged: (_) => onEdited(),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 12),
            AtelierButton(
              label: context.tr(RemainingL10n.request),
              icon: Icons.send_rounded,
              expand: true,
              loading: busy,
              onPressed: onSubmit,
            ),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              context.tr(RemainingL10n.requestHistory).toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < history.length; i++) ...[
              if (i > 0) const AtelierHairline(vertical: 8),
              _PersonRow(
                request: history[i],
                tone: switch (history[i].status) {
                  ReferenceStatus.accepted => AtelierTone.emerald,
                  ReferenceStatus.pending => AtelierTone.amber,
                  ReferenceStatus.rejected => AtelierTone.ruby,
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}
