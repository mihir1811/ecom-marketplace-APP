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
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../domain/models/product_detail.dart';
import '../../product_detail_navigation.dart';
import '../screens/luxe_product_detail_screen.dart';
import '../widgets/luxe/luxe_detail_gallery.dart';
import '../widgets/luxe/luxe_detail_parts.dart';
import 'product_gem_dock.dart';
import 'product_sheet_launch.dart';

/// Scroll distance over which the pop-up grows into a full screen.
const double _kGrowDistance = 340;

/// Content never gets wider than a phone; wider windows centre it.
const double _kMaxContentWidth = 560;

/// Space between the pop-up's edges and the screen.
const double _kSideInset = 14;

const Curve _kOpenCurve = Cubic(0.22, 1, 0.36, 1);
const Curve _kCloseCurve = Cubic(0.4, 0, 0.2, 1);

/// Product detail as a pop-up that grows out of the tapped card.
///
/// It opens as an inset rounded sheet above a dimmed, softly blurred list.
/// Scrolling up widens the sheet until it is the full screen, and scrolling
/// back (or pulling down) lets it shrink again and finally fall back into
/// its card. When it was opened from a list, a gem dock below the sheet
/// switches between that list's products with a continuous transition.
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
  late int _index = _set?.initialIndex ?? 0;
  int _dir = 1;
  bool _switched = false;

  /// Growth (0 pop-up … 1 full screen) read straight off the scroll offset.
  final _scrollGrowth = ValueNotifier<double>(0);

  /// Growth the frame actually uses: the scroll value, eased across a
  /// product switch so the new page does not make the sheet jump.
  final _growth = ValueNotifier<double>(0);
  final _pull = ValueNotifier<double>(0);

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 880),
    value: 1,
  );
  late final AnimationController _pullBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  double _growthFrom = 0;
  double _pullFrom = 0;
  bool _dismissing = false;
  Animation<double> _route = kAlwaysCompleteAnimation;
  final _viewed = <String>{};

  ProductSheetOrigin? get _origin => widget.launch.origin;

  ProductDetail get _detail => _set?.detailAt(_index) ?? widget.detail;

  @override
  void initState() {
    super.initState();
    _scrollGrowth.addListener(_updateGrowth);
    _settle.addListener(_updateGrowth);
    _pullBack.addListener(() {
      _pull.value =
          _pullFrom * (1 - Curves.easeOutCubic.transform(_pullBack.value));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView(_detail));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context)?.animation ?? kAlwaysCompleteAnimation;
  }

  @override
  void dispose() {
    _scrollGrowth.dispose();
    _growth.dispose();
    _pull.dispose();
    _settle.dispose();
    _pullBack.dispose();
    _origin?.dispose();
    super.dispose();
  }

  void _updateGrowth() {
    final raw = _scrollGrowth.value;
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
    _scrollGrowth.value = (offset / _kGrowDistance).clamp(0.0, 1.0);
  }

  void _switchTo(int index) {
    final set = _set;
    if (set == null || index == _index || index < 0 || index >= set.length) {
      return;
    }
    _dir = index > _index ? 1 : -1;
    _growthFrom = _growth.value;
    _settle.forward(from: 0);
    _scrollGrowth.value = 0;
    setState(() {
      _index = index;
      _switched = index != set.initialIndex;
    });
    final next = set.detailAt(index);
    rememberProductDetail(next);
    _recordView(next);
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

  // Pulling the sheet down at the top of its content dismisses it.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical || _dismissing) {
      return false;
    }
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      _pullBack.stop();
      _pull.value = math.min(_pull.value - n.overscroll, 260);
    } else if (n is ScrollUpdateNotification && _pull.value > 0) {
      final delta = n.scrollDelta ?? 0;
      if (delta > 0) _pull.value = math.max(0, _pull.value - delta);
    }
    return false;
  }

  void _onPointerUp(PointerEvent _) {
    if (_pull.value <= 0 || _dismissing) return;
    if (_pull.value > 90) {
      AppHaptics.light();
      _close();
    } else {
      _pullFrom = _pull.value;
      _pullBack.forward(from: 0);
    }
  }

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

  Widget _buildFrame(BuildContext context, Size screen) {
    final p = LuxePalette.of(context);
    final safe = MediaQuery.paddingOf(context);
    final set = _set;
    final contentWidth = math.min(screen.width, _kMaxContentWidth);
    final popupWidth = contentWidth - _kSideInset * 2;
    final popup = Rect.fromLTRB(
      (screen.width - popupWidth) / 2,
      safe.top + 18,
      (screen.width + popupWidth) / 2,
      screen.height -
          safe.bottom -
          (set == null ? 18 : kProductGemDockHeight + 14),
    );
    final full = Offset.zero & screen;
    final origin = _origin;
    final fallback = Rect.fromCenter(
      center: popup.center,
      width: popup.width * 0.5,
      height: popup.height * 0.4,
    );

    final stage = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: _stage(contentWidth, safe),
    );

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
          AnimatedBuilder(
            animation: Listenable.merge([_route, _growth, _pull]),
            child: stage,
            builder: (context, child) {
              final t = _route.value;
              final open = _eased(_route);
              final grow = Curves.easeInOutCubic.transform(_growth.value);
              final target = Rect.lerp(popup, full, grow)!;
              // After switching products the sheet no longer matches its
              // card, so it settles back into the screen instead.
              final from = origin == null
                  ? fallback
                  : _switched
                  ? popup.deflate(40)
                  : origin.rect;
              final pullDy = _pull.value * 0.7 * open;
              final rect = Rect.lerp(
                from,
                target,
                open,
              )!.shift(Offset(0, pullDy));
              final radius = ui.lerpDouble(
                ui.lerpDouble(origin?.radius ?? 28, 30, open)!,
                0,
                grow,
              )!;
              final contentAlpha = const Interval(
                0.1,
                0.55,
                curve: Curves.easeOut,
              ).transform(t);
              final cardAlpha = 1 - const Interval(0, 0.5).transform(t);
              // Until the card's pixels arrive, do not paint over the card.
              final backdropAlpha = origin?.snapshot.value != null
                  ? 1.0
                  : math.max(contentAlpha, (t / 0.3).clamp(0.0, 1.0));
              final shrink = 1 - 0.04 * (_pull.value / 200).clamp(0.0, 1.0);
              final borderRadius = BorderRadius.circular(radius);

              return Positioned.fromRect(
                rect: rect,
                child: Transform.scale(
                  scale: shrink,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.32 * open * (1 - grow),
                          ),
                          blurRadius: 44,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: ColoredBox(
                        color: p.canvas.withValues(alpha: backdropAlpha),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: contentAlpha,
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minWidth: contentWidth,
                                maxWidth: contentWidth,
                                minHeight: math.max(rect.height, popup.height),
                                maxHeight: math.max(rect.height, popup.height),
                                child: child,
                              ),
                            ),
                            if (origin != null && cardAlpha > 0.01)
                              _CardSnapshot(origin: origin, opacity: cardAlpha),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (set != null)
            AnimatedBuilder(
              animation: Listenable.merge([_route, _growth]),
              child: Align(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _kMaxContentWidth,
                  ),
                  child: ProductGemDock(
                    count: set.length,
                    index: _index,
                    detailAt: set.detailAt,
                    onSelected: _switchTo,
                  ),
                ),
              ),
              builder: (context, dock) {
                final dockIn = const Interval(
                  0.5,
                  1,
                  curve: Curves.easeOutBack,
                ).transform(_route.value);
                final hide = (_growth.value * 2.5).clamp(0.0, 1.0);
                final visible = (dockIn.clamp(0.0, 1.0)) * (1 - hide);
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: safe.bottom + 4,
                  height: kProductGemDockHeight,
                  child: IgnorePointer(
                    ignoring: visible < 0.6,
                    // Hidden docks stop their idle shimmer.
                    child: TickerMode(
                      enabled: visible > 0.01,
                      child: Opacity(
                        opacity: visible.clamp(0.0, 1.0),
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

  double _eased(Animation<double> a) {
    final curve = a.status == AnimationStatus.reverse
        ? _kCloseCurve
        : _kOpenCurve;
    return curve.transform(a.value.clamp(0.0, 1.0));
  }

  /// The product page, cross-moving when the dock selects another product.
  Widget _stage(double contentWidth, EdgeInsets safe) {
    final detail = _detail;
    final key = ValueKey<String>('${detail.segment.slug}:${detail.id}');
    final dir = _dir.toDouble();

    Widget transition(Widget child, Animation<double> a) {
      final incoming = child.key == key;
      return AnimatedBuilder(
        animation: a,
        child: child,
        builder: (context, child) {
          final v = a.value;
          if (incoming) {
            // Rises out of the dock, swinging in from the swipe direction.
            final scale = 0.86 + 0.14 * v;
            return Opacity(
              opacity: Curves.easeOut.transform(v.clamp(0.0, 1.0)),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(dir * 110 * (1 - v), 150 * (1 - v), 0, 1)
                  ..rotateZ(dir * 0.07 * (1 - v))
                  ..scaleByDouble(scale, scale, 1, 1),
                child: child,
              ),
            );
          }
          final scale = 0.88 + 0.12 * v;
          return IgnorePointer(
            child: Opacity(
              opacity: Curves.easeIn.transform(v.clamp(0.0, 1.0)),
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translateByDouble(-dir * 150 * (1 - v), -36 * (1 - v), 0, 1)
                  ..rotateZ(-dir * 0.09 * (1 - v))
                  ..scaleByDouble(scale, scale, 1, 1),
                child: child,
              ),
            ),
          );
        },
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 880),
          reverseDuration: const Duration(milliseconds: 700),
          switchInCurve: const Cubic(0.3, 0.7, 0.1, 1),
          switchOutCurve: Curves.easeInOutCubic,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: transition,
          child: _SheetPage(
            key: key,
            detail: detail,
            growth: _growth,
            contentWidth: contentWidth,
            safe: safe,
            onScroll: _onPageScroll,
          ),
        ),
        // A soft glint sweeps across the sheet as the product changes.
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _settle,
            builder: (context, _) {
              final v = _settle.value;
              if (v >= 1 || v <= 0) return const SizedBox.shrink();
              final x = -1.8 + 3.6 * Curves.easeInOut.transform(v);
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(x - 0.7, -0.4),
                    end: Alignment(x + 0.7, 0.4),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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

/// One product's page inside the sheet: scrolling gallery, summary and
/// record under a floating header, with the purchase bar pinned below.
class _SheetPage extends ConsumerStatefulWidget {
  const _SheetPage({
    required this.detail,
    required this.growth,
    required this.contentWidth,
    required this.safe,
    required this.onScroll,
    super.key,
  });

  final ProductDetail detail;
  final ValueListenable<double> growth;
  final double contentWidth;
  final EdgeInsets safe;
  final ValueChanged<double> onScroll;

  @override
  ConsumerState<_SheetPage> createState() => _SheetPageState();
}

class _SheetPageState extends ConsumerState<_SheetPage> {
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      _offset.value = _scroll.offset;
      widget.onScroll(_scroll.offset);
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
    final s = luxeProductSections(context, ref, widget.detail);
    final safe = widget.safe;

    return ColoredBox(
      color: p.canvas,
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
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverList.list(
                          children: [
                            LuxeDetailGallery(
                              media: s.media,
                              availabilityStatus: s.availabilityStatus,
                              // Clears the glass header; grows with the
                              // status bar once the sheet is full screen.
                              topInset: 56 + safe.top * g,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                              child: s.summary,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                              child: s.record,
                            ),
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
                          solidAfter: widget.contentWidth * 0.75,
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
    );
  }
}
