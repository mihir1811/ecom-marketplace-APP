import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import 'luxe_button.dart';
import 'luxe_feedback.dart';
import 'luxe_layout.dart';
import 'luxe_product_card.dart';

/// Pinned, frosted sliver header used by finder indexes and result toolbars.
class LuxePinnedBar extends StatelessWidget {
  const LuxePinnedBar({
    required this.child,
    super.key,
    this.extent = 56,
    this.background,
  });

  final Widget child;
  final double extent;

  /// Defaults to the luxe canvas.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _PinnedBarDelegate(
        child: child,
        extent: extent,
        background: background ?? p.canvas,
        hairline: p.hairline,
      ),
    );
  }
}

class _PinnedBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedBarDelegate({
    required this.child,
    required this.extent,
    required this.background,
    required this.hairline,
  });

  final Widget child;
  final double extent;
  final Color background;
  final Color hairline;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: overlaps ? hairline : Colors.transparent,
                width: 0.6,
              ),
            ),
          ),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedBarDelegate old) =>
      old.child != child ||
      old.background != background ||
      old.extent != extent ||
      old.hairline != hairline;
}

/// Grid / list presentation of catalog results.
enum LuxeViewMode { grid, list }

/// Results toolbar: Filters (with active count), Sort (current key) and the
/// grid / list switch.
class LuxeListingToolbar extends StatelessWidget {
  const LuxeListingToolbar({
    required this.filtersLabel,
    required this.activeFilters,
    required this.onFilters,
    required this.sortLabel,
    required this.onSort,
    required this.viewMode,
    required this.onViewMode,
    required this.gridLabel,
    required this.listLabel,
    super.key,
    this.sortBadge = 0,
  });

