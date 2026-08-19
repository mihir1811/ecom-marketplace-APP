import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../domain/models/compare_item.dart';
import '../../domain/models/compare_spec.dart';

const double kCompareLabelWidth = 132;
const double kCompareColWidth = 140;
const double kCompareRowHeight = 52;

/// Owns horizontal scroll sync so the comparison screen shell never rebuilds on scroll.
class ComparisonTable extends StatefulWidget {
  const ComparisonTable({
    required this.items,
    required this.specs,
    required this.onRemove,
    required this.onReorder,
    super.key,
  });

  final List<CompareItem> items;
  final List<CompareSpecDef> specs;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<ComparisonTable> createState() => _ComparisonTableState();
}

class _ComparisonTableState extends State<ComparisonTable> {
  final List<ScrollController> _horizontalControllers = [];
  bool _syncingScroll = false;

  Color get _headerBg => AppColors.surface(_cachedContext!);
  Color get _border => AppColors.border(_cachedContext!);
  Color get _muted => AppColors.textMuted(_cachedContext!);
  Color get _leadBg => AppColors.isDark(_cachedContext!)
      ? const Color(0xFF1E2E22)
      : const Color(0xFFE9EDE8);

  BuildContext? _cachedContext;

  @override
  void initState() {
    super.initState();
    _ensureControllers(widget.specs.length + 1);
  }

