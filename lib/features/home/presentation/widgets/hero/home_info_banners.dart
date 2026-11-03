import 'dart:async';

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
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.route,
    required this.tint,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final String route;

  /// Glow behind the icon, so each slide reads apart from the next.
  final Color tint;
}

const _slides = [
  _InfoSlide(
    icon: Icons.diamond_outlined,
    title: HomeL10n.infoAboutTitle,
    body: HomeL10n.infoAboutBody,
    action: HomeL10n.infoAboutAction,
    route: AppRouteNames.aboutUs,
    tint: Color(0xFFC9A45C),
  ),
  _InfoSlide(
    icon: Icons.verified_outlined,
    title: HomeL10n.infoCertifiedTitle,
    body: HomeL10n.infoCertifiedBody,
    action: HomeL10n.infoCertifiedAction,
    route: AppRouteNames.diamonds,
    tint: Color(0xFF7FA7C9),
  ),
  _InfoSlide(
    icon: Icons.sensors_rounded,
    title: HomeL10n.infoLiveTitle,
    body: HomeL10n.infoLiveBody,
    action: HomeL10n.infoLiveAction,
    route: AppRouteNames.liveShows,
    tint: Color(0xFFC97F7F),
  ),
  _InfoSlide(
    icon: Icons.auto_stories_outlined,
    title: HomeL10n.infoLearnTitle,
    body: HomeL10n.infoLearnBody,
    action: HomeL10n.infoLearnAction,
    route: AppRouteNames.diamondEducation,
    tint: Color(0xFF8FBFA4),
  ),
  _InfoSlide(
    icon: Icons.lock_outline_rounded,
    title: HomeL10n.infoSecureTitle,
    body: HomeL10n.infoSecureBody,
    action: HomeL10n.infoSecureAction,
    route: AppRouteNames.policies,
    tint: Color(0xFFB49BD1),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _InfoFace(
                  slide: _slides[i % _slides.length],
                  tablet: tablet,
                ),
              ),
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
                  color: i == active
                      ? HomeStage.gold
                      : HomeStage.ink.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Dark stage card: tinted glow and large icon on the right, copy and the
/// action on the left, a small GemWorld tag in the corner.
class _InfoFace extends StatelessWidget {
  const _InfoFace({required this.slide, required this.tablet});

  final _InfoSlide slide;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final title = context.tr(slide.title);

    void open() {
      AppHaptics.selection();
      context.push(slide.route);
    }

    return Semantics(
      button: true,
      label: '$title. ${context.tr(slide.body)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HomeStage.raised, HomeStage.obsidian],
            ),
            border: Border.all(color: HomeStage.gold.withValues(alpha: 0.22)),
            borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.75, 0),
                      radius: 0.9,
                      colors: [
                        slide.tint.withValues(alpha: 0.28),
                        slide.tint.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: tablet ? 48 : 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    slide.icon,
                    size: tablet ? 88 : 64,
                    color: slide.tint.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _InfoTag(label: context.tr(HomeL10n.infoTag)),
              ),
              Positioned(
                left: 16,
                top: 12,
                bottom: 12,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width * (tablet ? 0.5 : 0.6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.display(
                          tablet ? 26 : 20,
                          Colors.white,
                        ).copyWith(height: 1.1),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.tr(slide.body),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.label(
                          const Color(0xD9FFFFFF),
                          size: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ActionChip(label: context.tr(slide.action), onTap: open),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: HomeStage.gold.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: HomeType.label(HomeStage.gold, size: 10.5)),
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
              style: HomeType.label(const Color(0xFF16140F), size: 12.5),
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
