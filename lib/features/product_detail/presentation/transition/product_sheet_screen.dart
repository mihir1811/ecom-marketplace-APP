import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/theme/luxe_scope.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/product_card_anchor.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/models/product_detail.dart';
import '../../product_detail_navigation.dart';
import '../screens/luxe_product_detail_screen.dart';
import '../widgets/luxe/luxe_detail_gallery.dart';
import '../widgets/luxe/luxe_detail_parts.dart';
import 'product_gem_dock.dart';
import 'product_pager.dart';
import 'product_sheet_launch.dart';

/// Scroll distance over which the pop-up grows into a full screen.
const double _kGrowDistance = 340;

/// Content never gets wider than a phone; wider windows centre it.
const double _kMaxContentWidth = 560;

/// Share of the screen the centre pop-up takes when others peek in beside it.
const double _kCardShare = 0.9;

/// Scale of the pop-ups either side of the centre one.
const double _kSideScale = 0.88;

/// Extra pull past the top of a full-screen page before it shrinks back into
/// the pop-up, so the picture can be looked at without it giving way.
const double _kShrinkBuffer = 64;

/// Space between the centre pop-up and its neighbours.
const double _kPeekGap = 6;

const Curve _kOpenCurve = Cubic(0.22, 1, 0.36, 1);
const Curve _kCloseCurve = Cubic(0.4, 0, 0.2, 1);

/// Product detail as a pop-up that grows out of the tapped card.
///
/// It opens as an inset rounded pop-up above a dimmed, softly blurred list,
/// with the previous and next products peeking in at its sides. Swiping the
/// cards (or the dock below) moves between them; scrolling up widens the
/// centre one until it is the full screen. Closing shrinks it into the card
/// of the product being viewed, which the list has scrolled to.
class ProductSheetScreen extends ConsumerStatefulWidget {
  const ProductSheetScreen({
    required this.detail,
    required this.launch,
    super.key,
  });

  final ProductDetail detail;
  final ProductSheetLaunch launch;

  @override
  ConsumerState<ProductSheetScreen> createState() => _ProductSheetScreenState();
}

