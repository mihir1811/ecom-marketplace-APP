import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../application/reference_providers.dart';
import '../../domain/models/reference_models.dart';

enum RefTab { accepted, pending, commission }

enum RefRange {
  all('All'),
  d7('7 days'),
  d15('15 days'),
  d30('30 days'),
  custom('Custom');

  const RefRange(this.label);
  final String label;
}

Color refStatusColor(AtelierPalette p, ReferenceStatus s) => switch (s) {
  ReferenceStatus.accepted => p.emerald,
  ReferenceStatus.pending => p.amber,
  ReferenceStatus.rejected => p.ruby,
};

String _clean(String? s) {
  final t = (s ?? '').trim();
  return t == '—' ? '' : t;
}

/// Whole references page body, shared by buyer and seller screens:
/// code/share bar, own reference row, tabs with counts, then the list.
class ReferencesView extends ConsumerStatefulWidget {
  const ReferencesView({super.key});

  @override
  ConsumerState<ReferencesView> createState() => _ReferencesViewState();
}

class _ReferencesViewState extends ConsumerState<ReferencesView> {
  RefTab _tab = RefTab.accepted;
  bool _tabChosen = false;
  final Set<String> _deciding = {};

  Future<void> _refresh() => ref.read(referenceHubProvider.notifier).refresh();

  Future<void> _decide(ReferenceRequest r, {required bool accept}) async {
    if (_deciding.contains(r.id)) return;
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
      case ResultFailure(:final failure):
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceHubProvider);
    final profile = state.profile;
    final notifier = ref.read(referenceHubProvider.notifier);
    final pending = [
      for (final r in state.inbound)
        if (r.status == ReferenceStatus.pending) r,
    ];
    final accepted = [
      for (final r in state.inbound)
        if (r.status == ReferenceStatus.accepted) r,
    ];
    final pendingCount = profile?.inboundPendingCount ?? pending.length;
    final acceptedCount = profile?.inboundAcceptedCount ?? accepted.length;
    if (!_tabChosen && profile != null && pendingCount > 0) {
      _tab = RefTab.pending;
    }

    final List<Widget> children;
    if (profile == null && state.isLoading) {
      children = const [
        SkeletonBox(height: 90, radius: AtelierRadius.md),
        SizedBox(height: 6),
        AtelierSkeletonList(count: 4, height: 44),
      ];
    } else if (profile == null) {
      children = [
        AtelierErrorState(
          compact: true,
          title: 'References unavailable',
          message: state.errorMessage ?? '',
          onRetry: _refresh,
        ),
      ];
    } else {
      children = [
        if (state.errorMessage != null) ...[
          AtelierNotice(
            text: state.errorMessage!,
            tone: AtelierTone.ruby,
            icon: Icons.error_outline_rounded,
            actionLabel: context.tr(RemainingL10n.retry),
            onAction: _refresh,
          ),
          const SizedBox(height: 6),
        ],
        RefInviteBar(profile: profile),
        const SizedBox(height: 6),
        RefSponsorRow(
          profile: profile,
          onOpen: () => showRefSponsorSheet(context),
        ),
        const SizedBox(height: 6),
        AtelierSegmented<RefTab>(
          expand: true,
          dense: true,
          segments: [
            AtelierSegment(
              value: RefTab.accepted,
              label: context.tr(RemainingL10n.accepted),
              count: acceptedCount,
            ),
            AtelierSegment(
              value: RefTab.pending,
              label: context.tr(RemainingL10n.pending),
              count: pendingCount,
            ),
            AtelierSegment(
              value: RefTab.commission,
              label: atelierMoney(profile.totalCommissionEarned, symbol: '₹'),
            ),
          ],
          selected: _tab,
          onChanged: (t) => setState(() {
            _tabChosen = true;
            _tab = t;
          }),
        ),
        const SizedBox(height: 6),
        switch (_tab) {
          RefTab.accepted => RefList(
            empty: context.tr(RemainingL10n.noAcceptedReferences),
            children: [for (final r in accepted) RefPersonRow(request: r)],
          ),
          RefTab.pending => RefList(
            empty: context.tr(RemainingL10n.noPendingRequests),
            children: [
              for (final r in pending)
                RefRequestRow(
                  request: r,
                  busy: _deciding.contains(r.id),
                  onDecide: ({required accept}) => _decide(r, accept: accept),
                ),
            ],
          ),
          RefTab.commission => RefEarnings(
            purchases: state.purchases,
            loading: state.isLoadingPurchases,
            loadingMore: state.isLoadingMorePurchases,
            hasMore: state.purchasesHasMore,
            error: state.purchasesError,
            onRetry: _refresh,
            onLoadMore: notifier.loadMorePurchases,
          ),
        },
      ];
    }

