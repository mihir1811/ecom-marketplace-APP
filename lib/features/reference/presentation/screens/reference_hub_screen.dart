import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_currency.dart';
import '../../application/reference_providers.dart';
import '../../domain/models/reference_models.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_dialog.dart';

enum _ReferenceMetricTab { accepted, pending, commission }

/// Shared buyer/seller hub for referral code, inbound/outbound, and purchases.
class ReferenceHubScreen extends ConsumerStatefulWidget {
  const ReferenceHubScreen({super.key});

  @override
  ConsumerState<ReferenceHubScreen> createState() => _ReferenceHubScreenState();
}

class _ReferenceHubScreenState extends ConsumerState<ReferenceHubScreen> {
  _ReferenceMetricTab _tab = _ReferenceMetricTab.accepted;
  final _requestController = TextEditingController();
  bool _requestBusy = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceHubProvider);
    final profile = state.profile;

    return RefreshIndicator(
      onRefresh: () => ref.read(referenceHubProvider.notifier).refresh(),
      child: state.isLoading && profile == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : state.errorMessage != null && profile == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.s24),
              children: [
                Text(state.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s16),
                Center(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(referenceHubProvider.notifier).refresh(),
                    child: Text(context.tr(RemainingL10n.retry)),
                  ),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (_tab == _ReferenceMetricTab.commission &&
                    n is ScrollUpdateNotification &&
                    n.metrics.maxScrollExtent > 0 &&
                    n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                  ref.read(referenceHubProvider.notifier).loadMorePurchases();
                }
                return false;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s24,
                  AppSpacing.s12,
                  AppSpacing.s24,
                  AppSpacing.s40,
                ),
                children: [
                  Text(
                    context.tr(RemainingL10n.myReference),
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    context.tr(RemainingL10n.referenceIntro),
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _MetricRow(
                    selected: _tab,
                    acceptedCount: profile?.inboundAcceptedCount ?? 0,
                    pendingCount: profile?.inboundPendingCount ?? 0,
                    commission: profile?.totalCommissionEarned ?? 0,
                    onSelect: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _TabPanel(
                    tab: _tab,
                    inbound: state.inbound,
                    purchases: state.purchases,
                    isLoadingMore: state.isLoadingMorePurchases,
                    isLoadingPurchases: state.isLoadingPurchases,
                    purchasesError: state.purchasesError,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  if (profile != null) _ShareCard(profile: profile),
                  const SizedBox(height: AppSpacing.s16),
                  _MyReferenceCard(
                    profile: profile,
                    requestController: _requestController,
                    requestBusy: _requestBusy,
                    onSubmitRequest: _submitRequest,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submitRequest() async {
    final value = _requestController.text.trim();
    if (value.isEmpty || _requestBusy) return;
    setState(() => _requestBusy = true);
    final result = await ref.read(referenceHubProvider.notifier).request(value);
    if (!mounted) return;
    setState(() => _requestBusy = false);
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        _requestController.clear();
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr(RemainingL10n.referenceSent))),
        );
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.selected,
    required this.acceptedCount,
    required this.pendingCount,
    required this.commission,
    required this.onSelect,
  });

  final _ReferenceMetricTab selected;
  final int acceptedCount;
  final int pendingCount;
  final double commission;
  final ValueChanged<_ReferenceMetricTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        label: context.tr(RemainingL10n.accepted),
        value: '$acceptedCount',
        icon: Icons.people_outline,
        selected: selected == _ReferenceMetricTab.accepted,
        onTap: () => onSelect(_ReferenceMetricTab.accepted),
      ),
      _MetricCard(
        label: context.tr(RemainingL10n.pending),
        value: '$pendingCount',
        icon: Icons.schedule_outlined,
        selected: selected == _ReferenceMetricTab.pending,
        onTap: () => onSelect(_ReferenceMetricTab.pending),
      ),
      _MetricCard(
        label: context.tr(RemainingL10n.commission),
        value: AppCurrency.inr(commission, decimals: 0),
        icon: Icons.currency_rupee,
        selected: selected == _ReferenceMetricTab.commission,
        onTap: () => onSelect(_ReferenceMetricTab.commission),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s8),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.bronze : AppColors.border(context);
    final fill = selected
        ? AppColors.bronze.withValues(
            alpha: AppColors.isDark(context) ? 0.16 : 0.06,
          )
        : AppColors.card(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppSpacing.r16),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: AppColors.isDark(context) ? null : AppShadows.cardLight,
          ),
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.bronze.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppSpacing.r12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 14, color: AppColors.bronzeDark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPanel extends ConsumerWidget {
  const _TabPanel({
    required this.tab,
    required this.inbound,
    required this.purchases,
    required this.isLoadingMore,
    required this.isLoadingPurchases,
    this.purchasesError,
  });

  final _ReferenceMetricTab tab;
  final List<ReferenceRequest> inbound;
  final List<ReferencePurchase> purchases;
  final bool isLoadingMore;
  final bool isLoadingPurchases;
  final String? purchasesError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (tab) {
      _ReferenceMetricTab.accepted => _SectionCard(
        title: context.tr(RemainingL10n.acceptedReferences),
        child: _buildAccepted(context),
      ),
      _ReferenceMetricTab.pending => _SectionCard(
        title: context.tr(RemainingL10n.requestsToAccept),
        child: _buildPending(context, ref),
      ),
      _ReferenceMetricTab.commission => _SectionCard(
        title: context.tr(RemainingL10n.referralPurchases),
        subtitle: context.tr(RemainingL10n.diamondAndMeleeOrdersThatEarned),
        child: _PurchasesPanel(
          purchases: purchases,
          isLoadingMore: isLoadingMore,
          isLoadingPurchases: isLoadingPurchases,
          purchasesError: purchasesError,
        ),
      ),
    };
  }

  Widget _buildAccepted(BuildContext context) {
    final items = inbound
        .where((r) => r.status == ReferenceStatus.accepted)
        .toList(growable: false);
    if (items.isEmpty) {
      return _EmptyNote(context.tr(RemainingL10n.noAcceptedReferences));
    }
    return Column(
      children: [
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: _PersonRow(
              title: r.party?.nameDotEmail ?? r.partyLabel,
              trailing: r.status.label,
            ),
          ),
      ],
    );
  }

  Widget _buildPending(BuildContext context, WidgetRef ref) {
    final items = inbound
        .where((r) => r.status == ReferenceStatus.pending)
        .toList(growable: false);
    if (items.isEmpty) {
      return _EmptyNote(context.tr(RemainingL10n.noPendingRequests));
    }
    return Column(
      children: [
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: _PendingRequestCard(request: r),
          ),
      ],
    );
  }
}