class _ProductSheetScreenState extends ConsumerState<ProductSheetScreen>
    with TickerProviderStateMixin {
  late final ProductSwitchSet? _set = widget.launch.switchSet;
  int get _count => _set?.length ?? 1;
  late final int _initial = _set?.initialIndex ?? 0;
  late int _index = _initial;
  late final ProductPager _pager = ProductPager(
    vsync: this,
    count: _count,
    initial: _initial,
    onSettled: _onSettled,
    onStep: (i) {
      AppHaptics.selection();
      // Mid-swipe too, so the next page is in by the time it is reached.
      _set?.reached(i);
    },
  );

  void _onMoreProducts() {
    if (!mounted) return;
    setState(() => _pager.count = _count);
  }

  /// Growth (0 pop-up … 1 full screen) read straight off the scroll offset.
  final _scrollGrowth = ValueNotifier<double>(0);

  /// Growth the cards actually use: the scroll value, eased across a change
  /// of product so the new page does not make the card jump.
  final _growth = ValueNotifier<double>(0);
  final _pull = ValueNotifier<double>(0);

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
    value: 1,
  );
  late final AnimationController _pullBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// The neighbours slide in once the pop-up has finished opening.
  late final AnimationController _peek = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 180),
  );
  bool _peekReady = false;

  double _growthFrom = 0;
  double _pullFrom = 0;
  bool _dismissing = false;
  bool _overscrollDrag = false;

  /// Latched once the page has grown to the full screen; it then stays full
  /// screen, even back at the top of its scroll, until deliberately pulled.
  bool _expanded = false;
  double _shrinkPull = 0;
  bool _shrunkThisDrag = false;
  Animation<double> _route = kAlwaysCompleteAnimation;
  final _viewed = <String>{};

  ProductSheetOrigin? get _origin => widget.launch.origin;

  ProductDetail _detailAt(int i) => _set?.detailAt(i) ?? widget.detail;

  @override
  void initState() {
    super.initState();
    _scrollGrowth.addListener(_updateGrowth);
    _settle.addListener(_updateGrowth);
    _pullBack.addListener(() {
      _pull.value =
          _pullFrom * (1 - Curves.easeOutCubic.transform(_pullBack.value));
    });
    _set?.lengthListenable.addListener(_onMoreProducts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordView(_detailAt(_index));
      // Opened near the end of what is loaded: fetch the next page now.
      _set?.reached(_index);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
    if (!identical(route, _route)) {
      _route.removeStatusListener(_onRouteStatus);
      _route = route..addStatusListener(_onRouteStatus);
      if (_route.status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onRouteStatus(AnimationStatus.completed),
        );
      }
    }
  }

  @override
  void dispose() {
    _set?.lengthListenable.removeListener(_onMoreProducts);
    _route.removeStatusListener(_onRouteStatus);
    _scrollGrowth.dispose();
    _growth.dispose();
    _pull.dispose();
    _settle.dispose();
    _pullBack.dispose();
    _peek.dispose();
    _pager.dispose();
    _origin?.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      if (_set == null || _peekReady) return;
      // Build the neighbours only now so they never compete with the
      // opening morph for frames.
      setState(() => _peekReady = true);
      _peek.forward();
    } else if (status == AnimationStatus.reverse) {
      _peek.reverse();
    }
  }

  void _updateGrowth() {
    final raw = _expanded ? 1.0 : _scrollGrowth.value;
    _growth.value = _settle.isAnimating
        ? ui.lerpDouble(
            _growthFrom,
            raw,
            Curves.easeOutCubic.transform(_settle.value),
          )!
        : raw;
  }

  void _recordView(ProductDetail detail) {
    if (!mounted || !_viewed.add(detail.id)) return;
    if (!ref.read(authProvider).isAuthenticated) return;
    recordRecentlyViewed(
      ref,
      productId: detail.id,
      productType: detail.apiProductType,
    );
  }

  void _onPageScroll(double offset) {
    final growth = (offset / _kGrowDistance).clamp(0.0, 1.0);
    if (growth >= 1) _expanded = true;
    _scrollGrowth.value = growth;
  }

  /// Full screen back to the pop-up, after a pull at the top of the page.
  void _shrink() {
    _expanded = false;
    _shrunkThisDrag = true;
    _shrinkPull = 0;
    AppHaptics.selection();
    _growthFrom = _growth.value;
    _settle.forward(from: 0);
  }

  void _onSettled(int index) {
    if (!mounted || index == _index) return;
    _expanded = false;
    _shrinkPull = 0;
    _growthFrom = _growth.value;
    _settle.forward(from: 0);
    _scrollGrowth.value = 0;
    setState(() => _index = index);
    final detail = _detailAt(index);
    rememberProductDetail(detail);
    _recordView(detail);
    // Bring that product's card into view behind the pop-up, so closing
    // lands on it.
    ProductCardRegistry.reveal(index, _origin?.scrollable);
  }

  void _close() {
    if (_dismissing) return;
    _dismissing = true;
    context.goBack();
    // Navigation can decline (root route); allow another attempt then.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _dismissing = false;
    });
  }

  /// Whether swiping between products is available right now.
  bool get _canSwipe =>
      _count > 1 &&
      !_dismissing &&
      _peek.value > 0.9 &&
      _growth.value < 0.2 &&
      _route.status == AnimationStatus.completed;

  double _slot(double screenWidth, double cardW) {
    final g = Curves.easeInOutCubic.transform(_growth.value);
    final slot0 = cardW * (0.5 + 0.5 * _kSideScale) + _kPeekGap;
    return ui.lerpDouble(slot0, screenWidth, g)!;
  }

  // Pulling the sheet down at the top of its content dismisses it; pushing
  // past the first or last picture carries on to the next product.
  bool _onScroll(ScrollNotification n) {
    if (n.depth > 1 || _dismissing) return false;
    if (n.metrics.axis == Axis.horizontal) {
      if (n is OverscrollNotification &&
          n.dragDetails != null &&
          _canSwipe &&
          _lastSlot > 0) {
        if (!_overscrollDrag) {
          _overscrollDrag = true;
          _pager.dragStart();
        }
        _pager.dragBy(n.overscroll / _lastSlot);
      }
      return false;
    }
    if (n.depth != 0) return false;
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      if (_expanded) {
        _shrinkPull -= n.overscroll;
        if (_shrinkPull > _kShrinkBuffer) _shrink();
        return false;
      }
      // The pull that shrank the page must not also dismiss it.
      if (_shrunkThisDrag) return false;
      _pullBack.stop();
      _pull.value = math.min(_pull.value - n.overscroll, 260);
    } else if (n is ScrollUpdateNotification && _pull.value > 0) {
      final delta = n.scrollDelta ?? 0;
      if (delta > 0) _pull.value = math.max(0, _pull.value - delta);
    }
    return false;
  }

  void _onPointerUp(PointerEvent _) {
    _shrinkPull = 0;
    _shrunkThisDrag = false;
    if (_overscrollDrag) {
      _overscrollDrag = false;
      _pager.dragEnd(0);
    }
    if (_pull.value <= 0 || _dismissing) return;
    if (_pull.value > 90) {
      AppHaptics.light();
      _close();
    } else {
      _pullFrom = _pull.value;
      _pullBack.forward(from: 0);
    }
  }

  double _lastSlot = 0;

  @override
  Widget build(BuildContext context) {
    return LuxeScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) =>
              _buildFrame(context, constraints.biggest),
        ),
      ),
    );
  }

  double _eased(Animation<double> a) {
    final curve = a.status == AnimationStatus.reverse
        ? _kCloseCurve
        : _kOpenCurve;
    return curve.transform(a.value.clamp(0.0, 1.0));
  }

  /// Rectangle of the listing card of the product on show, when it is on
  /// screen.
  Rect? _closeRect(Size screen) {
    final card = ProductCardRegistry.find(
      _pager.nearest,
      _origin?.scrollable,
    )?.rect;
    if (card != null && card.overlaps(Offset.zero & screen)) return card;
    if (_pager.nearest == _initial) return _origin?.rect;
    return null;
  }

  Widget _buildFrame(BuildContext context, Size screen) {
    final safe = MediaQuery.paddingOf(context);
    final set = _set;
    final base = math.min(screen.width, _kMaxContentWidth);
    final cardW = set == null
        ? base - 28
        : (base * _kCardShare).clamp(250.0, 440.0);
    final popup = Rect.fromLTRB(
      (screen.width - cardW) / 2,
      safe.top + 18,
      (screen.width + cardW) / 2,
      screen.height -
          safe.bottom -
          (set == null ? 18 : kProductGemDockHeight + 14),
    );
    final full = Offset.zero & screen;
    _lastSlot = _slot(screen.width, cardW);

    // One stable widget per product, so moving cards never rebuild pages.
    final pages = <int, Widget>{};
    Widget pageFor(int i) => pages.putIfAbsent(i, () {
      final detail = _detailAt(i);
      return _SheetPage(
        key: ValueKey('${detail.segment.slug}:${detail.id}'),
        detail: detail,
        growth: _growth,
        safe: safe,
        active: i == _index,
        onScroll: _onPageScroll,
      );
    });

    final merged = Listenable.merge([
      _route,
      _growth,
      _pull,
      _peek,
      _pager.listenable,
    ]);

    return Listener(
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_route, _growth, _pull]),
            builder: (context, _) {
              final open = _eased(_route);
              final calm = 1 - _growth.value;
              final lift = 1 - (_pull.value / 320).clamp(0.0, 1.0);
              final sigma = 14 * open * calm;
              Widget veil = ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.5 * open * lift * (0.5 + 0.5 * calm),
                ),
              );
              if (sigma > 0.2) {
                veil = BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: veil,
                );
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: veil,
              );
            },
          ),
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) {
                if (_canSwipe) _pager.dragStart();
              },
              onHorizontalDragUpdate: (d) {
                if (_pager.dragging) _pager.dragBy(-d.delta.dx / _lastSlot);
              },
              onHorizontalDragEnd: (d) {
                if (_pager.dragging) {
                  _pager.dragEnd(-d.velocity.pixelsPerSecond.dx / _lastSlot);
                }
              },
              onHorizontalDragCancel: () {
                if (_pager.dragging && !_overscrollDrag) _pager.dragEnd(0);
              },
              child: AnimatedBuilder(
                animation: merged,
                builder: (context, _) => Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: _cards(
                    screen: screen,
                    popup: popup,
                    full: full,
                    cardW: cardW,
                    pageFor: pageFor,
                  ),
                ),
              ),
            ),
          ),
          if (set != null)
            AnimatedBuilder(
              animation: Listenable.merge([_route, _growth]),
              child: Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kMaxContentWidth - 24,
                  ),
                  child: ProductGemDock(pager: _pager, detailAt: set.detailAt),
                ),
              ),
              builder: (context, dock) {
                final dockIn = const Interval(
                  0.5,
                  1,
                  curve: Curves.easeOutBack,
                ).transform(_route.value);
                final hide = (_growth.value * 5).clamp(0.0, 1.0);
                final visible = dockIn.clamp(0.0, 1.0) * (1 - hide);
                return Positioned(
                  left: 12,
                  right: 12,
                  bottom: safe.bottom + 4,
                  height: kProductGemDockHeight,
                  child: IgnorePointer(
                    ignoring: visible < 0.6,
                    // Hidden docks stop their idle shimmer.
                    child: TickerMode(
                      enabled: visible > 0.01,
                      child: Opacity(
                        opacity: visible,
                        child: Transform.translate(
                          offset: Offset(0, (1 - dockIn) * 150 + hide * 40),
                          child: dock,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _cards({
    required Size screen,
    required Rect popup,
    required Rect full,
    required double cardW,
    required Widget Function(int) pageFor,
  }) {
    final p = LuxePalette.of(context);
    final origin = _origin;
    final t = _route.value;
    final closing = _route.status == AnimationStatus.reverse;
    final open = _eased(_route);
    final g = Curves.easeInOutCubic.transform(_growth.value);
    final pos = _pager.position;
    final peek = Curves.easeOutCubic.transform(_peek.value);
    final slot = _slot(screen.width, cardW);
    final rectG = Rect.lerp(popup, full, g)!;

    final shrunk = Rect.fromCenter(
      center: popup.center,
      width: popup.width * 0.5,
      height: popup.height * 0.4,
    );
    final from = closing
        ? (_closeRect(screen) ?? shrunk)
        : (origin?.rect ?? shrunk);
    final pullDy = _pull.value * 0.7 * open;
    final pullScale = 1 - 0.04 * (_pull.value / 200).clamp(0.0, 1.0);
    final nearest = _pager.nearest;

    final contentAlpha = const Interval(
      0.1,
      0.55,
      curve: Curves.easeOut,
    ).transform(t);
    final cardAlpha = 1 - const Interval(0, 0.5).transform(t);
    final snapshotUsable = origin != null && nearest == _initial;
    final bgAlpha = snapshotUsable && origin.snapshot.value != null
        ? 1.0
        : (t / 0.35).clamp(0.0, 1.0);

    // Pages two away stay mounted (hidden) so swiping back never rebuilds
    // their pictures and sections.
    final first = math.max(0, pos.floor() - 2);
    final last = math.min(_count - 1, pos.ceil() + 2);
    final order = <int>[
      for (var i = first; i <= last; i++)
        if (i == _index || _peekReady) i,
    ]..sort((a, b) => (b - pos).abs().compareTo((a - pos).abs()));

    final cards = <Widget>[];
    for (final i in order) {
      final d = i - pos;
      final away = d.abs();
      final main = i == _index;
      var alpha = 1.0;
      if (!main) {
        alpha =
            peek *
            (1 - (g * 4).clamp(0.0, 1.0)) *
            (away > 1 ? ((1.7 - away) / 0.7).clamp(0.0, 1.0) : 1.0);
      }
      final hidden = alpha <= 0.01;
      final scale = 1 - (1 - _kSideScale) * math.min(away, 1.0);
      final rect = (main ? Rect.lerp(from, rectG, open)! : rectG).shift(
        Offset(d * slot, pullDy),
      );
      final radius = ui.lerpDouble(
        main ? ui.lerpDouble(origin?.radius ?? 28, 30, open)! : 30,
        0,
        g,
      )!;
      final borderRadius = BorderRadius.circular(radius);
      final targetW = main ? rectG.width : cardW;
      final contentH = math.max(rect.height, popup.height);

      Widget body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32 * open * (1 - g)),
              blurRadius: 44,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: ColoredBox(
            color: p.canvas.withValues(alpha: main ? bgAlpha : 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: main ? contentAlpha : 1,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minWidth: targetW,
                    maxWidth: targetW,
                    minHeight: contentH,
                    maxHeight: contentH,
                    child: pageFor(i),
                  ),
                ),
                if (main && snapshotUsable && cardAlpha > 0.01)
                  _CardSnapshot(origin: origin, opacity: cardAlpha),
              ],
            ),
          ),
        ),
      );

      // The wrapper chain is identical for every card, so a card turning into
      // the centre one (or back) keeps its page state instead of remounting.
      // Neighbours are a handle: tapping one brings it to the centre.
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: main ? null : () => _pager.animateTo(i),
        child: AbsorbPointer(absorbing: !main, child: body),
      );
      body = Opacity(opacity: alpha.clamp(0.0, 1.0), child: body);
      body = Offstage(offstage: hidden, child: body);

      cards.add(
        Positioned.fromRect(
          key: ValueKey('card-$i'),
          rect: rect,
          child: Transform.scale(scale: scale * pullScale, child: body),
        ),
      );
    }
    return cards;
  }
}

