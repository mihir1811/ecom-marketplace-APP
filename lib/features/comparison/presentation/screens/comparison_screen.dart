import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../diamond_projects/application/diamond_selection.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/comparison_provider.dart';
import '../../domain/models/compare_insights.dart';
import '../../domain/models/compare_item.dart';
import '../../domain/models/compare_spec.dart';
import '../widgets/vitrine/vitrine_gem.dart';
import '../widgets/vitrine/vitrine_rail.dart';
import '../widgets/vitrine/vitrine_sheets.dart';
import '../widgets/vitrine/vitrine_specs.dart';
import '../widgets/vitrine/vitrine_style.dart';

/// Side-by-side comparison.
///
/// A pinned rail of piece medallions folds into thumbnails as grouped spec
/// rows scroll beneath it; every value sits under its piece. The strongest
/// value per row is marked in gold, each piece tallies its leads, shared
/// values are hidden so only the differences show. Tap a piece for details, moving or removing it (with undo);
/// long-press to drag it into another place.
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  void _browse() => context.goBack();

  Future<void> _clear() async {
    final ok = await confirmVitrineClear(context);
    if (!ok || !mounted) return;
    AppHaptics.medium();
    DiamondSelection.clearComparison(ref);
    _browse();
  }

  void _remove(List<CompareItem> items, int index) {
    final item = items[index];
    final repick = DiamondSelection.remove(ref, item.id);
    final messenger = ScaffoldMessenger.of(context);
    final v = Vitrine.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: v.ink,
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          duration: const Duration(seconds: 4),
          content: Text(
            '${context.tr(AccountCommerceL10n.removedComparison)} · ${item.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: v.text(13, color: v.paper, weight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: context.tr(AccountCommerceL10n.compareUndo),
            textColor: v.gold,
            onPressed: () =>
                DiamondSelection.restore(ref, item, index, repick: repick),
          ),
        ),
      );
  }

  void _move(int from, int to) =>
      ref.read(comparisonProvider.notifier).reorder(from, to);

  Future<void> _openPiece(
    List<CompareItem> items,
    CompareInsights insights,
    int index,
  ) async {
    final item = items[index];
    final action = await showVitrinePieceSheet(
      context,
      item: item,
      index: index,
      count: items.length,
      wins: insights.wins.elementAtOrNull(index) ?? 0,
      decisive: insights.decisive,
      canViewDetails: findRememberedProductDetail(item.id) != null,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case VitrinePieceAction.details:
        openRememberedProductDetail(context, item.id);
      case VitrinePieceAction.left:
        _move(index, index - 1);
      case VitrinePieceAction.right:
        _move(index, index + 1);
      case VitrinePieceAction.remove:
        _remove(items, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final state = ref.watch(comparisonProvider);
    final category = state.category;
    final items = state.items;

    return AppScaffold(
      backgroundColor: v.paper,
      body: Column(
        children: [
          _TopBar(
            title: category == null
                ? context.tr(AccountCommerceL10n.compare)
                : _capitalize(context.tr(category.labelPluralKey)),
            onBack: _browse,
            onClear: items.isEmpty ? null : _clear,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: VitrineMotion.settle,
              switchInCurve: VitrineMotion.ease,
              child: items.isEmpty || category == null
                  ? _Empty(key: const ValueKey('empty'), onBrowse: _browse)
                  : _Board(
                      key: const ValueKey('board'),
                      items: items,
                      specs: specsForCategory(category),
                      groups: groupSpecs(category, specsForCategory(category)),
                      onTapPiece: (i, insights) =>
                          _openPiece(items, insights, i),
                      onRemove: (i) => _remove(items, i),
                      onReorder: _move,
                      onAdd: _browse,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onClear,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_rounded,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: onBack,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  context.tr(AccountCommerceL10n.compareEyebrow).toUpperCase(),
                  style: v.eyebrow(color: v.gold),
                ),
                const SizedBox(height: 3),
                Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: v.display(24),
                    )
                    .animate()
                    .fadeIn(duration: VitrineMotion.settle)
                    .shimmer(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 1600),
                      color: v.gold,
                    ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: AnimatedOpacity(
              duration: VitrineMotion.quick,
              opacity: onClear == null ? 0 : 1,
              child: TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: v.muted,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  context.tr(AccountCommerceL10n.compareClear),
                  style: v.text(13, weight: FontWeight.w700, color: v.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: v.card,
        shape: CircleBorder(side: BorderSide(color: v.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: v.ink),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.items,
    required this.specs,
    required this.groups,
    required this.onTapPiece,
    required this.onRemove,
    required this.onReorder,
    required this.onAdd,
    super.key,
  });

  final List<CompareItem> items;
  final List<CompareSpecDef> specs;
  final List<CompareSpecGroup> groups;
  final void Function(int index, CompareInsights insights) onTapPiece;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    final insights = CompareInsights.of(items, specs);
    // Only rows that differ are shown once two or more pieces are compared.
    final differencesOnly = items.length > 1;
    final allSame =
        items.length > 1 &&
        specs
            .where((s) => !insights.empty.contains(s.key))
            .every((s) => insights.identical.contains(s.key));

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = VitrineColumns(
          count: math.max(items.length, 2),
          width: constraints.maxWidth,
        );
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
                child: Text(
                  context.tr(AccountCommerceL10n.comparePiecesOf, {
                    'count': items.length,
                    'max': ComparisonState.maxItems,
                  }),
                  textAlign: TextAlign.center,
                  style: v.text(12, color: v.muted, weight: FontWeight.w600),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: VitrineRailDelegate(
                items: items,
                insights: insights,
                columns: columns,
                onTapPiece: (i) => onTapPiece(i, insights),
                onRemove: onRemove,
                onReorder: onReorder,
                onAdd: onAdd,
              ),
            ),
            if (items.length == 1)
              SliverToBoxAdapter(
                child: _Notice(
                  text: context.tr(AccountCommerceL10n.compareOneMore),
                  action: context.tr(AccountCommerceL10n.browseMore),
                  onAction: onAdd,
                ),
              ),
            if (differencesOnly && allSame)
              SliverToBoxAdapter(
                child: _Notice(
                  text: context.tr(AccountCommerceL10n.compareAllIdentical),
                ),
              ),
            SliverList.list(
              children: [
                for (var i = 0; i < groups.length; i++)
                  VitrineSpecGroup(
                        group: groups[i],
                        items: items,
                        insights: insights,
                        columns: columns,
                        differencesOnly: differencesOnly,
                      )
                      .animate(delay: VitrineMotion.stagger * (i + 2))
                      .fadeIn(
                        duration: VitrineMotion.settle,
                        curve: VitrineMotion.ease,
                      )
                      .slideY(begin: 0.06, end: 0, curve: VitrineMotion.ease),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785,
                          child: Container(width: 6, height: 6, color: v.gold),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr(AccountCommerceL10n.compareLegend),
                            textAlign: TextAlign.center,
                            style: v.text(11.5, color: v.muted),
                          ),
                        ),
                      ],
                    ),
                    if (items.length > 1) ...[
                      const SizedBox(height: 5),
                      Text(
                        context.tr(AccountCommerceL10n.reorderHint),
                        textAlign: TextAlign.center,
                        style: v.text(11.5, color: v.faint),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          decoration: BoxDecoration(
            color: v.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: v.line, width: 0.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: v.display(15.5, style: FontStyle.italic),
                ),
              ),
              if (action != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(foregroundColor: v.gold),
                  child: Text(
                    action!,
                    style: v.text(12.5, weight: FontWeight.w800, color: v.gold),
                  ),
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: VitrineMotion.settle)
        .slideY(begin: 0.1, end: 0);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse, super.key});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final v = Vitrine.of(context);
    Widget enter(Widget w, int i) => w
        .animate(delay: VitrineMotion.stagger * i)
        .fadeIn(duration: VitrineMotion.settle, curve: VitrineMotion.ease)
        .slideY(begin: 0.12, end: 0, curve: VitrineMotion.ease);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            enter(const VitrineGem(size: 170), 0),
            const SizedBox(height: 14),
            enter(
              Text(
                context.tr(AccountCommerceL10n.compareEmptyTitle),
                textAlign: TextAlign.center,
                style: v.display(30),
              ),
              1,
            ),
            const SizedBox(height: 8),
            enter(
              Text(
                context.tr(AccountCommerceL10n.compareEmptyBody),
                textAlign: TextAlign.center,
                style: v.text(14, color: v.muted, height: 1.55),
              ),
              2,
            ),
            const SizedBox(height: 18),
            enter(
              Material(
                color: v.ink,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () {
                    AppHaptics.selection();
                    onBrowse();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    child: Text(
                      context.tr(AccountCommerceL10n.browseMore),
                      style: v.text(
                        14,
                        weight: FontWeight.w700,
                        color: v.paper,
                      ),
                    ),
                  ),
                ),
              ),
              3,
            ),
          ],
        ),
      ),
    );
  }
}
