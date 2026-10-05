import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_wheel.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/keyboard_aware.dart';
import '../../application/watch_filter_provider.dart';
import '../../domain/models/watch_brand_categories.dart';
import '../../domain/models/watch_filter_state.dart';
import 'brand_dials/watch_dial.dart';
import 'watch_brand_assets.dart';

/// Shop by Brand: a coverflow of each house's flagship watch head (live
/// time, no bracelet), styled like the home shape atelier. The centred
/// watch sits inside a graduated loupe dial that turns with the carousel;
/// neighbours tilt away at the sides. Tapping the centre (or the button)
/// toggles that brand filter; tapping a side watch brings it to centre.
///
/// The strip loops endlessly and drifts to the next house every few
/// seconds until the user touches it. One ticker drives every dial and
/// pauses while the strip is off screen.
class WatchBrandCarousel extends ConsumerStatefulWidget {
  const WatchBrandCarousel({super.key});

  @override
  ConsumerState<WatchBrandCarousel> createState() => _WatchBrandCarouselState();
}

class _WatchBrandCarouselState extends ConsumerState<WatchBrandCarousel>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _brands = WatchBrandAssets.featuredBrands;
  static const _loops = 1000;
  static const _autoScrollInterval = Duration(seconds: 4);
  static const _stageHeight = 230.0;
  static const _loupeSize = 196.0;

  late final PageController _controller = PageController(
    viewportFraction: 0.34,
    initialPage: _brands.length * (_loops ~/ 2),
  );
  late int _current = _brands.length * (_loops ~/ 2);
  Timer? _autoScrollTimer;
  bool _userTouched = false;

  /// Shared clock that repaints the live hands.
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _clock.value = elapsed.inMicroseconds / 1e6,
  );
  ScrollPosition? _scroll;
  bool _visible = true;

  String get _brand => _brands[_current % _brands.length];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_checkVisible);
      _scroll = next?..addListener(_checkVisible);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisible());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoScrollTimer?.cancel();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll?.removeListener(_checkVisible);
    _autoScrollTimer?.cancel();
    _controller.dispose();
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _checkVisible() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final top = box.localToGlobal(Offset.zero).dy;
      final screen = MediaQuery.sizeOf(context).height;
      _visible = top < screen && top + box.size.height > 0;
    }
    final run = _visible && !MediaQuery.disableAnimationsOf(context);
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_userTouched) return;
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!mounted || !_controller.hasClients || !_visible) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _controller.animateToPage(
        _current + 1,
        duration: const Duration(milliseconds: 900),
        curve: LuxeMotion.settle,
      );
    });
  }

  void _toggle(String brand) {
    AppHaptics.selection();
    ref.read(watchFilterProvider.notifier).toggleBrand(brand);
  }

  void _onTapItem(int index) {
    _stopAutoScroll();
    if (index == _current) {
      _toggle(_brands[index % _brands.length]);
      return;
    }
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 650),
      curve: LuxeMotion.settle,
    );
  }

  /// The user took over; stop drifting for this visit.
  void _stopAutoScroll() {
    _userTouched = true;
    _autoScrollTimer?.cancel();
  }

  double _page() =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? _current.toDouble()
      : _current.toDouble();

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final selected = ref.watch(watchFilterProvider.select((s) => s.brands));
    final brand = _brand;
    final flagship = WatchFlagship.of(brand);
    final isSelected = selected.contains(brand);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuxeRowHeading(
            title: 'Shop by Brand',
            subtitle: 'Select one or more luxury houses',
            actionLabel: 'View All Brands',
            onAction: () => showWatchBrandsDirectory(context),
          ),
          SizedBox(
            height: _stageHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Loupe dial: turns with the carousel, scroll-linked.
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      size: const Size.square(_loupeSize),
                      painter: _LoupePainter(
                        rotation: _page() * math.pi / 10,
                        color: p.accent,
                        hairline: isSelected ? p.accent : p.hairline,
                      ),
                    ),
                  ),
                ),
                NotificationListener<ScrollStartNotification>(
                  onNotification: (n) {
                    if (n.dragDetails != null) _stopAutoScroll();
                    return false;
                  },
                  child: PageView.builder(
                    controller: _controller,
                    clipBehavior: Clip.none,
                    itemCount: _brands.length * _loops,
                    onPageChanged: (i) {
                      AppHaptics.selection();
                      setState(() => _current = i);
                    },
                    itemBuilder: (context, i) => _BrandWatchItem(
                      controller: _controller,
                      index: i,
                      fallbackPage: _current.toDouble(),
                      brand: _brands[i % _brands.length],
                      clock: _clock,
                      selected: selected.contains(_brands[i % _brands.length]),
                      onTap: () => _onTapItem(i),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: LuxeMotion.medium,
            switchInCurve: LuxeMotion.settle,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(brand),
              children: [
                Text(
                  brand,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.displayItalic(32, p.ink),
                ),
                if (flagship != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    flagship.model.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: LuxeType.eyebrow(p.accent).copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () {
                _stopAutoScroll();
                _toggle(brand);
              },
              style: FilledButton.styleFrom(
                backgroundColor: isSelected ? p.accent : p.ink,
                foregroundColor: isSelected ? p.onAccent : p.canvas,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 16,
                ),
              ),
              child: AnimatedSwitcher(
                duration: LuxeMotion.fast,
                child: Row(
                  key: ValueKey(isSelected),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check_rounded, size: 18, color: p.onAccent),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        isSelected ? '$brand selected' : 'Shop $brand',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(
                          isSelected ? p.onAccent : p.canvas,
                          size: 14,
                        ),
                      ),
                    ),
                    if (!isSelected) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: p.canvas,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One watch on the [LuxeWheel]: neighbours sink along the arc and lean
/// outward, like the shape dials.
class _BrandWatchItem extends StatelessWidget {
  const _BrandWatchItem({
    required this.controller,
    required this.index,
    required this.fallbackPage,
    required this.brand,
    required this.clock,
    required this.selected,
    required this.onTap,
  });

  final PageController controller;
  final int index;
  final double fallbackPage;
  final String brand;
  final ValueNotifier<double> clock;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final flagship = WatchFlagship.of(brand);
    return LuxeWheelItem(
      controller: controller,
      index: index,
      fallbackPage: fallbackPage,
      child: Semantics(
        button: true,
        selected: selected,
        label: flagship == null ? brand : '$brand ${flagship.model}',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (flagship != null)
                      WatchDial(style: flagship.style, clock: clock, size: size)
                    else
                      Text(
                        brand,
                        textAlign: TextAlign.center,
                        style: LuxeType.label(p.ink, size: 13),
                      ),
                    Positioned(
                      top: (constraints.maxHeight - size) / 2 + 2,
                      right: (constraints.maxWidth - size) / 2 + 2,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: LuxeMotion.medium,
                        curve: LuxeMotion.settle,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent,
                            border: Border.all(color: p.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: p.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Jeweller's-loupe ring of fine graduations, no plate (same treatment as
/// the shape dials).
class _LoupePainter extends CustomPainter {
  _LoupePainter({
    required this.rotation,
    required this.color,
    required this.hairline,
  });

  final double rotation;
  final Color color;
  final Color hairline;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = hairline,
    );
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.7);
    for (var i = 0; i < 72; i++) {
      final a = rotation + i * math.pi * 2 / 72;
      final major = i % 6 == 0;
      tick.strokeWidth = major ? 1.4 : 0.8;
      final inner = r - (major ? 12 : 8);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * (r - 3),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_LoupePainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.hairline != hairline;
}

/// Category chips shown directly under the search bar.
class WatchCategoryChips extends ConsumerWidget {
  const WatchCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.categories));
    return LuxeQuickChips<String>(
      chips: [
        for (final c in WatchFilterState.categoryOptions)
          LuxeQuickChip(value: c, label: c),
      ],
      isSelected: selected.contains,
      onTap: ref.read(watchFilterProvider.notifier).toggleCategory,
    );
  }
}

Future<void> showWatchBrandsDirectory(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg(context),
    builder: (context) => const WatchBrandsDirectorySheet(),
  );
}

class WatchBrandsDirectorySheet extends ConsumerStatefulWidget {
  const WatchBrandsDirectorySheet({super.key});

  @override
  ConsumerState<WatchBrandsDirectorySheet> createState() =>
      _WatchBrandsDirectorySheetState();
}

class _WatchBrandsDirectorySheetState
    extends ConsumerState<WatchBrandsDirectorySheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(watchFilterProvider.select((s) => s.brands));
    final muted = AppColors.textMuted(context);

    final filtered = _query.isEmpty
        ? watchBrandCategories
        : watchBrandCategories
              .map(
                (g) => WatchBrandLetterGroup(
                  letter: g.letter,
                  brands: g.brands
                      .where(
                        (b) => b.toLowerCase().contains(_query.toLowerCase()),
                      )
                      .toList(),
                ),
              )
              .where((g) => g.brands.isNotEmpty)
              .toList();

    return AppKeyboardInset(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight * 0.92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch Brands',
                              style: AppTypography.headline.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              'Search and select brands.',
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.field(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: context.tr(CatalogL10n.searchBrands),
                          prefixIcon: Icon(
                            Icons.search,
                            color: muted,
                            size: 20,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 44,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: muted,
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (selected.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${selected.length} selected',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.bronze,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => ref
                              .read(watchFilterProvider.notifier)
                              .clearBrands(),
                          child: Text(context.tr(CatalogL10n.clear)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No brands match "$_query"',
                            style: AppTypography.body.copyWith(color: muted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.s40,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final group = filtered[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: AppColors.surface(context),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.s8,
                                  ),
                                  child: Text(
                                    group.letter,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                for (final brand in group.brands)
                                  ListTile(
                                    title: Text(
                                      brand,
                                      style: AppTypography.label.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: AppColors.bronze,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      final encodedBrand = Uri.encodeComponent(
                                        brand,
                                      );
                                      context.push(
                                        '/watches/brand/$encodedBrand',
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.charcoal,
                        foregroundColor: AppColors.warmWhite,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        selected.isEmpty
                            ? context.tr(CatalogL10n.done)
                            : context.tr(CatalogL10n.applyBrandCount, {
                                'count': selected.length,
                                'brandLabel': context.tr(
                                  selected.length == 1
                                      ? CatalogL10n.brand
                                      : CatalogL10n.brands,
                                ),
                              }),
                        style: AppTypography.label.copyWith(
                          color: AppColors.warmWhite,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
