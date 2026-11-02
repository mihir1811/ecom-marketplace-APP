import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../application/spotlight_providers.dart';
import '../../domain/spotlight_models.dart';
import '../spotlight_navigation.dart';
import 'spotlight_impression.dart';
import 'spotlight_tag.dart';

/// Paid banners (HOME_BANNER, CATEGORY_BANNER): one at a time, moving on
/// every 6.5 seconds and pausing while touched. Draws nothing, not even
/// [padding], when there is no live banner.
class SpotlightBannerCarousel extends ConsumerStatefulWidget {
  const SpotlightBannerCarousel({
    required this.query,
    super.key,
    this.padding = EdgeInsets.zero,
    this.visit,
    this.activeDotColor,
    this.dotColor,
  });

  final SpotlightQuery query;
  final EdgeInsets padding;

  /// Page dot colours; default to the palette's ink and hairline. Pass
  /// light ones when the carousel sits on a dark stage.
  final Color? activeDotColor;
  final Color? dotColor;

  /// The screen's visit, so each banner's view counts once per visit.
  final SpotlightVisit? visit;

  /// Phones show the 2:1 phone image, tablets the 4:1 one.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  @override
  ConsumerState<SpotlightBannerCarousel> createState() =>
      _SpotlightBannerCarouselState();
}

class _SpotlightBannerCarouselState
    extends ConsumerState<SpotlightBannerCarousel> {
  static const _interval = Duration(milliseconds: 6500);

  /// Pages are virtual (index % count) so the carousel always moves forward.
  static const _origin = 10000;

  final _controller = PageController(initialPage: _origin);
  late final SpotlightVisit _ownVisit = SpotlightVisit();
  Timer? _timer;
  int _count = 0;
  int _page = _origin;
  bool _touching = false;

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
    if (_count < 2 || _touching) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!mounted || _touching || !_controller.hasClients) return;
      final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      final next = (_controller.page?.round() ?? _page) + 1;
      if (reduce) {
        _controller.jumpToPage(next);
      } else {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: LuxeMotion.settle,
        );
      }
    });
  }

  void _setTouching(bool value) {
    if (_touching == value) return;
    _touching = value;
    _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final banners = spotlightItemsOf<SpotlightBanner>(
      ref.watch(spotlightProvider(widget.query)),
    );
    if (banners.length != _count) {
      _count = banners.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _schedule();
      });
    }
    if (banners.isEmpty) return const SizedBox.shrink();

    final tablet = SpotlightBannerCarousel.isTablet(context);
    final p = LuxePalette.of(context);
    final active = _page % banners.length;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Listener(
            onPointerDown: (_) => _setTouching(true),
            onPointerUp: (_) => _setTouching(false),
            onPointerCancel: (_) => _setTouching(false),
            child: AspectRatio(
              aspectRatio: tablet ? 4 : 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
                child: banners.length == 1
                    ? _slide(banners.first, tablet)
                    : PageView.builder(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) =>
                            _slide(banners[i % banners.length], tablet),
                      ),
              ),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < banners.length; i++)
                  AnimatedContainer(
                    duration: LuxeMotion.fast,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == active
                          ? (widget.activeDotColor ?? p.ink)
                          : (widget.dotColor ?? p.hairline),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _slide(SpotlightBanner banner, bool tablet) => SpotlightImpression(
    adId: banner.adId,
    visit: _visit,
    child: _BannerFace(
      banner: banner,
      tablet: tablet,
      onTap: () {
        AppHaptics.selection();
        openSpotlightBanner(context, ref, banner);
      },
    ),
  );
}

/// Image, dark gradient from the left, title, subtitle and the action.
class _BannerFace extends StatelessWidget {
  const _BannerFace({
    required this.banner,
    required this.tablet,
    required this.onTap,
  });

  final SpotlightBanner banner;
  final bool tablet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final subtitle = banner.subtitle?.trim();
    final actionLabel = context.tr(
      banner.link.opensProduct ? SpotlightL10n.view : SpotlightL10n.visitShop,
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
                url: tablet ? banner.imageUrl : banner.mobileImageUrl,
                memCacheWidth: (width * dpr).round(),
                error: const SizedBox.shrink(),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, 0.5, 0.9],
                  colors: [
                    Color(0xD9000000),
                    Color(0x80000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 10,
              right: 10,
              child: SpotlightTag(onImage: true),
            ),
            Positioned(
              left: 16,
              top: 12,
              bottom: 12,
              child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width * (tablet ? 0.5 : 0.66),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(
                            tablet ? 26 : 20,
                            Colors.white,
                          ).copyWith(height: 1.1),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            subtitle,
                            maxLines: tablet ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(
                              const Color(0xD9FFFFFF),
                              size: 12.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _ActionChip(label: actionLabel, onTap: onTap),
                      ],
                    ),
                  ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: LuxeType.label(const Color(0xFF16140F), size: 12.5),
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
    );
  }
}