    return AtelierPage(
      maxWidth: 760,
      onRefresh: _refresh,
      onNearEnd: _tab == RefTab.commission ? notifier.loadMorePurchases : null,
      children: children,
    );
  }
}

/// Plain bordered box holding rows split by hairlines; one muted line
/// when empty.
class RefList extends StatelessWidget {
  const RefList({required this.children, required this.empty, super.key});

  final List<Widget> children;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          empty,
          textAlign: TextAlign.center,
          style: AtelierType.caption(p.muted, size: 12),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: p.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Referral code, email and link with copy, plus share.
class RefInviteBar extends StatelessWidget {
  const RefInviteBar({required this.profile, super.key});

  final ReferenceProfile profile;

  Future<void> _share(BuildContext anchor) async {
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

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final code = profile.referralCode.trim();
    final canShare = code.isNotEmpty || profile.shareRegisterUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        border: Border.all(color: p.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${context.tr(RemainingL10n.yourCode)}: ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 12),
                ),
              ),
              Expanded(
                flex: 3,
                child: _CopyText(
                  value: code,
                  label: 'Referral code',
                  style: AtelierType.label(
                    p.ink,
                    size: 15,
                  ).copyWith(letterSpacing: 1.5),
                ),
              ),
              Builder(
                builder: (anchor) => IconButton(
                  tooltip: 'Share',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.ios_share_rounded, size: 18, color: p.gold),
                  onPressed: canShare ? () => _share(anchor) : null,
                ),
              ),
            ],
          ),
          _CopyText(
            value: profile.email,
            label: context.tr(RemainingL10n.yourEmail),
            icon: Icons.alternate_email_rounded,
          ),
          _CopyText(
            value: profile.shareRegisterUrl,
            label: context.tr(RemainingL10n.shareLink),
            icon: Icons.link_rounded,
          ),
        ],
      ),
    );
  }
}

class _CopyText extends StatelessWidget {
  const _CopyText({
    required this.value,
    required this.label,
    this.icon,
    this.style,
  });

  final String value;
  final String label;
  final IconData? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final v = value.trim();
    return InkWell(
      onTap: v.isEmpty
          ? null
          : () async {
              await atelierCopy(v);
              if (context.mounted) showAtelierToast(context, '$label copied');
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: p.muted),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                v.isEmpty ? '—' : v,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style ?? AtelierType.caption(p.inkSoft, size: 12),
              ),
            ),
            if (v.isNotEmpty) ...[
              const SizedBox(width: 5),
              Icon(Icons.copy_rounded, size: 13, color: p.gold),
            ],
          ],
        ),
      ),
    );
  }
}

/// Who referred you, as one tappable line; opens [showRefSponsorSheet].
class RefSponsorRow extends StatelessWidget {
  const RefSponsorRow({required this.profile, required this.onOpen, super.key});

