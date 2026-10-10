import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../theme/home_tokens.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.accent,
    required this.tag,
    required this.title,
    required this.body,
    required this.cta,
    required this.route,
    this.live = false,
  });

  final IconData icon;
  final Color accent;
  final String tag;
  final String title;
  final String body;
  final String cta;
  final String route;
  final bool live;
}

const _slides = [
  _Slide(
    icon: Icons.gavel_rounded,
    accent: Color(0xFFE0B25C),
    tag: HomeL10n.spotlightAuctionsTag,
    title: HomeL10n.spotlightAuctionsTitle,
    body: HomeL10n.spotlightAuctionsBody,
    cta: HomeL10n.spotlightBid,
    route: AppRouteNames.auctions,
    live: true,
  ),
  _Slide(
    icon: Icons.diamond_outlined,
    accent: Color(0xFF9CC9E8),
    tag: HomeL10n.spotlightDiamondsTag,
    title: HomeL10n.spotlightDiamondsTitle,
    body: HomeL10n.spotlightDiamondsBody,
    cta: HomeL10n.spotlightExplore,
    route: AppRouteNames.diamonds,
  ),
  _Slide(
    icon: Icons.auto_awesome_outlined,
    accent: Color(0xFF6FC7A4),
    tag: HomeL10n.spotlightGemstonesTag,
    title: HomeL10n.spotlightGemstonesTitle,
    body: HomeL10n.spotlightGemstonesBody,
    cta: HomeL10n.spotlightExplore,
    route: AppRouteNames.gemstones,
  ),
  _Slide(
    icon: Icons.science_outlined,
    accent: Color(0xFFB9A3E8),
    tag: HomeL10n.spotlightLabTag,
    title: HomeL10n.spotlightLabTitle,
    body: HomeL10n.spotlightLabBody,
    cta: HomeL10n.spotlightExplore,
    route: AppRouteNames.labGrownDiamonds,
  ),
  _Slide(
    icon: Icons.account_balance_outlined,
    accent: Color(0xFFF0C987),
    tag: HomeL10n.spotlightBullionTag,
    title: HomeL10n.spotlightBullionTitle,
    body: HomeL10n.spotlightBullionBody,
    cta: HomeL10n.spotlightExplore,
    route: AppRouteNames.bullions,
  ),
];

/// Hero foot: a self-advancing banner carousel of what's worth opening now,
/// above a compact trust strip.
class HeroSpotlight extends StatefulWidget {
  const HeroSpotlight({required this.animate, required this.gutter, super.key});

  final bool animate;
  final double gutter;

  @override
  State<HeroSpotlight> createState() => _HeroSpotlightState();
}

class _HeroSpotlightState extends State<HeroSpotlight> {
  static const _interval = Duration(milliseconds: 4800);
  static const _cardHeight = 150.0;
  // Large and a multiple of the slide count so paging loops both ways.
  static const _origin = 1000;

  PageController? _controller;
  double _fraction = 0;
  final _index = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    // Card spans the gutters; the next banner peeks in at the edge.
    final fraction = ((width - widget.gutter * 2 + 10) / width).clamp(0.5, 1.0);
    if (_controller == null || fraction != _fraction) {
      final page = _controller?.hasClients == true
          ? _controller!.page?.round() ?? _origin
          : _origin;
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(
        initialPage: page,
        viewportFraction: fraction,
      );
    }
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (!widget.animate) return;
    _timer = Timer.periodic(_interval, (_) {
      final c = _controller;
      if (!mounted || c == null || !c.hasClients) return;
      final page = c.page?.round() ?? _origin;
      c.animateToPage(
        page + 1,
        duration: const Duration(milliseconds: 900),
        curve: HomeMotion.settle,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _index.dispose();
    super.dispose();
  }

  Widget _enter(Widget child, int delayMs) {
    if (!widget.animate) return child;
    return child
        .animate(delay: delayMs.ms)
        .fadeIn(duration: 800.ms, curve: HomeMotion.settle)
        .moveY(begin: 16, end: 0, duration: 900.ms, curve: HomeMotion.settle);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _enter(
          SizedBox(
            height: _cardHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                // A finger on the banners holds the auto-advance.
                if (n is ScrollStartNotification && n.dragDetails != null) {
                  _timer?.cancel();
                } else if (n is ScrollEndNotification) {
                  _restart();
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => _index.value = i % _slides.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _SpotlightCard(
                    slide: _slides[i % _slides.length],
                    animate: widget.animate,
                  ),
                ),
              ),
            ),
          ),
          500,
        ),
        const SizedBox(height: 12),
        _enter(
          ValueListenableBuilder<int>(
            valueListenable: _index,
            builder: (context, current, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: HomeMotion.medium,
                    curve: HomeMotion.settle,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == current ? 18 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == current
                          ? HomeStage.gold
                          : HomeStage.ink.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          650,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.gutter),
          child: _enter(const _TrustStrip(), 800),
        ),
      ],
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.slide, required this.animate});

  final _Slide slide;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;
    final radius = BorderRadius.circular(HomeSpace.radius);

    return Semantics(
      button: true,
      label: '${context.tr(slide.title)}. ${context.tr(slide.body)}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: accent.withValues(alpha: 0.32)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accent.withValues(alpha: 0.2),
                  HomeStage.obsidian.withValues(alpha: 0.72),
                ),
                HomeStage.obsidian.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: InkWell(
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.06),
            onTap: () {
              AppHaptics.selection();
              context.openRoute(slide.route);
            },
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(
                    slide.icon,
                    size: 128,
                    color: accent.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Tag(
                        label: context.tr(slide.tag),
                        accent: accent,
                        live: slide.live,
                        animate: animate,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr(slide.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.display(24, HomeStage.ink),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 56),
                        child: Text(
                          context.tr(slide.body),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.body(HomeStage.inkMuted, size: 12.5),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            context.tr(slide.cta),
                            style: HomeType.label(accent, size: 12.5),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.accent,
    required this.live,
    required this.animate,
  });

  final String label;
  final Color accent;
  final bool live;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFE5484D),
        shape: BoxShape.circle,
      ),
    );
    if (animate) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 1, end: 0.25, duration: 800.ms);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[dot, const SizedBox(width: 6)],
          Text(
            label.toUpperCase(),
            style: HomeType.eyebrow(accent).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// Three compact trust marks, always visible under the banners.
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const marks = [
      (Icons.verified_outlined, HomeL10n.pillarCertifiedTitle),
      (Icons.storefront_outlined, HomeL10n.pillarSellersTitle),
      (Icons.lock_outline_rounded, HomeL10n.pillarPaymentsTitle),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: HomeStage.glass,
        borderRadius: BorderRadius.circular(HomeSpace.radiusSmall),
        border: Border.all(color: HomeStage.glassBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 22, color: HomeStage.glassBorder),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(marks[i].$1, size: 15, color: HomeStage.gold),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr(marks[i].$2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: HomeType.label(HomeStage.ink, size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
