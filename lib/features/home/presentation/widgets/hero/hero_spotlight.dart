import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/router/app_navigation.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../home_network_images.dart';
import '../../theme/home_tokens.dart';

class _Slide {
  const _Slide({
    required this.color,
    required this.image,
    required this.tag,
    required this.title,
    required this.body,
    required this.route,
  });

  /// Solid banner ground; copy and CTA sit on it in white.
  final Color color;
  final String image;
  final String tag;
  final String title;
  final String body;
  final String route;
}

const _slides = [
  _Slide(
    color: Color(0xFFD81B60),
    image: HomeNetworkImages.saleDiwali,
    tag: HomeL10n.saleDiwaliTag,
    title: HomeL10n.saleDiwaliTitle,
    body: HomeL10n.saleDiwaliBody,
    route: AppRouteNames.diamonds,
  ),
  _Slide(
    color: Color(0xFFE65100),
    image: HomeNetworkImages.saleDhanteras,
    tag: HomeL10n.saleDhanterasTag,
    title: HomeL10n.saleDhanterasTitle,
    body: HomeL10n.saleDhanterasBody,
    route: AppRouteNames.bullions,
  ),
  _Slide(
    color: Color(0xFF6A1B9A),
    image: HomeNetworkImages.saleWedding,
    tag: HomeL10n.saleWeddingTag,
    title: HomeL10n.saleWeddingTitle,
    body: HomeL10n.saleWeddingBody,
    route: AppRouteNames.jewelry,
  ),
  _Slide(
    color: Color(0xFF00897B),
    image: HomeNetworkImages.saleGem,
    tag: HomeL10n.saleGemTag,
    title: HomeL10n.saleGemTitle,
    body: HomeL10n.saleGemBody,
    route: AppRouteNames.gemstones,
  ),
  _Slide(
    color: Color(0xFF1E4FD8),
    image: HomeNetworkImages.saleGold,
    tag: HomeL10n.saleGoldTag,
    title: HomeL10n.saleGoldTitle,
    body: HomeL10n.saleGoldBody,
    route: AppRouteNames.jewelry,
  ),
];

/// Hero foot: a self-advancing carousel of festive sale banners.
class HeroSpotlight extends StatefulWidget {
  const HeroSpotlight({required this.animate, required this.gutter, super.key});

  final bool animate;
  final double gutter;

  @override
  State<HeroSpotlight> createState() => _HeroSpotlightState();
}

class _HeroSpotlightState extends State<HeroSpotlight> {
  static const _interval = Duration(milliseconds: 4800);
  static const _cardHeight = 164.0;
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
                  child: _SaleCard(slide: _slides[i % _slides.length]),
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
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final color = slide.color;

    return Semantics(
      button: true,
      label:
          '${context.tr(slide.tag)}. ${context.tr(slide.title)}. '
          '${context.tr(slide.body)}',
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HomeSpace.radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: Colors.white.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          onTap: () {
            AppHaptics.selection();
            context.openRoute(slide.route);
          },
          child: LayoutBuilder(
            builder: (context, box) {
              final photoWidth = box.maxWidth * 0.42;
              return Stack(
                children: [
                  // Soft disc behind the copy lifts it off the flat ground.
                  Positioned(
                    left: -36,
                    bottom: -56,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: photoWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(box.maxHeight / 2),
                      ),
                      child: AppNetworkImage(
                        url: slide.image,
                        memCacheWidth: 600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 16, photoWidth + 10, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Tag(label: context.tr(slide.tag)),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr(slide.title),
                            maxLines: 1,
                            style: HomeType.display(28, Colors.white).copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(slide.body),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: HomeType.body(
                            Colors.white.withValues(alpha: 0.9),
                            size: 12.5,
                          ),
                        ),
                        const Spacer(),
                        _ShopButton(color: color),
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

/// Sunny offer pill that reads on every banner colour.
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: HomeType.eyebrow(
          const Color(0xFF3E2723),
        ).copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ShopButton extends StatelessWidget {
  const _ShopButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr(HomeL10n.saleShop),
            style: HomeType.label(
              color,
              size: 12,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, size: 14, color: color),
        ],
      ),
    );
  }
}
