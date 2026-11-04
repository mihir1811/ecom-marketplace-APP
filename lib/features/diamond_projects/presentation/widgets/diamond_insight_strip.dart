import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../comparison/presentation/widgets/compare_add_button.dart';
import '../../../diamonds/application/diamond_list_provider.dart';
import '../../../diamonds/application/diamond_search_provider.dart';
import '../../../diamonds/domain/models/diamond.dart';
import '../../../diamonds/domain/models/diamond_catalog_type.dart';
import '../../../diamonds/domain/models/diamond_listing_summary_stats.dart';
import '../../application/diamond_inventory_loader.dart';
import '../../application/diamond_project_listing_pick_provider.dart';
import '../../application/diamond_project_selection_provider.dart';
import '../../application/diamond_selection.dart';

/// Height of [DiamondInsightStrip], for the pinned header's extent.
const double kDiamondInsightStripHeight = _kHeaderHeight + 4 + _kCardHeight;

const double _kHeaderHeight = 20;
const double _kCardHeight = 36;

const double _kCardRadius = 10;

/// Loads the whole matching inventory on demand, with a busy flag and a
/// cancel on dispose.
mixin _InventoryLoad<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;
  CancelToken? _token;

  @override
  void dispose() {
    _token?.cancel('diamond-inventory-left');
    super.dispose();
  }

  /// Null when it failed (a snackbar says so) or the page went away.
  Future<List<Diamond>?> loadInventory() async {
    if (busy) return null;
    setState(() => busy = true);
    final token = _token = CancelToken();
    final result = await DiamondInventoryLoader.loadAll(
      ref,
      cancelToken: token,
    );
    if (!mounted) return null;
    setState(() => busy = false);
    switch (result) {
      case Success(value: final all):
        return all;
      case ResultFailure():
        AppHaptics.warning();
        showCompareFeedback(
          context,
          context.tr(AccountCommerceL10n.projectLoadFailed),
        );
        return null;
    }
  }
}

/// Slim, pinned summary of the listing for buyers and sellers alike.
///
/// A slim caption row — the scope ("24 of 1,284", or "12 selected" with a
/// clear button) on the left, Select all (every matching stone in the
/// inventory, not only the loaded pages) on the right — over the KPIs of
/// that scope, which share the full width as small cards.
class DiamondInsightStrip extends ConsumerStatefulWidget {
  const DiamondInsightStrip({super.key});

  @override
  ConsumerState<DiamondInsightStrip> createState() =>
      _DiamondInsightStripState();
}