  final ReferenceProfile? profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final active = profile?.activeOutbound;
    final name = active?.party?.nameDotEmail ?? active?.partyLabel;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AtelierRadius.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${context.tr(RemainingL10n.myReference2).trim()}: ',
                      style: AtelierType.caption(p.muted, size: 12),
                    ),
                    TextSpan(
                      text: active == null ? 'None — add' : name!,
                      style: AtelierType.label(
                        active == null ? p.gold : p.ink,
                        size: 13,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (active != null) ...[
              const SizedBox(width: 5),
              Text(
                active.status.label,
                style: AtelierType.label(
                  refStatusColor(p, active.status),
                  size: 11.5,
                ),
              ),
            ],
            Icon(Icons.chevron_right_rounded, color: p.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Name, then email · date on one line; status at the end when shown.
class RefPersonRow extends StatelessWidget {
  const RefPersonRow({
    required this.request,
    this.showStatus = false,
    super.key,
  });

  final ReferenceRequest request;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final party = request.party;
    final name = party?.displayName ?? request.partyLabel;
    final email = party?.email.trim() ?? '';
    final when = _clean(request.acceptedAtLabel ?? request.createdAtLabel);
    final meta = [
      if (email.isNotEmpty && email != name) email,
      when,
    ].where((e) => e.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink, size: 13),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.caption(p.muted, size: 11),
                  ),
              ],
            ),
          ),
          if (showStatus) ...[
            const SizedBox(width: 6),
            Text(
              request.status.label,
              style: AtelierType.label(
                refStatusColor(p, request.status),
                size: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pending request with inline reject / accept.
class RefRequestRow extends StatelessWidget {
  const RefRequestRow({
    required this.request,
    required this.busy,
    required this.onDecide,
    super.key,
  });

  final ReferenceRequest request;
  final bool busy;
  final void Function({required bool accept}) onDecide;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Row(
      children: [
        Expanded(child: RefPersonRow(request: request)),
        IconButton(
          tooltip: context.tr(RemainingL10n.reject),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, size: 20, color: p.ruby),
          onPressed: busy ? null : () => onDecide(accept: false),
        ),
        if (busy)
          SizedBox(
            width: 40,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: p.gold,
                ),
              ),
            ),
          )
        else
          IconButton(
            tooltip: context.tr(RemainingL10n.accept),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.check_rounded, size: 20, color: p.emerald),
            onPressed: () => onDecide(accept: true),
          ),
      ],
    );
  }
}

/// Commission ledger: range filter, one-line net summary, dense rows.
class RefEarnings extends StatefulWidget {
  const RefEarnings({
    required this.purchases,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.onRetry,
    required this.onLoadMore,
    this.error,
    super.key,
  });

  final List<ReferencePurchase> purchases;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  State<RefEarnings> createState() => _RefEarningsState();
}

class _RefEarningsState extends State<RefEarnings> {
  RefRange _range = RefRange.all;
  DateTimeRange? _custom;

  List<ReferencePurchase> get _filtered {
    final now = DateTime.now().toUtc();
    DateTime start;
    DateTime? end;
    switch (_range) {
      case RefRange.all:
        return widget.purchases;
      case RefRange.d7:
        start = now.subtract(const Duration(days: 7));
      case RefRange.d15:
        start = now.subtract(const Duration(days: 15));
      case RefRange.d30:
        start = now.subtract(const Duration(days: 30));
      case RefRange.custom:
        final c = _custom;
        if (c == null) return widget.purchases;
        start = DateTime(c.start.year, c.start.month, c.start.day).toUtc();
        end = DateTime(c.end.year, c.end.month, c.end.day, 23, 59, 59).toUtc();
    }
    return [
      for (final p in widget.purchases)
        if (p.commissionAt == null ||
            (!p.commissionAt!.toUtc().isBefore(start) &&
                (end == null || !p.commissionAt!.toUtc().isAfter(end))))
          p,
    ];
  }

