import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../application/jewelry_house_providers.dart';
import '../jewellery_category_images.dart';

/// A house's collections as a carousel of tall cards, each fronted by the
/// house's latest upload in it. Only names and imagery: tapping one opens
/// the results page for that collection.
class JewelryHouseCollections extends ConsumerStatefulWidget {
  const JewelryHouseCollections({
    required this.shop,
    required this.onOpen,
    super.key,
  });

  final String shop;
  final ValueChanged<String> onOpen;

  @override
  ConsumerState<JewelryHouseCollections> createState() =>
      _JewelryHouseCollectionsState();
}

class _JewelryHouseCollectionsState
    extends ConsumerState<JewelryHouseCollections> {
  static const _fraction = 0.78;

  final _pages = PageController(viewportFraction: _fraction);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cardHeight = (width * _fraction * 1.28).clamp(300.0, 460.0);
    final collections = ref.watch(jewelryHouseCollectionsProvider(widget.shop));

    return AnimatedSize(
      duration: LuxeMotion.medium,
      curve: LuxeMotion.settle,
      alignment: Alignment.topCenter,
      child: collections.when(
        loading: () => _Frame(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.11),
            child: LuxeSkeleton(
              width: double.infinity,
              height: cardHeight,
              radius: LuxeSpace.radius,
            ),
          ),
        ),
        // Collections are a way in; the pieces below still work without.
        error: (_, _) => const SizedBox(width: double.infinity),
        data: (items) {
          if (items.isEmpty) return const SizedBox(width: double.infinity);
          return _Frame(
            child: Column(
              children: [
                SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    controller: _pages,
                    padEnds: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    onPageChanged: (_) => AppHaptics.selection(),
                    itemBuilder: (context, i) => AnimatedBuilder(
                      animation: _pages,
                      builder: (context, child) {
                        final page =
                            _pages.hasClients && _pages.position.haveDimensions
                            ? _pages.page ?? 0
                            : 0.0;
                        final d = (page - i).abs().clamp(0.0, 1.0);
                        return Opacity(
                          opacity: 1 - d * 0.35,
                          child: Transform.scale(
                            scale: 1 - d * 0.08,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _CollectionCard(
                          index: i,
                          collection: items[i],
                          onTap: () => widget.onOpen(items[i].category.slug),
                        ),
                      ),
                    ),
                  ),
                ),
                if (items.length > 1) ...[
                  const SizedBox(height: 18),
                  _Progress(pages: _pages, count: items.length, palette: p),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Eyebrow and display title over the carousel.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(JewelryFlowL10n.houseCollections).toUpperCase(),
                  style: LuxeType.eyebrow(p.accent),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(JewelryFlowL10n.houseCollectionsTitle),
                  style: LuxeType.displayItalic(30, p.ink),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.index,
    required this.collection,
    required this.onTap,
  });

  final int index;
  final JewelryHouseCollection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = collection.category;
    final cover = collection.cover;
    final fallback = Image.asset(
      JewelleryCategoryImages.assetFor(category.slug),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(color: LuxeStage.raised),
    );

    return PressTilt(
      semanticLabel: category.name,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: LuxeStage.obsidian),
              cover == null
                  ? fallback
                  : AppNetworkImage(url: cover, error: fallback),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x59000000),
                      Color(0x00000000),
                      Color(0x26000000),
                      Color(0xD9000000),
                    ],
                    stops: [0, 0.28, 0.55, 1],
                  ),
                ),
              ),
              // A fine gold inner frame, like a vitrine.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LuxeSpace.radius - 8),
                      border: Border.all(
                        color: LuxeStage.gold.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 26,
                left: 26,
                child: Text(
                  'N° ${(index + 1).toString().padLeft(2, '0')}',
                  style: LuxeType.eyebrow(LuxeStage.goldLight),
                ),
              ),
              Positioned(
                left: 26,
                right: 26,
                bottom: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(36, LuxeStage.ink),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 0.8,
                          color: LuxeStage.gold,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.tr(JewelryFlowL10n.explore).toUpperCase(),
                          style: LuxeType.eyebrow(LuxeStage.gold),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: LuxeStage.gold,
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
    );
  }
}

/// "01 ——— 04" with a gold hairline that fills as the carousel turns.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.pages,
    required this.count,
    required this.palette,
  });

  final PageController pages;
  final int count;
  final LuxePalette palette;

  String _n(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: AnimatedBuilder(
        animation: pages,
        builder: (context, _) {
          final page = pages.hasClients && pages.position.haveDimensions
              ? pages.page ?? 0
              : 0.0;
          final current = page.round().clamp(0, count - 1);
          final t = count <= 1 ? 1.0 : (page / (count - 1)).clamp(0.0, 1.0);
          return Row(
            children: [
              Text(_n(current + 1), style: LuxeType.figure(p.ink, size: 13)),
              const SizedBox(width: 14),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 0.8, color: p.hairline),
                      Container(
                        height: 1.4,
                        width: c.maxWidth * (0.12 + 0.88 * t),
                        color: p.accent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(_n(count), style: LuxeType.figure(p.inkFaint, size: 13)),
            ],
          );
        },
      ),
    );
  }
}