class _DiamondInsightStripState extends ConsumerState<DiamondInsightStrip>
    with _InventoryLoad {
  Future<void> _selectAll() async {
    AppHaptics.selection();
    final all = await loadInventory();
    if (all == null || all.isEmpty || !mounted) return;
    DiamondSelection.selectAll(ref, all);
    AppHaptics.medium();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final list = ref.watch(diamondListProvider).value;
    final loaded = list?.diamonds ?? const <Diamond>[];
    final settled = list != null && !list.isInitialLoading;
    final total = settled ? list.totalCount : 0;
    final picks = ref.watch(
      diamondProjectListingPickProvider.select((s) => s.length),
    );
    final picked = ref.watch(pickedDiamondsProvider);
    final selecting = picks > 0;
    final stats = DiamondListingSummaryStats.fromDiamonds(
      selecting ? picked : loaded,
    );
    final canSelectAll = settled && total > 0 && picks < total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: kDiamondInsightStripHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _kHeaderHeight,
              child: Row(
                children: [
                  Expanded(
                    child: _Scope(
                      selected: picks,
                      shown: loaded.length,
                      total: total,
                      settled: settled,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: LuxeMotion.fast,
                    child: canSelectAll || busy
                        ? _SelectAll(busy: busy, onTap: _selectAll)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: _kCardHeight,
              child: AnimatedSwitcher(
                duration: LuxeMotion.fast,
                child: Row(
                  key: ValueKey(stats.isEmpty),
                  children: stats.isEmpty
                      ? [
                          Expanded(
                            child: _StatCard(
                              child: Text(
                                '—',
                                style: LuxeType.figure(p.inkFaint, size: 12),
                              ),
                            ),
                          ),
                        ]
                      : _kpis(context, stats, p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _kpis(
    BuildContext context,
    DiamondListingSummaryStats s,
    LuxePalette p,
  ) {
    final items = [
      (CatalogL10n.totalCtShort, '${s.totalCarat.toStringAsFixed(2)} ct'),
      (
        CatalogL10n.pricePerCtShort,
        AppCurrency.format(_compact(s.pricePerCarat)),
      ),
      (CatalogL10n.total, AppCurrency.format(_compact(s.totalPrice))),
      (CatalogL10n.averageTotal, AppCurrency.format(_compact(s.avgTotal))),
    ];
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 5),
        Expanded(
          child: _StatCard(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(items[i].$1),
                    maxLines: 1,
                    style: LuxeType.label(
                      p.inkMuted,
                      size: 9,
                    ).copyWith(letterSpacing: 0.6, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].$2,
                    maxLines: 1,
                    style: LuxeType.figure(
                      p.ink,
                      size: 12.5,
                    ).copyWith(fontWeight: FontWeight.w600, height: 1.15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ];
  }

  /// 76,620,000 → 76.6M, 412,000 → 412K, 41,200 → 41.2K, 4,210 → 4,210.
  static String _compact(double v) {
    String trim(String s) =>
        s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
    final a = v.abs();
    if (a >= 1e6) return '${trim((v / 1e6).toStringAsFixed(1))}M';
    if (a >= 1e5) return '${(v / 1e3).round()}K';
    if (a >= 1e4) return '${trim((v / 1e3).toStringAsFixed(1))}K';
    return formatGroupedWhole(v.roundToDouble());
  }
}

/// One centred card of the strip.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      height: _kCardHeight,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: p.hairline, width: 0.6),
      ),
      child: child,
    );
  }
}

/// Left caption: "24 of 1,284" while nothing is picked; an accent
/// "12 selected ×" once something is.
class _Scope extends ConsumerWidget {
  const _Scope({
    required this.selected,
    required this.shown,
    required this.total,
    required this.settled,
  });

  final int selected;
  final int shown;
  final int total;
  final bool settled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final active = selected > 0;
    final text = active
        ? context.tr(AccountCommerceL10n.projectSelectedCount, {
            'count': formatGroupedWhole(selected.toDouble()),
          })
        : settled
        ? context.tr(AccountCommerceL10n.projectShown, {
            'shown': formatGroupedWhole(shown.toDouble()),
            'total': formatGroupedWhole(total.toDouble()),
          })
        : context.tr(DiamondFlowL10n.searching);
    final ink = active ? p.accent : p.inkMuted;

    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LuxeType.label(
              ink,
              size: 11.5,
            ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
          ),
        ),
        if (active)
          Semantics(
            button: true,
            label: context.tr(AccountCommerceL10n.projectClear),
            excludeSemantics: true,
            child: Tooltip(
              message: context.tr(AccountCommerceL10n.projectClear),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.medium();
                  DiamondSelection.clearPicks(ref);
                },
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accent.withValues(alpha: 0.14),
                  ),
                  child: Icon(Icons.close_rounded, size: 11, color: ink),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Right caption: picks every matching stone, with a
/// spinner while the inventory loads.
class _SelectAll extends StatelessWidget {
  const _SelectAll({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final label = context.tr(AccountCommerceL10n.projectSelectAll);
    return Semantics(
      button: true,
      label: busy ? context.tr(AccountCommerceL10n.projectSelecting) : label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 13,
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: p.accent,
                        ),
                      )
                    : Icon(Icons.done_all_rounded, size: 13, color: p.accent),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: LuxeType.label(
                  p.accent,
                  size: 11.5,
                ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seller-only link in the listing toolbar: opens the diamond project
/// (detailed analytics) for the picked stones, or for every matching stone
/// when nothing is picked.
class DiamondAnalyticsLink extends ConsumerStatefulWidget {
  const DiamondAnalyticsLink({super.key});

  @override
  ConsumerState<DiamondAnalyticsLink> createState() =>
      _DiamondAnalyticsLinkState();
}

class _DiamondAnalyticsLinkState extends ConsumerState<DiamondAnalyticsLink>
    with _InventoryLoad {
  Future<void> _open() async {
    AppHaptics.selection();
    final picks = ref.read(diamondProjectListingPickProvider);
    List<Diamond>? diamonds;
    if (picks.isEmpty) {
      diamonds = await loadInventory();
    } else {
      // Stones picked elsewhere (compare, detail) may only be known from
      // the loaded page.
      final known = {for (final d in ref.read(pickedDiamondsProvider)) d.id: d};
      for (final d
          in ref.read(diamondListProvider).value?.diamonds ??
              const <Diamond>[]) {
        if (picks.contains(d.id)) known.putIfAbsent(d.id, () => d);
      }
      diamonds = known.values.toList(growable: false);
    }
    if (diamonds == null || diamonds.isEmpty || !mounted) return;

    ref
        .read(diamondProjectSelectionProvider.notifier)
        .selectLoadedPage(
          diamonds: diamonds,
          filters: ref.read(diamondSearchProvider),
          catalog: ref.read(diamondCatalogTypeProvider),
        );
    GoRouter.of(context).push(AppRouteNames.diamondProject);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(canAnalyzeDiamondsProvider)) return const SizedBox.shrink();
    final p = LuxePalette.of(context);
    final hint = context.tr(AccountCommerceL10n.projectAnalyticsHint);

    return Tooltip(
      message: hint,
      child: Semantics(
        button: true,
        label: hint,
        excludeSemantics: true,
        child: Material(
          color: p.accentSoft,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: busy ? null : _open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(AccountCommerceL10n.projectAnalytics),
                    style: LuxeType.label(
                      p.accent,
                      size: 12.5,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  SizedBox.square(
                    dimension: 16,
                    child: busy
                        ? Padding(
                            padding: const EdgeInsets.all(2),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: p.accent,
                            ),
                          )
                        : Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: p.accent,
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
