import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../application/diamond_list_provider.dart';
import '../../domain/models/sorting_criteria.dart';

/// Multi-criteria sort sheet for diamond results.
///
/// Top to bottom: one-tap quick picks (a sideways strip), the user's sort
/// order when set (drag to change priority, flip each direction, remove),
/// and the fields still available to add. Nothing applies until "Show
/// results".
class DiamondSortingBottomSheet extends ConsumerStatefulWidget {
  const DiamondSortingBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final luxe = LuxeScope.isActive(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => luxe
          ? const LuxeScope(child: DiamondSortingBottomSheet())
          : const DiamondSortingBottomSheet(),
    );
  }

  @override
  ConsumerState<DiamondSortingBottomSheet> createState() =>
      _DiamondSortingBottomSheetState();
}

/// A one-tap sort recipe.
class _QuickPick {
  const _QuickPick(this.labelKey, this.icon, this.field, this.direction);

  final String labelKey;
  final IconData icon;
  final String field;
  final SortDirection direction;
}

const _quickPicks = [
  _QuickPick(
    CatalogL10n.sortPresetLowestPrice,
    Icons.south_rounded,
    'price',
    SortDirection.ascending,
  ),
  _QuickPick(
    CatalogL10n.sortPresetHighestPrice,
    Icons.north_rounded,
    'price',
    SortDirection.descending,
  ),
  _QuickPick(
    CatalogL10n.sortPresetBiggest,
    Icons.open_in_full_rounded,
    'carat',
    SortDirection.descending,
  ),
  _QuickPick(
    CatalogL10n.sortPresetBestValue,
    Icons.workspace_premium_outlined,
    'pricePerCarat',
    SortDirection.ascending,
  ),
];

IconData _fieldIcon(String key) => switch (key) {
  'price' => Icons.payments_outlined,
  'pricePerCarat' => Icons.balance_outlined,
  'carat' => Icons.scale_outlined,
  _ => Icons.sort_rounded,
};

String _fieldHint(BuildContext context, String key) => context.tr(switch (key) {
  'price' => CatalogL10n.sortPriceHint,
  'pricePerCarat' => CatalogL10n.sortPpcHint,
  _ => CatalogL10n.sortCaratHint,
});

/// Direction wording that matches the field: sizes grow, prices rise.
String _directionLabel(BuildContext context, String key, SortDirection d) {
  final size = key == 'carat';
  final asc = d == SortDirection.ascending;
  return context.tr(
    size
        ? (asc ? CatalogL10n.sortSmallToLarge : CatalogL10n.sortLargeToSmall)
        : (asc ? CatalogL10n.sortLowToHigh : CatalogL10n.sortHighToLow),
  );
}

