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
          LuxeViewToggle(
            viewMode: viewMode,
            onChanged: onViewMode,
            gridLabel: gridLabel,
            listLabel: listLabel,
          ),
        ],
      ),
    );
  }
}

/// Compact grid / list switch.
class LuxeViewToggle extends StatelessWidget {
  const LuxeViewToggle({
    required this.viewMode,
    required this.onChanged,
    required this.gridLabel,
    required this.listLabel,
    super.key,
  });

  final LuxeViewMode viewMode;
  final ValueChanged<LuxeViewMode> onChanged;
  final String gridLabel;
  final String listLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: LuxeSegmented<LuxeViewMode>(
        options: LuxeViewMode.values,
        selected: viewMode,
        height: 38,
        dense: true,
        onChanged: onChanged,
        labelOf: (m) => m == LuxeViewMode.grid ? gridLabel : listLabel,
        iconOf: (m) => m == LuxeViewMode.grid
            ? Icons.grid_view_rounded
            : Icons.view_agenda_outlined,
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
    final size = MediaQuery.sizeOf(context);
    final cell = (size.width - padding * 2 - gap) / 2;
    final gridExtent = LuxeListingMetrics.gridExtent(context);
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
            AspectRatio(
              aspectRatio: 1,
              child: block(
                double.infinity,
                double.infinity,
                LuxeSpace.radius - 5,
              ),
            ),
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
    // Enough rows to cover the whole viewport, laid out with the same grid
    // delegate as real results so both columns always render (a Wrap of two
    // exact half-width cells could overflow by rounding and fall to one).
    final rows =
        (size.height /
                (grid ? gridExtent + gap : LuxeListingMetrics.listStride))
            .ceil() +
        1;
    final skeletonCard = LuxeSkeleton(child: grid ? gridCard : listCard);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padding, 6, padding, 24),
      sliver: grid
          ? SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: gridExtent,
              ),
              itemCount: rows * 2,
              itemBuilder: (_, _) => skeletonCard,
            )
          : SliverList.separated(
              itemCount: rows,
              separatorBuilder: (_, _) => SizedBox(height: gap),
              itemBuilder: (_, _) => skeletonCard,
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

/// Grid / list spacing shared by every luxe results screen.
abstract final class LuxeListingMetrics {
  static const gap = 12.0;
  static const pad = 16.0;

  /// Row stride of [LuxeProductListCard] including the gap.
  static const listStride = LuxeProductListCard.thumbSize + 12 + gap;

  static double gridCell(BuildContext context) =>
      (MediaQuery.sizeOf(context).width - pad * 2 - gap) / 2;

  /// Fixed tile extent of [LuxeProductGridCard] at the current text scale.
  static double gridExtent(BuildContext context) =>
      gridCell(context) +
      luxeGridCardTextExtent(MediaQuery.textScalerOf(context));
}

/// Scroll offset, next-page prefetch, back-to-top and position-preserving
/// grid ↔ list switching shared by every luxe results screen.
///
/// Call [initListing] / [disposeListing] from the state's lifecycle and put
/// [listingHeaderKey] on whatever sits above the pinned toolbar.
mixin LuxeListingMixin<W extends StatefulWidget> on State<W> {
  final listingScroll = ScrollController();
  final listingOffset = ValueNotifier<double>(0);
  final listingHeaderKey = GlobalKey();

  /// Ids whose entrance animation already played.
  final listingEntered = <String>{};

  /// True when another page may be requested right now.
  bool get listingCanLoadMore;
  void listingLoadMore();
  int get listingItemCount;
  LuxeViewMode get listingViewMode;
  void listingApplyViewMode(LuxeViewMode mode);

  void initListing() => listingScroll.addListener(_onListingScroll);

  void disposeListing() {
    listingScroll
      ..removeListener(_onListingScroll)
      ..dispose();
    listingOffset.dispose();
  }

  void _onListingScroll() {
    if (!listingScroll.hasClients) return;
    listingOffset.value = listingScroll.offset;
    if (!listingCanLoadMore) return;
    final position = listingScroll.position;
    // Prefetch ~1 viewport before the end so the next page arrives seamlessly.
    if (position.pixels >=
        position.maxScrollExtent - position.viewportDimension) {
      listingLoadMore();
    }
  }

  double get _headerExtent {
    final box = listingHeaderKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }

  double _stride(LuxeViewMode mode) => mode == LuxeViewMode.grid
      ? LuxeListingMetrics.gridExtent(context) + LuxeListingMetrics.gap
      : LuxeListingMetrics.listStride;

  /// Switches layout while keeping the first visible item in view.
  void switchListingViewMode(LuxeViewMode next) {
    final current = listingViewMode;
    if (current == next) return;
    final count = listingItemCount;
    final into =
        (listingScroll.hasClients ? listingScroll.offset : 0) - _headerExtent;
    final index = count == 0 || into <= 0
        ? 0
        : ((into / _stride(current)).floor() *
                  (current == LuxeViewMode.grid ? 2 : 1))
              .clamp(0, count - 1);
    listingApplyViewMode(next);
    if (index == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !listingScroll.hasClients) return;
      final rows = next == LuxeViewMode.grid ? index ~/ 2 : index;
      final target = _headerExtent + rows * _stride(next);
      listingScroll.jumpTo(
        target.clamp(0.0, listingScroll.position.maxScrollExtent),
      );
    });
  }

  void listingBackToTop() => listingScroll.animateTo(
    0,
    duration: const Duration(milliseconds: 900),
    curve: LuxeMotion.settle,
  );
}

