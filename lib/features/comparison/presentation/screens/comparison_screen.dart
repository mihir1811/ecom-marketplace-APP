import 'package:flutter/material.dart';
import 'package:gemstone/core/widgets/app_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../application/comparison_provider.dart';
import '../../domain/models/compare_item.dart';
import '../../domain/models/compare_spec.dart';

const double _kCompareLabelWidth = 132;
const double _kCompareColWidth = 140;
const double _kCompareRowHeight = 52;

/// Side-by-side comparison table with leading-option highlights.
class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(comparisonProvider);
    if (state.items.length < 2 || state.category == null) {
      return AppScaffold(
        appBar: AppBar(
          title: Text(
            'Compare',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select at least 2 items of the same type to compare.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.s16),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = state.items;
    final specs = specsForCategory(state.category!);
    final muted =
        AppColors.textMutedLight;
    final border = AppColors.warmBorder;
    final headerBg = AppColors.sandSurface;
    final leadBg = const Color(0xFFE9EDE8);

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          'Compare ${state.category!.labelPlural}',
          style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(comparisonProvider.notifier).clear();
              context.pop();
            },
            child: Text(
              'Start New',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.bronze,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _ComparisonTable(
              items: items,
              specs: specs,
              headerBg: headerBg,
              border: border,
              muted: muted,
              leadBg: leadBg,
              onRemove: (id) {
                ref.read(comparisonProvider.notifier).remove(id);
                if (ref.read(comparisonProvider).count < 2) {
                  context.pop();
                }
              },
              onReorder: (oldIndex, newIndex) {
                ref.read(comparisonProvider.notifier).reorder(oldIndex, newIndex);
              },
            ),
          ),
          _FooterBar(
            count: items.length,
            labelPlural: state.category!.labelPlural,
            onBrowse: () => context.pop(),
            onClear: () {
              ref.read(comparisonProvider.notifier).clear();
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

/// Fixed spec labels per row; item columns share one horizontal scroll offset.
class _ComparisonTable extends StatefulWidget {
  const _ComparisonTable({
    required this.items,
    required this.specs,
    required this.headerBg,
    required this.border,
    required this.muted,
    required this.leadBg,
    required this.onRemove,
    required this.onReorder,
  });

  final List<CompareItem> items;
  final List<CompareSpecDef> specs;
  final Color headerBg;
  final Color border;
  final Color muted;
  final Color leadBg;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_ComparisonTable> createState() => _ComparisonTableState();
}

class _ComparisonTableState extends State<_ComparisonTable> {
  final List<ScrollController> _horizontalControllers = [];
  bool _syncingScroll = false;

  @override
  void initState() {
    super.initState();
    _ensureControllers(widget.specs.length + 1);
  }

  @override
  void didUpdateWidget(covariant _ComparisonTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureControllers(widget.specs.length + 1);
  }

  void _ensureControllers(int rowCount) {
    while (_horizontalControllers.length < rowCount) {
      final index = _horizontalControllers.length;
      final controller = ScrollController();
      controller.addListener(() => _syncHorizontalFrom(index));
      _horizontalControllers.add(controller);
    }
    while (_horizontalControllers.length > rowCount) {
      _horizontalControllers.removeLast().dispose();
    }
  }

  void _syncHorizontalFrom(int sourceIndex) {
    if (_syncingScroll) return;
    final source = _horizontalControllers[sourceIndex];
    if (!source.hasClients) return;
    final offset = source.offset;
    _syncingScroll = true;
    for (var i = 0; i < _horizontalControllers.length; i++) {
      if (i == sourceIndex) continue;
      final target = _horizontalControllers[i];
      if (target.hasClients && target.offset != offset) {
        target.jumpTo(offset);
      }
    }
    _syncingScroll = false;
  }

  @override
  void dispose() {
    for (final c in _horizontalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _contentWidth => widget.items.length * _kCompareColWidth;

  Widget _scrollableValues({
    required int rowIndex,
    required Widget child,
  }) {
    return SingleChildScrollView(
      controller: _horizontalControllers[rowIndex],
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _contentWidth,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showReorderHint = widget.items.length > 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _kCompareLabelWidth,
                  child: _SpecColumnHeader(
                    headerBg: widget.headerBg,
                    muted: widget.muted,
                    showReorderHint: showReorderHint,
                  ),
                ),
                Expanded(
                  child: _scrollableValues(
                    rowIndex: 0,
                    child: _ItemHeaderRow(
                      items: widget.items,
                      border: widget.border,
                      muted: widget.muted,
                      onRemove: widget.onRemove,
                      onReorder: widget.onReorder,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var row = 0; row < widget.specs.length; row++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _kCompareLabelWidth,
                    child: _SpecLabelCell(
                      label: widget.specs[row].label,
                      stripe: row.isEven,
                      border: widget.border,
                      muted: widget.muted,
                    ),
                  ),
                  Expanded(
                    child: _scrollableValues(
                      rowIndex: row + 1,
                      child: _ItemValuesRow(
                        items: widget.items,
                        spec: widget.specs[row],
                        stripe: row.isEven,
                        border: widget.border,
                        leadBg: widget.leadBg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecColumnHeader extends StatelessWidget {
  const _SpecColumnHeader({
    required this.headerBg,
    required this.muted,
    required this.showReorderHint,
  });

  final Color headerBg;
  final Color muted;
  final bool showReorderHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: headerBg,
      padding: const EdgeInsets.all(AppSpacing.s12),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spec',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          if (showReorderHint) ...[
            const SizedBox(height: AppSpacing.s8),
            Icon(Icons.drag_indicator, size: 16, color: muted),
            const SizedBox(height: 2),
            Text(
              'Hold & drag cards to reorder',
              style: AppTypography.caption.copyWith(
                color: muted,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecLabelCell extends StatelessWidget {
  const _SpecLabelCell({
    required this.label,
    required this.stripe,
    required this.border,
    required this.muted,
  });

  final String label;
  final bool stripe;
  final Color border;
  final Color muted;
  @override
  Widget build(BuildContext context) {
    final rowBg = stripe
        ? AppColors.sandSurface.withValues(alpha: 0.45)
        : AppColors.warmWhite;

    return Container(
      height: _kCompareRowHeight,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(color: border),
          right: BorderSide(color: border),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: muted,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ItemHeaderRow extends StatelessWidget {
  const _ItemHeaderRow({
    required this.items,
    required this.border,
    required this.muted,
    required this.onRemove,
    required this.onReorder,
  });

  final List<CompareItem> items;
  final Color border;
  final Color muted;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final headerBg = AppColors.sandSurface;

    return Container(
      color: headerBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: _kCompareColWidth,
              child: _DraggableColumnHeader(
                item: items[i],
                index: i,
                border: border,
                muted: muted,
                onRemove: () => onRemove(items[i].id),
                onReorder: onReorder,
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemValuesRow extends StatelessWidget {
  const _ItemValuesRow({
    required this.items,
    required this.spec,
    required this.stripe,
    required this.border,
    required this.leadBg,
  });

  final List<CompareItem> items;
  final CompareSpecDef spec;
  final bool stripe;
  final Color border;
  final Color leadBg;
  @override
  Widget build(BuildContext context) {
    final displays = items
        .map((e) => e.displayValues[spec.key] ?? 'N/A')
        .toList();
    final nums = items.map((e) => e.numericValues[spec.key]).toList();
    final leaders = leadingFlags(
      displayValues: displays,
      numericValues: nums,
      spec: spec,
    );

    final rowBg = stripe
        ? AppColors.sandSurface.withValues(alpha: 0.45)
        : AppColors.warmWhite;

    return Container(
      height: _kCompareRowHeight,
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: _kCompareColWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: leaders[i] ? leadBg : null,
                  border: Border(left: BorderSide(color: border)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s8,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      if (leaders[i]) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Color(0xFF2E7D4F),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          displays[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight:
                                leaders[i] ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Long-press drag handle for a comparison column; drops update column order.
class _DraggableColumnHeader extends StatelessWidget {
  const _DraggableColumnHeader({
    required this.item,
    required this.index,
    required this.border,
    required this.muted,
    required this.onRemove,
    required this.onReorder,
  });

  final CompareItem item;
  final int index;
  final Color border;
  final Color muted;
  final VoidCallback onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        onReorder(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final isTarget = candidateData.isNotEmpty;
        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 180),
          hapticFeedbackOnStart: true,
          feedback: Material(
            elevation: 8,
            color: Colors.transparent,
            child: SizedBox(
              width: _kCompareColWidth,
              child: Opacity(
                opacity: 0.92,
                child: _ItemHeader(
                  item: item,
                  border: AppColors.bronze,
                  muted: muted,
                  onRemove: () {},
                  isDragging: true,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: _ItemHeader(
              item: item,
              border: border,
              muted: muted,
              onRemove: onRemove,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isTarget ? AppColors.bronze : Colors.transparent,
                  width: 3,
                ),
              ),
              color: isTarget
                  ? AppColors.bronze.withValues(alpha: 0.08)
                  : null,
            ),
            child: _ItemHeader(
              item: item,
              border: isTarget ? AppColors.bronze : border,
              muted: muted,
              onRemove: onRemove,
            ),
          ),
        );
      },
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({
    required this.item,
    required this.border,
    required this.muted,
    required this.onRemove,
    this.isDragging = false,
  });

  final CompareItem item;
  final Color border;
  final Color muted;
  final VoidCallback onRemove;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDragging
            ? (AppColors.warmWhite)
            : null,
        border: Border(left: BorderSide(color: border)),
        borderRadius: isDragging
            ? BorderRadius.circular(AppSpacing.r8)
            : null,
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.sandSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      border: Border.all(color: border),
                    ),
                    child: _thumb(item),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.terracotta,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        size: 14,
                        color: muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Text(
            item.displayValues['price'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.bronze,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(CompareItem item) {
    if (item.imageUrl != null && item.imageUrl!.startsWith('public/')) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Image.asset(
          item.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.diamond_outlined,
            color: AppColors.bronze,
          ),
        ),
      );
    }
    if (item.shape != null) {
      return Center(
        child: renderShapeSvg(item.shape!, size: 40, color: AppColors.bronze),
      );
    }
    return const Icon(Icons.watch, color: AppColors.bronze, size: 36);
  }
}

class _FooterBar extends StatelessWidget {
  const _FooterBar({
    required this.count,
    required this.labelPlural,
    required this.onBrowse,
    required this.onClear,
  });

  final int count;
  final String labelPlural;
  final VoidCallback onBrowse;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          border: Border(
            top: BorderSide(
              color: AppColors.warmBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count $labelPlural selected',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onBrowse,
              child: Text(
                'Browse More',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.bronze,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.charcoal,
                foregroundColor: AppColors.warmWhite,
              ),
              onPressed: onClear,
              child: const Text('Start New Comparison'),
            ),
          ],
        ),
      ),
    );
  }
}