/// The tapped card's pixels, stretched over the growing sheet so the card
/// seems to turn into it (and back).
class _CardSnapshot extends StatelessWidget {
  const _CardSnapshot({required this.origin, required this.opacity});

  final ProductSheetOrigin origin;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image?>(
      valueListenable: origin.snapshot,
      builder: (context, image, _) {
        if (image == null) return const SizedBox.shrink();
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: RawImage(
            image: image,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }
}

double _ease(double g) => Curves.easeInOut.transform(g);

/// One product's page inside a pop-up: scrolling gallery, summary and
/// record under a floating header, with the purchase bar pinned below.
///
/// Pages that are only peeking in at the side skip the long record; it is
/// built once the page becomes the one on show.
class _SheetPage extends ConsumerStatefulWidget {
  const _SheetPage({
    required this.detail,
    required this.growth,
    required this.safe,
    required this.active,
    required this.onScroll,
    super.key,
  });

  final ProductDetail detail;
  final ValueListenable<double> growth;
  final EdgeInsets safe;
  final bool active;
  final ValueChanged<double> onScroll;

  @override
  ConsumerState<_SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends ConsumerState<_SheetPage> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  /// The long record is built the first time the page is on show and kept,
  /// so coming back to a product does not rebuild it.
  bool _recordBuilt = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      _offset.value = _scroll.offset;
      if (widget.active) widget.onScroll(_scroll.offset);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final active = widget.active;
    if (active) _recordBuilt = true;
    // Neighbour pages wait until shown: a full jewelry fetch counts a view.
    final s = luxeProductSections(
      context,
      ref,
      widget.detail,
      loadFull: _recordBuilt,
    );
    final safe = widget.safe;

    return ColoredBox(
      color: p.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(overscroll: false, scrollbars: false),
                      child: ValueListenableBuilder<double>(
                        valueListenable: widget.growth,
                        builder: (context, g, _) => CustomScrollView(
                          controller: _scroll,
                          physics: active
                              ? const ClampingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                )
                              : const NeverScrollableScrollPhysics(),
                          slivers: [
                            SliverList.list(
                              children: [
                                LuxeDetailGallery(
                                  media: s.media,
                                  availabilityStatus: s.availabilityStatus,
                                  // Clears the glass header; grows with the
                                  // status bar once the sheet is full screen.
                                  topInset: (56 + safe.top) * _ease(g),
                                  aspectRatio: ui.lerpDouble(
                                    1.45,
                                    1,
                                    _ease(g),
                                  )!,
                                  thumbsFactor: _ease(g),
                                  clampEnds: true,
                                  badgeTop: ui.lerpDouble(60, 14, _ease(g))!,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    14,
                                    14,
                                    0,
                                  ),
                                  child: s.summary,
                                ),
                                if (_recordBuilt) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      6,
                                      14,
                                      0,
                                    ),
                                    child: s.record,
                                  ),
                                  s.related(20),
                                  const SizedBox(height: 40),
                                ],
                              ],
                            ),
                            // Short records still need enough travel for the
                            // pop-up to reach the full screen.
                            SliverLayoutBuilder(
                              builder: (context, c) => SliverToBoxAdapter(
                                child: SizedBox(
                                  height: math.max(
                                    0,
                                    c.viewportMainAxisExtent +
                                        _kGrowDistance -
                                        c.precedingScrollExtent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder<double>(
                        valueListenable: widget.growth,
                        builder: (context, g, _) {
                          final mq = MediaQuery.of(context);
                          return MediaQuery(
                            data: mq.copyWith(
                              padding: mq.padding.copyWith(top: safe.top * g),
                            ),
                            child: LuxeFloatingHeader(
                              title: s.title,
                              offset: _offset,
                              solidAfter: 260,
                              actions: s.headerActions,
                              leadingIcon: Icons.keyboard_arrow_down_rounded,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (s.bottomBar != null)
                ValueListenableBuilder<double>(
                  valueListenable: widget.growth,
                  builder: (context, g, child) => ColoredBox(
                    color: p.surface,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: safe.bottom * g),
                      child: child,
                    ),
                  ),
                  child: s.bottomBar,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