  final String filtersLabel;
  final int activeFilters;
  final VoidCallback onFilters;
  final String sortLabel;
  final int sortBadge;
  final VoidCallback onSort;
  final LuxeViewMode viewMode;
  final ValueChanged<LuxeViewMode> onViewMode;
  final String gridLabel;
  final String listLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          LuxeToolbarPill(
            icon: Icons.tune_rounded,
            label: filtersLabel,
            badge: activeFilters,
            onTap: onFilters,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: LuxeToolbarPill(
                icon: Icons.swap_vert_rounded,
                label: sortLabel,
                badge: sortBadge,
                onTap: onSort,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: LuxeSegmented<LuxeViewMode>(
              options: LuxeViewMode.values,
              selected: viewMode,
              height: 38,
              dense: true,
              onChanged: onViewMode,
              labelOf: (m) => m == LuxeViewMode.grid ? gridLabel : listLabel,
              iconOf: (m) => m == LuxeViewMode.grid
                  ? Icons.grid_view_rounded
                  : Icons.view_agenda_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined stadium pill with an icon, label and optional count badge.
class LuxeToolbarPill extends StatelessWidget {
  const LuxeToolbarPill({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.hairline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.ink, size: 12.5),
                ),
              ),
              AnimatedSwitcher(
                duration: LuxeMotion.fast,
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: badge > 0
                    ? Container(
                        key: ValueKey(badge),
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        height: 18,
                        alignment: Alignment.center,
                        decoration: ShapeDecoration(
                          color: p.ink,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          '$badge',
                          style: LuxeType.figure(p.canvas, size: 10.5),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip of active-filter summaries plus a reset action.
class LuxeActiveFilterPills extends StatelessWidget {
  const LuxeActiveFilterPills({
    required this.labels,
    required this.onEdit,
    required this.onReset,
    required this.resetLabel,
    super.key,
  });

  final List<String> labels;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    if (labels.isEmpty) return const SizedBox(height: 6);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          for (final label in labels) ...[
            Material(
              color: p.accentSoft,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(label, style: LuxeType.label(p.ink, size: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          TextButton.icon(
            onPressed: () {
              AppHaptics.selection();
              onReset();
            },
            style: TextButton.styleFrom(foregroundColor: p.accent),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(
              resetLabel,
              style: LuxeType.label(p.accent, size: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small cross-fading line under a top-bar title (e.g. "1,284 results").
class LuxeCountLine extends StatelessWidget {
  const LuxeCountLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return AnimatedSwitcher(
      duration: LuxeMotion.medium,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        style: LuxeType.label(p.inkMuted, size: 12),
      ),
    );
  }
}

/// Plays a short fade-up the first time an item is shown (first ~10 only),
/// never again when it is scrolled back into view.
class LuxeEntranceOnce extends StatefulWidget {
  const LuxeEntranceOnce({
    required this.id,
    required this.seen,
    required this.index,
    required this.child,
    super.key,
  });

  final String id;

  /// Ids that already played; owned by the screen so it outlives items.
  final Set<String> seen;
  final int index;
  final Widget child;

  @override
  State<LuxeEntranceOnce> createState() => _LuxeEntranceOnceState();
}

class _LuxeEntranceOnceState extends State<LuxeEntranceOnce> {
  late final bool _animate = widget.index < 10 && widget.seen.add(widget.id);

  @override
  Widget build(BuildContext context) {
    if (!_animate || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return widget.child
        .animate(delay: (widget.index * 55).ms)
        .fadeIn(duration: 420.ms)
        .moveY(begin: 18, end: 0, duration: 650.ms, curve: LuxeMotion.settle);
  }
}

/// Inline spinner + label shown while the next page loads.
class LuxeLoadingMore extends StatelessWidget {
  const LuxeLoadingMore({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 1.8, color: p.accent),
        ),
        const SizedBox(width: 12),
        Text(label, style: LuxeType.label(p.inkMuted, size: 12.5)),
      ],
    );
  }
}

/// Floating "back to top" control that slides in after scrolling far.
class LuxeBackToTop extends StatelessWidget {
  const LuxeBackToTop({
    required this.offset,
    required this.onTap,
    required this.tooltip,
    super.key,
    this.showAfter = 1400,
  });

  final ValueListenable<double> offset;
  final VoidCallback onTap;
  final String tooltip;
  final double showAfter;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, _) {
        final show = value > showAfter;
        return AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, 1.6),
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: LuxeMotion.fast,
            child: IgnorePointer(
              ignoring: !show,
              child: LuxeIconButton(
                icon: Icons.arrow_upward_rounded,
                tooltip: tooltip,
                onPressed: onTap,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmering placeholder cards matching [LuxeProductGridCard] /
/// [LuxeProductListCard] while the first page loads.
class LuxeListingSkeletons extends StatelessWidget {
  const LuxeListingSkeletons({
    required this.grid,
    super.key,
    this.padding = 16,
    this.gap = 12,
  });

  final bool grid;
  final double padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cell = (width - padding * 2 - gap) / 2;
    Widget block(double? w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    Widget frame(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        border: Border.all(color: p.hairline),
      ),
      child: child,
    );
    final gridCard = frame(
      Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(double.infinity, cell - 10, LuxeSpace.radius - 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 12, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(cell * 0.65, 16),
                  const SizedBox(height: 8),
                  block(cell * 0.45, 11),
                  const SizedBox(height: 14),
                  block(cell * 0.5, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    const thumb = LuxeProductListCard.thumbSize;
    final listCard = frame(
      Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            block(thumb, thumb, LuxeSpace.radius - 6),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(140, 16),
                  const SizedBox(height: 8),
                  block(100, 11),
                  const SizedBox(height: 20),
                  block(90, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 6, padding, 24),
      sliver: SliverToBoxAdapter(
        child: LuxeSkeleton(
          child: grid
              ? Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (var i = 0; i < 4; i++)
                      SizedBox(width: cell, child: gridCard),
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      listCard,
                      SizedBox(height: gap),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Single-choice luxe sheet (e.g. sort order). Resolves to the picked
/// option, or null when dismissed.
Future<T?> showLuxeChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T current,
  required String Function(T) labelOf,
}) {
  return showLuxeSheet<T>(
    context,
    title: title,
    builder: (sheetContext) {
      final p = LuxePalette.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: o == current ? p.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                child: InkWell(
                  borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.of(sheetContext).pop(o);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labelOf(o),
                            style: LuxeType.label(
                              o == current ? p.ink : p.inkMuted,
                              size: 14,
                            ),
                          ),
                        ),
                        AnimatedScale(
                          scale: o == current ? 1 : 0,
                          duration: LuxeMotion.fast,
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
