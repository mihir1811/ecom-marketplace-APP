import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../home_content.dart';
import '../theme/home_tokens.dart';
import 'home_section.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../../../core/widgets/luxe/scroll_reveal.dart';

/// Bento grid of the six catalogue worlds.
class HomeCollections extends StatelessWidget {
  const HomeCollections({super.key});

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final gutter = homeGutter(context);
    const items = HomeContent.collections;

    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, HomeSpace.section, gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSectionHeading(
            index: '01',
            eyebrow: context.tr(HomeL10n.collectionsEyebrow),
            title: context.tr(HomeL10n.collectionsTitle),
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final col = (w - _gap) / 2;
              final tall = col * 1.42;
              final small = (tall - _gap) / 2;
              return Column(
                children: [
                  SizedBox(
                    height: tall,
                    child: Row(
                      children: [
                        Expanded(
                          child: _Tile(item: items[0], number: 1, hero: true),
                        ),
                        const SizedBox(width: _gap),
                        Expanded(
                          child: Column(
                            children: [
                              SizedBox(
                                height: small,
                                child: _Tile(
                                  item: items[1],
                                  number: 2,
                                  delay: 120,
                                ),
                              ),
                              const SizedBox(height: _gap),
                              SizedBox(
                                height: small,
                                child: _Tile(
                                  item: items[2],
                                  number: 3,
                                  delay: 220,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _gap),
                  SizedBox(
                    height: (w * 0.52).clamp(170.0, 320.0),
                    child: _Tile(item: items[3], number: 4, wide: true),
                  ),
                  const SizedBox(height: _gap),
                  SizedBox(
                    height: col * 1.08,
                    child: Row(
                      children: [
                        Expanded(child: _Tile(item: items[4], number: 5)),
                        const SizedBox(width: _gap),
                        Expanded(
                          child: _Tile(item: items[5], number: 6, delay: 120),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.number,
    this.hero = false,
    this.wide = false,
    this.delay = 0,
  });

  final HomeCollection item;
  final int number;
  final bool hero;
  final bool wide;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final palette = HomePalette.of(context);
    final title = context.tr(item.titleKey);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (MediaQuery.sizeOf(context).width * dpr).round();

    return ScrollReveal.builder(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 1300),
      builder: (context, reveal) {
        return AnimatedBuilder(
          animation: reveal,
          builder: (context, child) {
            final t = reveal.value;
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 36),
                child: child,
              ),
            );
          },
          child: PressTilt(
            semanticLabel: title,
            onTap: () => context.openRoute(item.route),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HomeSpace.radius),
              child: ColoredBox(
                color: palette.surfaceRaised,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ken Burns settle: the photo eases from 1.18x to rest.
                    AnimatedBuilder(
                      animation: reveal,
                      builder: (context, child) => Transform.scale(
                        scale: 1 + (1 - reveal.value) * 0.18,
                        child: child,
                      ),
                      child: AppNetworkImage(
                        url: item.imageUrl,
                        memCacheWidth: cacheWidth,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.45, 1],
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                            Color(0xC7000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 16,
                      child: Text(
                        number.toString().padLeft(2, '0'),
                        style: HomeType.eyebrow(const Color(0xCCFFFFFF)),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0x26FFFFFF),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HomeType.display(
                          hero || wide ? 30 : 22,
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
