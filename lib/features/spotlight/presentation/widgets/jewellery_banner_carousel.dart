import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// JEWELLERY_HOME_BANNER: paid banners on the jewellery home, one at a
/// time, turning every 6.5 s while at least half of the strip is on screen.
///
/// The seller's words are drawn over the image, never baked into it: on
/// phones at the bottom-left over a bottom-up gradient (the top band holds
/// the pill and the controls), on wider screens centred on the left 60%. A
/// long title makes the strip taller instead of being cut, and every banner
/// shares the tallest one's height. Draws nothing when none is running.
class JewelleryBannerCarousel extends ConsumerStatefulWidget {
  const JewelleryBannerCarousel({
    super.key,
    this.padding = EdgeInsets.zero,
    this.visit,
  });

  final EdgeInsets padding;

  /// The screen's visit, so each banner's view counts once per visit.
  final SpotlightVisit? visit;

  static const SpotlightQuery query = (
    placement: SpotlightPlacement.jewelleryHomeBanner,
    category: null,
    excludeProductId: null,
    limit: null,
  );

  /// 4:1 wide image from this width up, 2:1 phone image below it.
  static const wideFrom = 600.0;

  @override
  ConsumerState<JewelleryBannerCarousel> createState() =>
      _JewelleryBannerCarouselState();
}

class _JewelleryBannerCarouselState
    extends ConsumerState<JewelleryBannerCarousel> {
  static const _interval = Duration(milliseconds: 6500);

  /// Pages are virtual (index % count) so the carousel always moves forward.
  static const _origin = 10000;

  final _controller = PageController(initialPage: _origin);
  final _key = UniqueKey();
  late final SpotlightVisit _ownVisit = SpotlightVisit();
  Timer? _timer;
  int _count = 0;
  int _page = _origin;
  bool _touching = false;
  bool _paused = false;
  bool _halfVisible = false;

  SpotlightVisit get _visit => widget.visit ?? _ownVisit;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_count < 2 || _touching || _paused || !_halfVisible) return;
    _timer = Timer.periodic(_interval, (_) => _go(1));
  }

  void _go(int delta) {
    if (!mounted || !_controller.hasClients) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final next = (_controller.page?.round() ?? _page) + delta;
    if (reduce) {
      _controller.jumpToPage(next);
    } else {
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: LuxeMotion.settle,
      );
    }
  }

  void _step(int delta) {
    AppHaptics.selection();
    _go(delta);
    // A manual turn restarts the wait for the next automatic one.
    _schedule();
  }

  void _setTouching(bool value) {
    if (_touching == value) return;
    _touching = value;
    _schedule();
  }

  void _onVisibility(VisibilityInfo info) {
    final half = info.visibleFraction >= 0.5;
    if (!mounted || half == _halfVisible) return;
    _halfVisible = half;
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final banners = spotlightItemsOf<SpotlightBanner>(
      ref.watch(spotlightProvider(JewelleryBannerCarousel.query)),
    );
    if (banners.length != _count) {
      _count = banners.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _schedule();
      });
    }
    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: VisibilityDetector(
        key: _key,
        onVisibilityChanged: _onVisibility,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final wide = width >= JewelleryBannerCarousel.wideFrom;
            final layout = _BannerLayout(
              context: context,
              width: width,
              wide: wide,
            );
            final height = banners.fold<double>(
              width / (wide ? 4 : 2),
              (h, b) => math.max(h, layout.heightFor(b)),
            );
            final active = _page % banners.length;

            return Listener(
              onPointerDown: (_) => _setTouching(true),
              onPointerUp: (_) => _setTouching(false),
              onPointerCancel: (_) => _setTouching(false),
              child: SizedBox(
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (banners.length == 1)
                        _slide(banners.first, layout)
                      else
                        PageView.builder(
                          controller: _controller,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) =>
                              _slide(banners[i % banners.length], layout),
                        ),
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: SpotlightSponsoredPill(),
                      ),
                      if (banners.length > 1)
                        Positioned(
                          top: 6,
                          left: 8,
                          child: _Controls(
                            count: banners.length,
                            active: active,
                            paused: _paused,
                            onPrevious: () => _step(-1),
                            onNext: () => _step(1),
                            onPause: () {
                              AppHaptics.selection();
                              setState(() => _paused = !_paused);
                              _schedule();
                            },
                          ),
                        ),
                      // 1 px ads-blue outline around the banner.
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              LuxeSpace.radiusSmall,
                            ),
                            border: Border.all(
                              color: SpotlightColors.blueLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _slide(SpotlightBanner banner, _BannerLayout layout) =>
      SpotlightImpression(
        adId: banner.adId,
        visit: _visit,
        child: _BannerFace(
          banner: banner,
          layout: layout,
          onTap: () {
            AppHaptics.selection();
            openSpotlightBanner(context, ref, banner);
          },
        ),
      );
}