/// Results slivers for a paginated catalog: skeletons while the first page
/// loads, an error or empty state, then the staggered grid / list and the
/// loading-more row.
List<Widget> luxeResultSlivers<T>({
  required BuildContext context,
  required bool initialLoading,
  required String? error,
  required List<T> items,
  required bool isLoadingMore,
  required LuxeViewMode viewMode,
  required String Function(T) idOf,
  required Widget Function(T item, LuxeViewMode mode) cardOf,
  required Set<String> entered,
  required Widget emptyView,
  required Widget Function(String message) errorView,
  required String loadingMoreLabel,
}) {
  const pad = LuxeListingMetrics.pad;
  const gap = LuxeListingMetrics.gap;
  final grid = viewMode == LuxeViewMode.grid;
  Widget fill(Widget child) =>
      SliverFillRemaining(hasScrollBody: false, child: child);

  if (initialLoading) {
    return [LuxeListingSkeletons(grid: grid, padding: pad, gap: gap)];
  }
  if (error != null && items.isEmpty) return [fill(errorView(error))];
  if (items.isEmpty) return [fill(emptyView)];

  Widget card(int i) {
    final item = items[i];
    final id = '${viewMode.name}-${idOf(item)}';
    return LuxeEntranceOnce(
      key: ValueKey(id),
      id: id,
      seen: entered,
      index: i,
      child: RepaintBoundary(child: cardOf(item, viewMode)),
    );
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(pad, 6, pad, 0),
      sliver: grid
          ? SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                mainAxisExtent: LuxeListingMetrics.gridExtent(context),
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => card(i),
            )
          : SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: gap),
              itemBuilder: (context, i) => card(i),
            ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
        child: isLoadingMore
            ? LuxeLoadingMore(label: loadingMoreLabel)
            : const SizedBox.shrink(),
      ),
    ),
  ];
}

/// Scrollable results body: pull-to-refresh, the caller's slivers and a
/// floating back-to-top control.
class LuxeListingScrollView extends StatelessWidget {
  const LuxeListingScrollView({
    required this.controller,
    required this.offset,
    required this.slivers,
    required this.onRefresh,
    required this.onBackToTop,
    required this.backToTopLabel,
    super.key,
  });

  final ScrollController controller;
  final ValueListenable<double> offset;
  final List<Widget> slivers;
  final Future<void> Function() onRefresh;
  final VoidCallback onBackToTop;
  final String backToTopLabel;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Stack(
      children: [
        RefreshIndicator(
          color: p.ink,
          backgroundColor: p.surface,
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: LuxeBackToTop(
            offset: offset,
            tooltip: backToTopLabel,
            onTap: onBackToTop,
          ),
        ),
      ],
    );
  }
}

/// Rounded luxe search input with a clear action.
class LuxeSearchField extends StatefulWidget {
  const LuxeSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    super.key,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LuxeSearchField> createState() => _LuxeSearchFieldState();
}

class _LuxeSearchFieldState extends State<LuxeSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(LuxeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final hasText = widget.controller.text.isNotEmpty;
    final radius = BorderRadius.circular(28);
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      style: LuxeType.body(p.ink, size: 14.5),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.inkMuted),
        suffixIcon: hasText
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: Icon(Icons.close_rounded, size: 18, color: p.inkMuted),
                onPressed: () {
                  AppHaptics.selection();
                  widget.controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.ink, width: 1.2),
        ),
      ),
    );
  }
}

/// One quick-filter chip: value, label and an optional tone dot or custom
/// leading mark (e.g. a metal swatch).
class LuxeQuickChip<T> {
  const LuxeQuickChip({
    required this.value,
    required this.label,
    this.tone,
    this.leading,
  });

  final T value;
  final String label;
  final Color? tone;
  final Widget? leading;
}

/// Horizontally scrolling stadium chips for listing-level quick filters
/// (categories, metals, variants). Selection is decided by [isSelected].
class LuxeQuickChips<T> extends StatelessWidget {
  const LuxeQuickChips({
    required this.chips,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.dense = false,
  });

  final List<LuxeQuickChip<T>> chips;
  final bool Function(T) isSelected;
  final ValueChanged<T> onTap;

  /// Smaller secondary row (e.g. variants under metals).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SizedBox(
      height: dense ? 34 : 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = isSelected(chip.value);
          return Semantics(
            button: true,
            selected: selected,
            label: chip.label,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () {
                AppHaptics.selection();
                onTap(chip.value);
              },
              child: AnimatedContainer(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 16),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: selected ? p.ink : p.surface,
                  shape: StadiumBorder(
                    side: BorderSide(color: selected ? p.ink : p.hairline),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chip.leading != null) ...[
                      chip.leading!,
                      const SizedBox(width: 8),
                    ] else if (chip.tone != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: chip.tone,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      chip.label,
                      style: LuxeType.label(
                        selected ? p.canvas : p.inkMuted,
                        size: dense ? 12 : 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Eyebrow-style row heading with an optional trailing text action.
class LuxeRowHeading extends StatelessWidget {
  const LuxeRowHeading({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: LuxeType.eyebrow(p.accent)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(p.inkMuted, size: 12.5),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: p.accent),
              child: Text(
                actionLabel!,
                style: LuxeType.label(p.accent, size: 12.5),
              ),
            ),
        ],
      ),
    );
  }
}