class _DiamondSortingBottomSheetState
    extends ConsumerState<DiamondSortingBottomSheet> {
  late List<SortingCriteria> _order;

  static final _allowed = DiamondSortingFields.all.map((f) => f.key).toSet();

  @override
  void initState() {
    super.initState();
    _order =
        ([...ref.read(diamondSortingProvider)]
              ..sort((a, b) => a.priority.compareTo(b.priority)))
            .where((s) => _allowed.contains(s.fieldKey))
            .toList();
    _renumber();
  }

  void _renumber() {
    for (var i = 0; i < _order.length; i++) {
      _order[i] = _order[i].copyWith(priority: i + 1);
    }
  }

  List<SortingFieldDef> get _available {
    final used = _order.map((s) => s.fieldKey).toSet();
    return DiamondSortingFields.all
        .where((f) => !used.contains(f.key))
        .toList();
  }

  bool _isQuickPickActive(_QuickPick q) =>
      _order.length == 1 &&
      _order.first.fieldKey == q.field &&
      _order.first.direction == q.direction;

  void _applyQuickPick(_QuickPick q) {
    AppHaptics.selection();
    final def = DiamondSortingFields.findByKey(q.field);
    if (def == null) return;
    setState(() {
      _order = _isQuickPickActive(q)
          ? []
          : [
              SortingCriteria(
                fieldKey: def.key,
                displayName: def.displayName,
                direction: q.direction,
                priority: 1,
              ),
            ];
    });
  }

  void _add(SortingFieldDef def) {
    AppHaptics.selection();
    setState(() {
      _order.add(
        SortingCriteria(
          fieldKey: def.key,
          displayName: def.displayName,
          // Carat reads naturally largest-first; money cheapest-first.
          direction: def.key == 'carat'
              ? SortDirection.descending
              : SortDirection.ascending,
          priority: _order.length + 1,
        ),
      );
    });
  }

  void _remove(int index) {
    AppHaptics.selection();
    setState(() {
      _order.removeAt(index);
      _renumber();
    });
  }

  void _setDirection(int index, SortDirection d) {
    if (_order[index].direction == d) return;
    AppHaptics.selection();
    setState(() => _order[index] = _order[index].copyWith(direction: d));
  }

  void _move(int from, int to) {
    setState(() {
      final item = _order.removeAt(from);
      _order.insert(to.clamp(0, _order.length), item);
      _renumber();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    AppHaptics.selection();
    _move(oldIndex, newIndex);
  }

  void _clear() {
    AppHaptics.selection();
    setState(() => _order = []);
  }

  void _apply() {
    _renumber();
    ref.read(diamondSortingProvider.notifier).state = List.of(_order);
    ref.read(diamondListProvider.notifier).applyFiltersAndSort();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: p.canvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(LuxeSpace.radius + 4),
            ),
          ),
          child: Column(
            children: [
              _handle(p),
              _header(p),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  children: [
                    _sectionLabel(p, context.tr(CatalogL10n.sortQuickPicks)),
                    const SizedBox(height: 8),
                    _quickPickRow(p),
                    if (_order.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _orderList(p),
                    ],
                    if (_available.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _sectionLabel(p, context.tr(CatalogL10n.sortAddCriteria)),
                      const SizedBox(height: 8),
                      for (final def in _available)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _AddFieldTile(
                            def: def,
                            nth: _order.length + 1,
                            onTap: () => _add(def),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              _footer(p),
            ],
          ),
        );
      },
    );
  }

  Widget _handle(LuxePalette p) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: p.inkFaint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header(LuxePalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(CatalogL10n.sorting).toUpperCase(),
                  style: LuxeType.eyebrow(p.accent),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(CatalogL10n.sortTitle),
                  style: LuxeType.display(28, p.ink),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: p.surfaceRaised,
              foregroundColor: p.ink,
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(LuxePalette p, String text) =>
      Text(text.toUpperCase(), style: LuxeType.eyebrow(p.inkMuted));

  Widget _quickPickRow(LuxePalette p) {
    // Bleeds to the sheet edges so chips scroll under the side padding.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final q in _quickPicks)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _QuickPickChip(
                label: context.tr(q.labelKey),
                icon: q.icon,
                active: _isQuickPickActive(q),
                onTap: () => _applyQuickPick(q),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderList(LuxePalette p) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _order.length,
      onReorderItem: _onReorder,
      onReorderStart: (_) => AppHaptics.selection(),
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + 0.03 * t,
            child: Material(
              color: Colors.transparent,
              elevation: 10 * t,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
              child: child,
            ),
          );
        },
        child: child,
      ),
      itemBuilder: (context, i) {
        final c = _order[i];
        return Padding(
          key: ValueKey(c.fieldKey),
          padding: const EdgeInsets.only(bottom: 8),
          child: _SortRow(
            index: i,
            count: _order.length,
            criteria: c,
            onDirection: (d) => _setDirection(i, d),
            onRemove: () => _remove(i),
            onMove: (to) => _move(i, to),
          ),
        );
      },
    );
  }

  Widget _footer(LuxePalette p) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        8,
        14,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: p.canvas,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: Row(
        children: [
          if (_order.isNotEmpty) ...[
            TextButton(
              onPressed: _clear,
              style: TextButton.styleFrom(
                foregroundColor: p.inkMuted,
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                context.tr(CatalogL10n.sortClear),
                style: LuxeType.label(p.inkMuted, size: 13.5),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _apply,
              style: FilledButton.styleFrom(
                backgroundColor: p.ink,
                foregroundColor: p.canvas,
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(CatalogL10n.sortApply),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(p.canvas, size: 14.5),
                    ),
                  ),
                  if (_order.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: ShapeDecoration(
                        color: p.accent,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '${_order.length}',
                        style: LuxeType.figure(p.onAccent, size: 12),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One quick-pick pill (icon + label), filled when its recipe is active.
class _QuickPickChip extends StatelessWidget {
  const _QuickPickChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final fg = active ? p.canvas : p.ink;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? p.ink : p.surface,
        shape: StadiumBorder(
          side: BorderSide(color: active ? p.ink : p.hairline),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(active ? Icons.check_rounded : icon, size: 16, color: fg),
                const SizedBox(width: 5),
                Text(label, style: LuxeType.label(fg, size: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One criterion in the user's order: priority badge, field, direction
/// switch, remove, and the drag handle.
class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.index,
    required this.count,
    required this.criteria,
    required this.onDirection,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final int count;
  final SortingCriteria criteria;
  final ValueChanged<SortDirection> onDirection;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final first = index == 0;
    return Semantics(
      customSemanticsActions: {
        if (index > 0)
          CustomSemanticsAction(
            label: context.tr(CatalogL10n.sortMoveUp),
          ): () =>
              onMove(index - 1),
        if (index < count - 1)
          CustomSemanticsAction(
            label: context.tr(CatalogL10n.sortMoveDown),
          ): () =>
              onMove(index + 1),
      },
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
            border: Border.all(
              color: first ? p.accent : p.hairline,
              width: first ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _PriorityBadge(n: index + 1, primary: first),
                  const SizedBox(width: 8),
                  Icon(_fieldIcon(criteria.fieldKey), size: 18, color: p.ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          criteria.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.label(p.ink, size: 14.5),
                        ),
                        Text(
                          _fieldHint(context, criteria.fieldKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.body(p.inkFaint, size: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr(CatalogL10n.sortRemove),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: p.inkMuted,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: p.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _DirectionSwitch(
                  fieldKey: criteria.fieldKey,
                  value: criteria.direction,
                  onChanged: onDirection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.n, required this.primary});

  final int n;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primary ? p.accent : p.surfaceRaised,
      ),
      child: Text(
        '$n',
        style: LuxeType.figure(primary ? p.onAccent : p.ink, size: 13),
      ),
    );
  }
}

/// Two-way segmented control with field-specific wording.
class _DirectionSwitch extends StatelessWidget {
  const _DirectionSwitch({
    required this.fieldKey,
    required this.value,
    required this.onChanged,
  });

  final String fieldKey;
  final SortDirection value;
  final ValueChanged<SortDirection> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget seg(SortDirection d, IconData icon) {
      final on = value == d;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: LuxeMotion.fast,
              curve: LuxeMotion.settle,
              height: 36,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: on ? p.ink : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: on ? p.canvas : p.inkMuted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _directionLabel(context, fieldKey, d),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(
                        on ? p.canvas : p.inkMuted,
                        size: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: p.surfaceRaised,
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          seg(SortDirection.ascending, Icons.trending_up_rounded),
          seg(SortDirection.descending, Icons.trending_down_rounded),
        ],
      ),
    );
  }
}

class _AddFieldTile extends StatelessWidget {
  const _AddFieldTile({
    required this.def,
    required this.nth,
    required this.onTap,
  });

  final SortingFieldDef def;
  final int nth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        side: BorderSide(color: p.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(_fieldIcon(def.key), size: 18, color: p.ink),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.displayName,
                      style: LuxeType.label(p.ink, size: 14),
                    ),
                    Text(
                      _fieldHint(context, def.key),
                      style: LuxeType.body(p.inkFaint, size: 11.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: ShapeDecoration(
                  color: p.accentSoft,
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: p.accent),
                    const SizedBox(width: 3),
                    Text('#$nth', style: LuxeType.figure(p.accent, size: 12)),
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