enum _PurchaseRange { all, d7, d15, d30, custom }

class _PurchasesPanel extends ConsumerStatefulWidget {
  const _PurchasesPanel({
    required this.purchases,
    required this.isLoadingMore,
    required this.isLoadingPurchases,
    this.purchasesError,
  });

  final List<ReferencePurchase> purchases;
  final bool isLoadingMore;
  final bool isLoadingPurchases;
  final String? purchasesError;

  @override
  ConsumerState<_PurchasesPanel> createState() => _PurchasesPanelState();
}

class _PurchasesPanelState extends ConsumerState<_PurchasesPanel> {
  _PurchaseRange _range = _PurchaseRange.all;
  DateTime? _customStart;
  DateTime? _customEnd;

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
        if (_customStart == null || _customEnd == null) {
          return widget.purchases;
        }
        start = DateTime(
          _customStart!.year,
          _customStart!.month,
          _customStart!.day,
        ).toUtc();
        end = DateTime(
          _customEnd!.year,
          _customEnd!.month,
          _customEnd!.day,
          23,
          59,
          59,
        ).toUtc();
    }

    return widget.purchases
        .where((p) {
          final at = p.commissionAt?.toUtc();
          if (at == null) return true;
          if (start != null && at.isBefore(start)) return false;
          if (end != null && at.isAfter(end)) return false;
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _onSelectRange(_PurchaseRange range) async {
    if (range != _PurchaseRange.custom) {
      setState(() => _range = range);
      return;
    }
    final picked = await _pickCustomDateRange();
    if (picked == null) return;
    setState(() {
      _range = _PurchaseRange.custom;
      _customStart = picked.$1;
      _customEnd = picked.$2;
    });
  }

  Future<(DateTime, DateTime)?> _pickCustomDateRange() async {
    DateTime? start = _customStart;
    DateTime? end = _customEnd;
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 1));

    return showAppDialog<(DateTime, DateTime)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStart() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: start ?? DateTime.now(),
                firstDate: firstDate,
                lastDate: end ?? lastDate,
                helpText: context.tr(RemainingL10n.selectStartDate),
              );
              if (picked == null) return;
              setDialogState(() {
                start = picked;
                if (end != null && end!.isBefore(picked)) {
                  end = null;
                }
              });
            }

            Future<void> pickEnd() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: end ?? start ?? DateTime.now(),
                firstDate: start ?? firstDate,
                lastDate: lastDate,
                helpText: context.tr(RemainingL10n.selectEndDate),
              );
              if (picked == null) return;
              setDialogState(() => end = picked);
            }

            String fmt(DateTime? d) {
              if (d == null) return '—';
              String two(int v) => v.toString().padLeft(2, '0');
              return '${two(d.month)}/${two(d.day)}/${d.year}';
            }

            return AlertDialog(
              backgroundColor: AppColors.card(context),
              title: Text(
                context.tr(RemainingL10n.customDateRange),
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr(RemainingL10n.startDate)),
                      subtitle: Text(fmt(start)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: pickStart,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr(RemainingL10n.endDate)),
                      subtitle: Text(fmt(end)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: pickEnd,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.tr(RemainingL10n.cancel)),
                ),
                FilledButton(
                  onPressed: start != null && end != null
                      ? () => Navigator.of(dialogContext).pop((start!, end!))
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.warmWhite,
                  ),
                  child: Text(context.tr(RemainingL10n.apply)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final customLabel = (_range == _PurchaseRange.custom &&
            _customStart != null &&
            _customEnd != null)
        ? '${_fmtDate(_customStart!)} → ${_fmtDate(_customEnd!)}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _PurchaseRange.values.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.s8),
                _RangeChip(
                  label: switch (_PurchaseRange.values[i]) {
                    _PurchaseRange.all => 'All time',
                    _PurchaseRange.d7 => '7 days',
                    _PurchaseRange.d15 => '15 days',
                    _PurchaseRange.d30 => '30 days',
                    _PurchaseRange.custom => 'Custom',
                  },
                  selected: _range == _PurchaseRange.values[i],
                  onTap: () => _onSelectRange(_PurchaseRange.values[i]),
                ),
              ],
            ],
          ),
        ),
        if (customLabel != null) ...[
          const SizedBox(height: AppSpacing.s8),
          Text(
            customLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        if (widget.isLoadingPurchases && widget.purchases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.purchasesError != null && widget.purchases.isEmpty)
          Column(
            children: [
              _EmptyNote(widget.purchasesError!),
              const SizedBox(height: AppSpacing.s12),
              FilledButton(
                onPressed: () =>
                    ref.read(referenceHubProvider.notifier).refresh(),
                child: Text(context.tr(RemainingL10n.retry)),
              ),
            ],
          )
        else if (filtered.isEmpty)
          _EmptyNote(context.tr(RemainingL10n.noCommissionPurchases))
        else ...[
          for (final p in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: _PurchaseRow(purchase: p),
            ),
          if (widget.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  static String _fmtDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.month)}/${two(d.day)}/${d.year}';
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.bronze.withValues(alpha: 0.18),
      labelStyle: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        height: 1.1,
        color: selected
            ? AppColors.bronze
            : AppColors.textSecondary(context),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      side: BorderSide(
        color: selected ? AppColors.bronze : AppColors.border(context),
      ),
      backgroundColor: AppColors.card(context),
      showCheckmark: false,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PendingRequestCard extends ConsumerWidget {
  const _PendingRequestCard({required this.request});

  final ReferenceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            request.party?.nameWithEmail ?? request.partyLabel,
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            context.tr(RemainingL10n.requestedDate, {
              'date': request.createdAtLabel,
            }),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await ref
                        .read(referenceHubProvider.notifier)
                        .reject(request.id);
                    if (!context.mounted) return;
                    _toast(
                      context,
                      result,
                      context.tr(RemainingL10n.requestRejected),
                    );
                  },
                  child: Text(context.tr(RemainingL10n.reject)),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final result = await ref
                        .read(referenceHubProvider.notifier)
                        .accept(request.id);
                    if (!context.mounted) return;
                    _toast(
                      context,
                      result,
                      context.tr(RemainingL10n.requestAccepted),
                    );
                  },
                  child: Text(context.tr(RemainingL10n.accept)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toast(
    BuildContext context,
    Result<ReferenceRequest, Failure> result,
    String ok,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success():
        messenger.showSnackBar(SnackBar(content: Text(ok)));
      case ResultFailure(failure: final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.purchase});

  final ReferencePurchase purchase;

  @override
  Widget build(BuildContext context) {
    final amountColor = purchase.commissionInr < 0
        ? AppColors.terracotta
        : const Color(0xFF2E7D4F);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.buyerLabel ?? purchase.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      purchase.metaLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                purchase.signedAmountLabel,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ],
          ),
          if (purchase.commissionInr < 0) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Commission reversed (seller rejected the order)',
              style: AppTypography.caption.copyWith(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (purchase.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            for (final item in purchase.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  item.lineLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.profile});

  final ReferenceProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.tr(RemainingL10n.shareReference),
      titleIcon: Icons.person_add_alt_1_outlined,
      subtitle: context.tr(RemainingL10n.othersCanUseYourEmailOrCode),
      child: Column(
        children: [
          _CopyField(
            label: context.tr(RemainingL10n.yourEmail),
            value: profile.email,
          ),
          const SizedBox(height: AppSpacing.s12),
          _CopyField(
            label: context.tr(RemainingL10n.yourCode),
            value: profile.referralCode,
          ),
          const SizedBox(height: AppSpacing.s12),
          _CopyField(
            label: context.tr(RemainingL10n.shareLink),
            value: profile.shareRegisterUrl,
          ),
        ],
      ),
    );
  }
}

