import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../spotlight/presentation/widgets/spotlight_banner_carousel.dart';
import '../../theme/home_tokens.dart';

/// GemWorld's own banners (about us, certified diamonds, live shows,
/// learning, secure checkout). The hero shows them while no paid banner is
/// live, in the same 2:1 (tablet 4:1) frame so a paid one swaps in cleanly.
class HomeInfoBanners extends StatefulWidget {
  const HomeInfoBanners({super.key});

  @override
  State<HomeInfoBanners> createState() => _HomeInfoBannersState();
}

class _InfoSlide {
  const _InfoSlide({
    required this.image,
    required this.title,
    required this.body,
    required this.action,
    required this.route,
    required this.background,
  });

  /// Square photo of the product on a plain studio backdrop, shown whole
  /// at the right of the card. Credits in `docs/image-credits.md`.
  final String image;
  final String title;
  final String body;
  final String action;
  final String route;

  /// The photo's own backdrop colour. Each photo's edges were evened out to
  /// exactly this colour, so the card and photo read as one surface.
  final Color background;
}

const _dir = 'public/images/homeHero';

const _slides = [
  _InfoSlide(
    image: '$_dir/about.webp',
    title: HomeL10n.infoAboutTitle,
    body: HomeL10n.infoAboutBody,
    action: HomeL10n.infoAboutAction,
    route: AppRouteNames.aboutUs,
    background: Color(0xFFF1F2F2),
  ),
  _InfoSlide(
    image: '$_dir/certified.webp',
    title: HomeL10n.infoCertifiedTitle,
    body: HomeL10n.infoCertifiedBody,
    action: HomeL10n.infoCertifiedAction,
    route: AppRouteNames.diamonds,
    background: Color(0xFFDBDCE0),
  ),
  _InfoSlide(
    image: '$_dir/live.webp',
    title: HomeL10n.infoLiveTitle,
    body: HomeL10n.infoLiveBody,
    action: HomeL10n.infoLiveAction,
    route: AppRouteNames.liveShows,
    background: Color(0xFFEEEFF1),
  ),
  _InfoSlide(
    image: '$_dir/learn.webp',
    title: HomeL10n.infoLearnTitle,
    body: HomeL10n.infoLearnBody,
    action: HomeL10n.infoLearnAction,
    route: AppRouteNames.diamondEducation,
    background: Color(0xFFDEE0E2),
  ),
  _InfoSlide(
    image: '$_dir/secure.webp',
    title: HomeL10n.infoSecureTitle,
    body: HomeL10n.infoSecureBody,
    action: HomeL10n.infoSecureAction,
    route: AppRouteNames.policies,
    background: Color(0xFFEFF0F0),
  ),
];

class _HomeInfoBannersState extends State<HomeInfoBanners> {
  static const _interval = Duration(milliseconds: 6500);

  /// Pages are virtual (index % count) so the carousel always moves forward.
  static const _origin = 10000;

  final _controller = PageController(initialPage: _origin);
  Timer? _timer;
  int _page = _origin;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_touching) return;
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
          curve: HomeMotion.settle,
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
    final tablet = SpotlightBannerCarousel.isTablet(context);
    final active = _page % _slides.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Listener(
          onPointerDown: (_) => _setTouching(true),
          onPointerUp: (_) => _setTouching(false),
          onPointerCancel: (_) => _setTouching(false),
          child: AspectRatio(
            aspectRatio: tablet ? 4 : 2,
            // Each slide is its own card that travels as a whole. The pager
            // spans the full screen width so a card slides out past the
            // gutter instead of being cropped by a fixed frame, and the
            // gutter becomes the gap between neighbouring cards.
            child: LayoutBuilder(
              builder: (context, box) {
                final screen = MediaQuery.sizeOf(context).width;
                final bleed = ((screen - box.maxWidth) / 2).clamp(
                  0.0,
                  double.infinity,
                );
                final full = box.maxWidth + bleed * 2;

                return OverflowBox(
                  minWidth: full,
                  maxWidth: full,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: bleed),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          HomeSpace.radiusSmall,
                        ),
                        child: _InfoFace(
                          slide: _slides[i % _slides.length],
                          tablet: tablet,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: HomeMotion.fast,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  // Dots sit on the page canvas below the hero stage.
                  color: i == active
                      ? HomePalette.of(context).accent
                      : HomePalette.of(context).ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Split campaign card: the whole photo, uncropped and with no overlay, on
/// the right at full card height, set on its own backdrop colour so there is
/// no seam; headline, one supporting line and a text-link action on the
/// left. No glow, frame or badge, so it reads like a printed campaign rather
/// than a generated tile.
class _InfoFace extends StatelessWidget {
  const _InfoFace({required this.slide, required this.tablet});

  final _InfoSlide slide;
  final bool tablet;

  static const ink = Color(0xFF1C1A17);
  static const inkMuted = Color(0xFF4A453E);

  @override
  Widget build(BuildContext context) {
    final title = context.tr(slide.title);
    final body = context.tr(slide.body);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Semantics(
      button: true,
      label: '$title. $body',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          context.push(slide.route);
        },
        child: ColoredBox(
          color: slide.background,
          child: LayoutBuilder(
            builder: (context, box) {
              // Photos are square: full card height, flush with the right,
              // top and bottom edges, so only their (evened) left edge meets
              // the card colour.
              final photoSide = box.maxHeight;
              final pad = tablet ? 28.0 : 18.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: photoSide,
                    child: ExcludeSemantics(
                      child: Image.asset(
                        slide.image,
                        cacheWidth: (photoSide * dpr).round(),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  Positioned(
                    left: pad,
                    top: pad - 4,
                    bottom: pad - 4,
                    // Copy stays clear of the product, which sits at least a
                    // tenth of the photo in from its left edge.
                    width:
                        math.min(
                          box.maxWidth * (tablet ? 0.52 : 0.56),
                          box.maxWidth - photoSide * 0.92,
                        ) -
                        pad,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.display(
                            tablet ? 28 : 22,
                            ink,
                          ).copyWith(height: 1.05),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.body(
                            inkMuted,
                            size: tablet ? 14 : 12.5,
                          ).copyWith(height: 1.35),
                        ),
                        SizedBox(height: tablet ? 14 : 10),
                        _TextLink(label: context.tr(slide.action)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Underlined action, the way print and luxury retail sites mark a link.
/// The whole card is the tap target, so this is visual only.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _InfoFace.ink)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: HomeType.label(
                _InfoFace.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 14, color: _InfoFace.ink),
          ],
        ),
      ),
    );
  }
}