  Future<void> _onRange(RefRange range) async {
    if (range != RefRange.custom) {
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
      _range = RefRange.custom;
      _custom = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final all = widget.purchases;
    if (widget.loading && all.isEmpty) {
      return const AtelierSkeletonList(count: 4, height: 48);
    }
    if (widget.error != null && all.isEmpty) {
      return AtelierErrorState(
        compact: true,
        title: 'Earnings unavailable',
        message: widget.error!,
        onRetry: widget.onRetry,
      );
    }
    final filtered = _filtered;
    final net = filtered.fold<double>(0, (s, e) => s + e.commissionInr);
    final reversed = filtered.where((e) => e.commissionInr < 0).length;
    final custom = _custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtelierSegmented<RefRange>(
          dense: true,
          segments: [
            for (final r in RefRange.values)
              AtelierSegment(
                value: r,
                label: r == RefRange.custom && custom != null
                    ? '${atelierDate(custom.start)} – ${atelierDate(custom.end)}'
                    : r.label,
              ),
          ],
          selected: _range,
          onChanged: _onRange,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Net ${atelierMoney(net, symbol: '₹', decimals: 2)}',
                  style: AtelierType.label(net < 0 ? p.ruby : p.emerald),
                ),
                TextSpan(
                  text:
                      ' · ${filtered.length} '
                      '${filtered.length == 1 ? 'order' : 'orders'}'
                      '${reversed > 0 ? ' · $reversed reversed' : ''}',
                  style: AtelierType.caption(p.muted, size: 12),
                ),
              ],
            ),
          ),
        ),
        RefList(
          empty: context.tr(RemainingL10n.noCommissionPurchases),
          children: [for (final e in filtered) RefEarningRow(purchase: e)],
        ),
        if (all.isNotEmpty)
          if (widget.loadingMore)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: p.gold,
                  ),
                ),
              ),
            )
          else if (widget.error != null)
            TextButton(
              onPressed: widget.onLoadMore,
              child: Text(
                '${widget.error} · ${context.tr(RemainingL10n.retry)}',
                style: AtelierType.caption(p.ruby, size: 12),
              ),
            )
          else if (widget.hasMore)
            TextButton(
              onPressed: widget.onLoadMore,
              child: Text(
                context.tr(RemainingL10n.loadMore),
                style: AtelierType.label(p.gold, size: 12),
              ),
            ),
      ],
    );
  }
}

/// Buyer, signed amount; then type · status · date · items.
class RefEarningRow extends StatelessWidget {
  const RefEarningRow({required this.purchase, super.key});

  final ReferencePurchase purchase;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final reversed = purchase.commissionInr < 0;
    final meta = [
      if (reversed) 'Reversed (seller rejected)',
      if (purchase.metaLabel.isNotEmpty) purchase.metaLabel,
      if (purchase.createdAtLabel.trim().isNotEmpty) purchase.createdAtLabel,
      for (final item in purchase.items) item.lineLabel,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.buyerLabel ?? purchase.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink, size: 13),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.caption(
                      reversed ? p.ruby : p.muted,
                      size: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            purchase.signedAmountLabel,
            style: AtelierType.label(reversed ? p.ruby : p.emerald, size: 13),
          ),
        ],
      ),
    );
  }
}

/// Sheet for your own reference: current link, or a form to request one,
/// plus earlier requests.
Future<void> showRefSponsorSheet(BuildContext context) {
  return showAtelierSheet<void>(
    context: context,
    title: context.tr(RemainingL10n.myReference2),
    builder: (_) => const _SponsorSheetBody(),
  );
}

class _SponsorSheetBody extends ConsumerStatefulWidget {
  const _SponsorSheetBody();

  @override
  ConsumerState<_SponsorSheetBody> createState() => _SponsorSheetBodyState();
}

class _SponsorSheetBodyState extends ConsumerState<_SponsorSheetBody> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (_busy) return;
    if (value.isEmpty) {
      AppHaptics.error();
      setState(() => _error = 'Enter an email or referral code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(referenceHubProvider.notifier).request(value);
    if (!mounted) return;
    switch (result) {
      case Success():
        AppHaptics.success();
        _controller.clear();
        setState(() => _busy = false);
        showAtelierToast(
          context,
          context.tr(RemainingL10n.referenceSent),
          tone: AtelierTone.emerald,
        );
      case ResultFailure(:final failure):
        AppHaptics.error();
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final profile = ref.watch(referenceHubProvider.select((s) => s.profile));
    final active = profile?.activeOutbound;
    final history = profile?.outboundHistory ?? const <ReferenceRequest>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active != null)
          RefList(
            empty: '',
            children: [RefPersonRow(request: active, showStatus: true)],
          )
        else ...[
          AtelierTextField(
            controller: _controller,
            label: 'Email or referral code',
            hint: context.tr(RemainingL10n.emailReferralCode),
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          AtelierButton(
            label: context.tr(RemainingL10n.request),
            compact: true,
            expand: true,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${context.tr(RemainingL10n.requestHistory)} (${history.length})',
            style: AtelierType.caption(p.muted, size: 12),
          ),
          const SizedBox(height: 4),
          RefList(
            empty: '',
            children: [
              for (final r in history)
                RefPersonRow(request: r, showStatus: true),
            ],
          ),
        ],
        const SizedBox(height: 6),
      ],
    );
  }
}
