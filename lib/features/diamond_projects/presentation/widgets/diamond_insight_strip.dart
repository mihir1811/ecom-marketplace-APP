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
const double kDiamondInsightStripHeight = 34;

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
/// One 34 px capsule under the toolbar: the scope ("24 of 1,284", or
/// "12 selected" with a clear button), the KPIs of that scope scrolling
/// sideways, and Select all — which picks every matching stone in the
/// inventory, not only the loaded pages.
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
    final list = ref.watch(diamondListProvider).valueOrNull;
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

    return Container(
      height: kDiamondInsightStripHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(left: 4, right: 4),
      decoration: ShapeDecoration(
        color: p.surface.withValues(alpha: 0.72),
        shape: StadiumBorder(side: BorderSide(color: p.hairline, width: 0.6)),
      ),
      child: Row(
        children: [
          _Scope(
            selected: picks,
            shown: loaded.length,
            total: total,
            settled: settled,
          ),
          Expanded(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0, 0.05, 0.92, 1],
              ).createShader(r),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AnimatedSwitcher(
                  duration: LuxeMotion.fast,
                  child: Row(
                    key: ValueKey(stats.isEmpty),
                    children: stats.isEmpty
                        ? [
                            Text(
                              '—',
                              style: LuxeType.figure(p.inkFaint, size: 12),
                            ),
                          ]
                        : _kpis(context, stats, p),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: LuxeMotion.fast,
            child: busy
                ? Semantics(
                    key: const ValueKey('busy'),
                    label: context.tr(AccountCommerceL10n.projectSelecting),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: p.accent,
                        ),
                      ),
                    ),
                  )
                : canSelectAll
                ? _StripAction(
                    key: const ValueKey('all'),
                    icon: Icons.done_all_rounded,
                    label: context.tr(AccountCommerceL10n.projectSelectAll),
                    onTap: _selectAll,
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ],
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
        if (i > 0)
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.inkFaint,
            ),
          ),
        Text(
          context.tr(items[i].$1),
          style: LuxeType.label(
            p.inkMuted,
            size: 9.5,
          ).copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(width: 5),
        Text(
          items[i].$2,
          style: LuxeType.figure(
            p.ink,
            size: 12.5,
          ).copyWith(fontWeight: FontWeight.w600),
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

/// "24 of 1,284" while nothing is picked; an accent "12 selected ×" pill
/// once something is.
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
    final ink = active ? p.onAccent : p.inkMuted;

    return AnimatedContainer(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      height: 26,
      padding: EdgeInsets.only(left: 10, right: active ? 2 : 10),
      decoration: ShapeDecoration(
        color: active ? p.accent : p.surfaceRaised,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: LuxeType.figure(
              ink,
              size: 11.5,
            ).copyWith(fontWeight: FontWeight.w600),
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
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.onAccent.withValues(alpha: 0.2),
                    ),
                    child: Icon(Icons.close_rounded, size: 13, color: ink),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StripAction extends StatelessWidget {
  const _StripAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: p.accent),
              const SizedBox(width: 4),
              Text(label, style: LuxeType.label(p.accent, size: 11.5)),
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
          in ref.read(diamondListProvider).valueOrNull?.diamonds ??
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
              padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
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