class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Text(
                  value.isEmpty ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            OutlinedButton.icon(
              onPressed: value.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$label copied')));
                    },
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: Text(context.tr(RemainingL10n.copy)),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyReferenceCard extends StatelessWidget {
  const _MyReferenceCard({
    required this.profile,
    required this.requestController,
    required this.requestBusy,
    required this.onSubmitRequest,
  });

  final ReferenceProfile? profile;
  final TextEditingController requestController;
  final bool requestBusy;
  final VoidCallback onSubmitRequest;

  @override
  Widget build(BuildContext context) {
    final active = profile?.activeOutbound;
    final history = profile?.outboundHistory ?? const <ReferenceRequest>[];

    return _SectionCard(
      title: context.tr(RemainingL10n.myReference2),
      titleIcon: Icons.person_add_alt_1_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.r12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                      ),
                      children: [
                        TextSpan(
                          text: context.tr(RemainingL10n.referrer),
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              active.party?.nameWithEmail ?? active.partyLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary(context),
                      ),
                      children: [
                        TextSpan(
                          text: context.tr(RemainingL10n.status),
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: active.status.label),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              context.tr(RemainingL10n.addSomeoneAsYourReferenceUsingTheir),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: requestController,
                    enabled: !requestBusy,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmitRequest(),
                    decoration: InputDecoration(
                      hintText: context.tr(RemainingL10n.emailReferralCode),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                FilledButton(
                  onPressed: requestBusy ? null : onSubmitRequest,
                  child: requestBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr(RemainingL10n.request)),
                ),
              ],
            ),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s20),
            Text(
              context.tr(RemainingL10n.requestHistory),
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final item in history)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: _PersonRow(
                  title: item.party?.nameDotEmail ?? item.partyLabel,
                  trailing: item.status.label,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Text(
          trailing,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.titleIcon,
  });

  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppColors.isDark(context) ? null : AppShadows.cardLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 18, color: AppColors.bronze),
                const SizedBox(width: AppSpacing.s8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              subtitle!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: AppColors.textMuted(context),
        fontSize: 14,
      ),
    );
  }
}