/// Text styles, insets and the height a banner's words need.
class _BannerLayout {
  _BannerLayout({
    required BuildContext context,
    required this.width,
    required this.wide,
  }) : textScaler = MediaQuery.textScalerOf(context),
       textDirection = Directionality.of(context);

  final double width;
  final bool wide;
  final TextScaler textScaler;
  final TextDirection textDirection;

  /// Band above the words on phones, kept for the pill and the controls.
  static const topBand = 44.0;
  static const inset = 16.0;
  static const buttonHeight = 32.0;

  TextStyle get titleStyle =>
      LuxeType.display(wide ? 28 : 22, Colors.white).copyWith(height: 1.12);

  TextStyle get subtitleStyle => LuxeType.label(
    const Color(0xE6FFFFFF),
    size: wide ? 14 : 13,
  ).copyWith(height: 1.3);

  /// Width the words may take.
  double get textWidth => wide ? width * 0.6 - inset * 1.5 : width - inset * 2;

  double _measure(String text, TextStyle style, {int? maxLines}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: maxLines,
    )..layout(maxWidth: math.max(1, textWidth));
    final h = painter.height;
    painter.dispose();
    return h;
  }

  /// Height [banner] needs so nothing is cut off.
  double heightFor(SpotlightBanner banner) {
    final subtitle = banner.subtitle?.trim() ?? '';
    final words =
        _measure(banner.title, titleStyle) +
        (subtitle.isEmpty
            ? 0
            : 6 + _measure(subtitle, subtitleStyle, maxLines: 2)) +
        12 +
        textScaler.scale(buttonHeight);
    return wide ? words + inset * 2 : topBand + words + inset;
  }
}

class _BannerFace extends StatelessWidget {
  const _BannerFace({
    required this.banner,
    required this.layout,
    required this.onTap,
  });

  final SpotlightBanner banner;
  final _BannerLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final wide = layout.wide;
    final subtitle = banner.subtitle?.trim() ?? '';
    final sellerName = banner.seller?.name.trim() ?? '';
    final actionLabel = banner.link.opensListing
        ? context.tr(SpotlightL10n.viewThePiece)
        : sellerName.isEmpty
        ? context.tr(SpotlightL10n.visitShop)
        : context.tr(SpotlightL10n.visitNamed, {'name': sellerName});

    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(banner.title, style: layout.titleStyle),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: layout.subtitleStyle,
          ),
        ],
        const SizedBox(height: 12),
        _ActionChip(label: actionLabel, onTap: onTap),
      ],
    );

    return Semantics(
      button: true,
      label: '${context.tr(SpotlightL10n.sponsored)}. ${banner.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: p.surfaceRaised,
              child: AppNetworkImage(
                url: wide ? banner.imageUrl : banner.mobileImageUrl,
                memCacheWidth: (layout.width * dpr).round(),
                error: const SizedBox.shrink(),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: wide
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0, 0.45, 0.8],
                        colors: [
                          Color(0xD9000000),
                          Color(0x8C000000),
                          Color(0x00000000),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: [0, 0.55, 1],
                        colors: [
                          Color(0xE0000000),
                          Color(0x66000000),
                          Color(0x26000000),
                        ],
                      ),
              ),
            ),
            if (wide)
              Positioned(
                left: _BannerLayout.inset,
                top: _BannerLayout.inset,
                bottom: _BannerLayout.inset,
                width: layout.textWidth,
                child: Align(alignment: Alignment.centerLeft, child: words),
              )
            else
              Positioned(
                left: _BannerLayout.inset,
                right: _BannerLayout.inset,
                bottom: _BannerLayout.inset,
                child: words,
              ),
          ],
        ),
      ),
    );
  }
}

/// Dots with previous, pause and next, on a frosted chip.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.count,
    required this.active,
    required this.paused,
    required this.onPrevious,
    required this.onNext,
    required this.onPause,
  });

  final int count;
  final int active;
  final bool paused;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, VoidCallback onTap) =>
        Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          child: InkResponse(
            onTap: onTap,
            radius: 18,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
        );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: ShapeDecoration(
          color: const Color(0x59000000),
          shape: StadiumBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Icons.chevron_left_rounded,
              context.tr(SpotlightL10n.previous),
              onPrevious,
            ),
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: LuxeMotion.fast,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == active ? 14 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: i == active ? Colors.white : const Color(0x80FFFFFF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            button(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              context.tr(paused ? SpotlightL10n.play : SpotlightL10n.pause),
              onPause,
            ),
            button(
              Icons.chevron_right_rounded,
              context.tr(SpotlightL10n.next),
              onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.textScalerOf(
            context,
          ).scale(_BannerLayout.buttonHeight),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(const Color(0xFF16140F), size: 13),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF16140F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