  @override
  void didUpdateWidget(covariant ComparisonTable oldWidget) {
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
      if (target.hasClients && (target.offset - offset).abs() > 0.5) {
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

  double get _contentWidth => widget.items.length * kCompareColWidth;

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
    _cachedContext = context;
    final showReorderHint = widget.items.length > 1;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: kCompareLabelWidth,
                    child: _SpecColumnHeader(
                      headerBg: _headerBg,
                      muted: _muted,
                      showReorderHint: showReorderHint,
                    ),
                  ),
                  Expanded(
                    child: _scrollableValues(
                      rowIndex: 0,
                      child: _ItemHeaderRow(
                        items: widget.items,
                        specs: widget.specs,
                        border: _border,
                        muted: _muted,
                        onRemove: widget.onRemove,
                        onReorder: widget.onReorder,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var row = 0; row < widget.specs.length; row++)
            RepaintBoundary(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: kCompareLabelWidth,
                      child: _SpecLabelCell(
                        label: widget.specs[row].label,
                        stripe: row.isEven,
                        border: _border,
                        muted: _muted,
                      ),
                    ),
                    Expanded(
                      child: _scrollableValues(
                        rowIndex: row + 1,
                        child: _ItemValuesRow(
                          items: widget.items,
                          spec: widget.specs[row],
                          stripe: row.isEven,
                          border: _border,
                          leadBg: _leadBg,
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

class ComparisonFooterBar extends StatelessWidget {
  const ComparisonFooterBar({
    required this.count,
    required this.labelPlural,
    required this.onBrowse,
    required this.onClear,
    super.key,
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
          color: AppColors.card(context),
          border: Border(
            top: BorderSide(color: AppColors.border(context)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$count $labelPlural selected',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
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
                backgroundColor: AppColors.isDark(context)
                    ? AppColors.slateBorder
                    : AppColors.charcoal,
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
    final isDark = AppColors.isDark(context);
    final rowBg = stripe
        ? (isDark
            ? AppColors.slateSurface.withValues(alpha: 0.6)
            : AppColors.sandSurface.withValues(alpha: 0.45))
        : AppColors.card(context);

    return Container(
      height: kCompareRowHeight,
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
    required this.specs,
    required this.border,
    required this.muted,
    required this.onRemove,
    required this.onReorder,
  });

  final List<CompareItem> items;
  final List<CompareSpecDef> specs;
  final Color border;
  final Color muted;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: kCompareColWidth,
              child: _DraggableColumnHeader(
                item: items[i],
                index: i,
                specs: specs,
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
    final displays =
        items.map((e) => e.displayValues[spec.key] ?? 'N/A').toList();
    final nums = items.map((e) => e.numericValues[spec.key]).toList();
    final leaders = leadingFlags(
      displayValues: displays,
      numericValues: nums,
      spec: spec,
    );

    final isDark = AppColors.isDark(context);
    final rowBg = stripe
        ? (isDark
            ? AppColors.slateSurface.withValues(alpha: 0.6)
            : AppColors.sandSurface.withValues(alpha: 0.45))
        : AppColors.card(context);

    return Container(
      height: kCompareRowHeight,
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: kCompareColWidth,
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

class _DraggableColumnHeader extends StatelessWidget {
  const _DraggableColumnHeader({
    required this.item,
    required this.index,
    required this.specs,
    required this.border,
    required this.muted,
    required this.onRemove,
    required this.onReorder,
  });

  final CompareItem item;
  final int index;
  final List<CompareSpecDef> specs;
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
            elevation: 10,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.r8),
            child: SizedBox(
              width: kCompareColWidth,
              child: Opacity(
                opacity: 0.95,
                child: _DragColumnFeedback(
                  item: item,
                  specs: specs,
                  muted: muted,
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
              color: isTarget ? AppColors.bronze.withValues(alpha: 0.08) : null,
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

/// Full-column ghost shown while dragging (header + all spec cells).
class _DragColumnFeedback extends StatelessWidget {
  const _DragColumnFeedback({
    required this.item,
    required this.specs,
    required this.muted,
  });

  final CompareItem item;
  final List<CompareSpecDef> specs;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r8),
        border: Border.all(color: AppColors.bronze, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ItemHeader(
            item: item,
            border: AppColors.border(context),
            muted: muted,
            onRemove: () {},
          ),
          for (var i = 0; i < specs.length; i++)
            _DragSpecCell(
              value: item.displayValues[specs[i].key] ?? 'N/A',
              stripe: i.isEven,
            ),
        ],
      ),
    );
  }
}

class _DragSpecCell extends StatelessWidget {
  const _DragSpecCell({
    required this.value,
    required this.stripe,
  });

  final String value;
  final bool stripe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: kCompareRowHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: stripe
            ? (AppColors.isDark(context)
                ? AppColors.slateSurface.withValues(alpha: 0.6)
                : AppColors.sandSurface.withValues(alpha: 0.45))
            : AppColors.card(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context)),
        ),
      ),
      child: Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader({
    required this.item,
    required this.border,
    required this.muted,
    required this.onRemove,
  });

  final CompareItem item;
  final Color border;
  final Color muted;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: border)),
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
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(AppSpacing.r8),
                      border: Border.all(color: border),
                    ),
                    clipBehavior: Clip.antiAlias,
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
                        color: AppColors.card(context).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppSpacing.r4),
                      ),
                      child: Icon(Icons.drag_handle, size: 14, color: muted),
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
              color: AppColors.textPrimary(context),
            ),
          ),
          Text(
            item.displayValues['price'] ?? '',
            style: GoogleFonts.manrope(
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
    final url = item.imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final lower = url.toLowerCase();
      final isNetwork = lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower.startsWith('www.');
      if (isNetwork) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.r8),
          child: AppNetworkImage(
            url: lower.startsWith('www.') ? 'https://$url' : url,
            fit: BoxFit.cover,
            memCacheWidth: 280,
          ),
        );
      }
      if (url.startsWith('public/') || url.startsWith('assets/')) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Image.asset(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.diamond_outlined,
              color: AppColors.bronze,
            ),
          ),
        );
      }
    }
    if (item.shape != null) {
      return Center(
        child: renderShapeSvg(item.shape!, size: 40, color: AppColors.bronze),
      );
    }
    return const Icon(Icons.watch, color: AppColors.bronze, size: 36);
  }
}
