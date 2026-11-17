import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_listing.dart';
import '../../../../core/widgets/luxe/luxe_product_card.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/jewellery_categories_provider.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../application/jewelry_home_providers.dart';
import '../../domain/models/jewelry_filter_state.dart';
import '../../domain/models/marketplace_enums.dart';
import '../../domain/models/marketplace_listing.dart';
import 'jewelry_house_parts.dart';
import 'jewelry_luxe_cards.dart';

/// Section heading for the jewelry home: serif title, one-line subtitle and
/// an optional "View all" action with an arrow.
class JewelryHomeHeading extends StatelessWidget {
  const JewelryHomeHeading({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onDark = false,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Light text for headings placed on a dark band.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final ink = onDark ? LuxeStage.ink : p.ink;
    final muted = onDark ? LuxeStage.inkMuted : p.inkMuted;
    final accent = onDark ? LuxeStage.gold : p.accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.display(24, ink),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(muted, size: 12.5),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!, style: LuxeType.label(accent, size: 13)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Circle image with a hairline gold ring and a two-line label under it.
class _CircleTile extends StatelessWidget {
  const _CircleTile({
    required this.label,
    required this.size,
    required this.onTap,
    required this.child,
  });

  final String label;
  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return PressTilt(
      semanticLabel: label,
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: SizedBox(
        width: size + 12,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
              ),
              child: ClipOval(child: child),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.ink, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero carousel
// ---------------------------------------------------------------------------

/// One hero slide: a photo (Unsplash License, see `docs/image-credits.md`),
/// its collection and copy.
class _HeroSlideData {
  const _HeroSlideData({
    required this.asset,
    required this.labelKey,
    required this.lineKey,
    required this.category,
    this.focus = Alignment.center,
  });

  final String asset;
  final String labelKey;
  final String lineKey;

  /// Collection name matched against the live categories.
  final String category;

  /// Where the piece sits in the photo, so the crop keeps it in view.
  final Alignment focus;
}

/// Editorial hero: one collection per slide, the photo on the right fading
/// into the dark stage on the left where the copy and "Shop now" sit, so
/// text never covers the piece. Turns every 5 s (paused while touched or
/// when motion is reduced) with page dots below.
class JewelryHeroCarousel extends ConsumerStatefulWidget {
  const JewelryHeroCarousel({required this.onOpen, super.key});

  /// Live category slug of the slide, or null to open every collection.
  final ValueChanged<String?> onOpen;

  @override
  ConsumerState<JewelryHeroCarousel> createState() =>
      _JewelryHeroCarouselState();
}

class _JewelryHeroCarouselState extends ConsumerState<JewelryHeroCarousel> {
  static const _interval = Duration(seconds: 5);
  static const _dir = 'public/images/jewelryHero';

  static const _slides = [
    _HeroSlideData(
      asset: '$_dir/rings.webp',
      labelKey: JewelryFlowL10n.rings,
      lineKey: JewelryFlowL10n.homeHeroRings,
      category: 'Rings',
    ),
    _HeroSlideData(
      asset: '$_dir/necklaces.webp',
      labelKey: JewelryFlowL10n.necklaces,
      lineKey: JewelryFlowL10n.homeHeroNecklaces,
      category: 'Necklaces',
      focus: Alignment(0.4, 0),
    ),
    _HeroSlideData(
      asset: '$_dir/earrings.webp',
      labelKey: JewelryFlowL10n.earrings,
      lineKey: JewelryFlowL10n.homeHeroEarrings,
      category: 'Earrings',
      focus: Alignment(0.3, 0),
    ),
    _HeroSlideData(
      asset: '$_dir/bracelets.webp',
      labelKey: JewelryFlowL10n.bracelets,
      lineKey: JewelryFlowL10n.homeHeroBracelets,
      category: 'Bracelets',
      focus: Alignment(0, 0.3),
    ),
  ];

  /// Virtual pages so the hero always moves forward.
  static const _origin = 1000 * 4;

  final _controller = PageController(initialPage: _origin);
  Timer? _timer;
  int _page = _origin;
  bool _touching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer.periodic(_interval, (_) {
      if (_touching || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: LuxeMotion.settle,
      );
    });
  }

  /// Live slug whose name or slug matches the slide's collection.
  String? _slugFor(_HeroSlideData slide) {
    final live = ref.read(jewelleryCategoriesProvider).value ?? const [];
    final want = slide.category.toLowerCase();
    final singular = want.endsWith('s')
        ? want.substring(0, want.length - 1)
        : want;
    for (final c in live) {
      final name = c.name.trim().toLowerCase();
      final slug = c.slug.trim().toLowerCase();
      if (name == want ||
          slug == want ||
          name == singular ||
          slug == singular) {
        return c.slug;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final height = math.min(width * 0.6, 280.0);
    final active = _page % _slides.length;

    return Column(
      children: [
        Listener(
          onPointerDown: (_) => _touching = true,
          onPointerUp: (_) => _touching = false,
          onPointerCancel: (_) => _touching = false,
          child: SizedBox(
            height: height,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final slide = _slides[i % _slides.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _HeroSlide(
                    slide: slide,
                    onTap: () => widget.onOpen(_slugFor(slide)),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: LuxeMotion.medium,
                curve: LuxeMotion.settle,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == active ? p.accent : p.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.slide, required this.onTap});

  final _HeroSlideData slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = context.tr(slide.labelKey);
    final line = context.tr(slide.lineKey);
    final stage = LuxeStage.obsidian;
    return PressTilt(
      semanticLabel: '$title. $line',
      maxTilt: 0.02,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LuxeSpace.radius),
        child: ColoredBox(
          color: stage,
          child: LayoutBuilder(
            builder: (context, c) {
              final photo = c.maxWidth * 0.62;
              return Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: photo,
                    child: ExcludeSemantics(
                      child: Image.asset(
                        slide.asset,
                        fit: BoxFit.cover,
                        alignment: slide.focus,
                        cacheWidth: 900,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  // Blends the photo's left edge into the stage.
                  Positioned(
                    right: photo * 0.55,
                    top: 0,
                    bottom: 0,
                    width: photo * 0.45 + 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [stage, stage.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 18,
                    bottom: 18,
                    width: c.maxWidth * 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context
                              .tr(JewelryFlowL10n.homeHeroEyebrow)
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.eyebrow(
                            LuxeStage.gold,
                          ).copyWith(fontSize: 9.5, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: LuxeType.display(34, LuxeStage.ink),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            line,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.body(
                              LuxeStage.inkMuted,
                              size: 13,
                            ).copyWith(height: 1.35),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: ShapeDecoration(
                            color: LuxeStage.gold,
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  context.tr(JewelryFlowL10n.homeHeroCta),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LuxeType.label(
                                    LuxeStage.obsidian,
                                    size: 12.5,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: LuxeStage.obsidian,
                              ),
                            ],
                          ),
                        ),
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

// ---------------------------------------------------------------------------
// Budget grid
// ---------------------------------------------------------------------------

/// One price band in rupees; a null bound is open.
typedef JewelryBudgetBand = ({double? min, double? max});

/// "Shop by budget": four price bands in a 2×2 grid, each landing on the
/// results with that price range applied.
class JewelryBudgetGrid extends StatelessWidget {
  const JewelryBudgetGrid({required this.onOpen, super.key});

  final ValueChanged<JewelryBudgetBand> onOpen;

  static const _bands = <(JewelryBudgetBand, String)>[
    ((min: null, max: 10000), JewelryFlowL10n.homeBudgetGifts),
    ((min: 10000, max: 25000), JewelryFlowL10n.homeBudgetEveryday),
    ((min: 25000, max: 50000), JewelryFlowL10n.homeBudgetStatement),
    ((min: 50000, max: null), JewelryFlowL10n.homeBudgetHeirloom),
  ];

  /// 10000 → ₹10K; 100000 → ₹1L.
  static String _amount(double v) {
    if (v >= 100000) {
      final l = v / 100000;
      return '₹${l == l.roundToDouble() ? l.toInt() : l.toStringAsFixed(1)}L';
    }
    return '₹${(v / 1000).round()}K';
  }

  static String _label(BuildContext context, JewelryBudgetBand b) {
    if (b.min == null) {
      return context.tr(JewelryFlowL10n.homeBudgetUnder, {
        'amount': _amount(b.max!),
      });
    }
    if (b.max == null) {
      return context.tr(JewelryFlowL10n.homeBudgetAbove, {
        'amount': _amount(b.min!),
      });
    }
    return '${_amount(b.min!)} – ${_amount(b.max!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            Row(
              children: [
                for (var col = 0; col < 2; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _BudgetTile(
                      label: _label(context, _bands[row * 2 + col].$1),
                      caption: context.tr(_bands[row * 2 + col].$2),
                      tier: row * 2 + col,
                      onTap: () => onOpen(_bands[row * 2 + col].$1),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.label,
    required this.caption,
    required this.tier,
    required this.onTap,
  });

  final String label;
  final String caption;

  /// 0–3: deepens the tint and adds a diamond per tier.
  final int tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final tint = Color.lerp(p.surface, p.accentSoft, 0.35 + tier * 0.2)!;
    return PressTilt(
      semanticLabel: '$label, $caption',
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 2),
          border: Border.all(color: p.hairline),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.surface, tint],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i <= tier; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.diamond_rounded,
                      size: 12,
                      color: p.accent.withValues(alpha: 0.85),
                    ),
                  ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded, size: 16, color: p.inkMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.display(22, p.ink),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LuxeType.label(p.inkMuted, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trending rail
// ---------------------------------------------------------------------------

/// "Trending now" with New arrivals / Bestsellers tabs over one swipeable
/// row of product cards and a "View all" that opens the results in that
/// order. Hidden when neither tab has pieces.
class JewelryTrendingRail extends ConsumerStatefulWidget {
  const JewelryTrendingRail({required this.onViewAll, super.key});

  final ValueChanged<JewelrySortOption> onViewAll;

  @override
  ConsumerState<JewelryTrendingRail> createState() =>
      _JewelryTrendingRailState();
}

class _JewelryTrendingRailState extends ConsumerState<JewelryTrendingRail> {
  static const _tabs = [JewelrySortOption.newest, JewelrySortOption.popular];

  var _sort = JewelrySortOption.newest;

  String _label(BuildContext context, JewelrySortOption s) => context.tr(
    s == JewelrySortOption.newest
        ? JewelryFlowL10n.homeTabNew
        : JewelryFlowL10n.homeTabBestsellers,
  );

  @override
  Widget build(BuildContext context) {
    final rail = ref.watch(jewelryHomeRailProvider(_sort));
    // The first tab decides whether the section exists at all.
    final first = ref.watch(jewelryHomeRailProvider(_tabs.first));
    if (first.hasError || (first.value?.isEmpty ?? false)) {
      return const SizedBox.shrink();
    }

    final screen = MediaQuery.sizeOf(context).width;
    final width = math.min((screen - 12 - 16) / 2.25, 220.0);
    final height =
        width + luxeGridCardTextExtent(MediaQuery.textScalerOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JewelryHomeHeading(
          title: context.tr(JewelryFlowL10n.homeTrendingTitle),
          subtitle: context.tr(JewelryFlowL10n.homeTrendingSubtitle),
          actionLabel: context.tr(JewelryMarketL10n.viewAll),
          onAction: () => widget.onViewAll(_sort),
        ),
        LuxeQuickChips<JewelrySortOption>(
          chips: [
            for (final s in _tabs)
              LuxeQuickChip(value: s, label: _label(context, s)),
          ],
          isSelected: (s) => s == _sort,
          onTap: (s) => setState(() => _sort = s),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: AnimatedSwitcher(
            duration: LuxeMotion.fast,
            child: rail.when(
              skipLoadingOnRefresh: true,
              loading: () => _RailSkeleton(
                key: const ValueKey('loading'),
                width: width,
                height: height,
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => ListView.separated(
                key: ValueKey(_sort),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: LuxeListingMetrics.pad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: LuxeListingMetrics.gap),
                itemBuilder: (context, i) => SizedBox(
                  width: width,
                  child: JewelryLuxeGridCard(
                    jewelry: items[i],
                    onTap: () =>
                        openJewelryDetail(context, items[i], among: items),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton({required this.width, required this.height, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: LuxeListingMetrics.pad),
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: LuxeListingMetrics.gap),
          LuxeSkeleton(
            width: width,
            height: height,
            radius: LuxeSpace.cardRadius,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gemstones
// ---------------------------------------------------------------------------

/// "Shop by gemstone": round stone art; each opens every collection set
/// with that stone (`gemstone` is the API enum, e.g. `RUBY`).
class JewelryGemstoneRail extends StatelessWidget {
  const JewelryGemstoneRail({required this.onOpen, super.key});

  final ValueChanged<String> onOpen;

  static const _gems = [
    ('DIAMOND', 'public/images/round.webp'),
    ('RUBY', 'public/images/gemstones/Ruby.webp'),
    ('EMERALD', 'public/images/gemstones/Emerald.webp'),
    ('SAPPHIRE', 'public/images/gemstones/Sapphire.webp'),
    ('PEARL', 'public/images/gemstones/Pearl.webp'),
    ('AMETHYST', 'public/images/gemstones/Amethyst.webp'),
    ('TANZANITE', 'public/images/gemstones/Tanzanite.webp'),
    ('MORGANITE', 'public/images/gemstones/Morganite.webp'),
    ('AQUAMARINE', 'public/images/gemstones/Aquamarine.webp'),
    ('TOPAZ', 'public/images/gemstones/Topaz.webp'),
  ];

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return SizedBox(
      height: _size + 10 + MediaQuery.textScalerOf(context).scale(34),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _gems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final (gem, asset) = _gems[i];
          return _CircleTile(
            label: context.trCatalogValue(MarketplaceEnums.label(gem)),
            size: _size,
            onTap: () => onOpen(gem),
            child: ColoredBox(
              color: p.surfaceRaised,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  cacheWidth: 180,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.diamond_outlined, color: p.accent),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Jewelry houses
// ---------------------------------------------------------------------------

/// Compact house cards (banner, logo, name, city, pieces, rating) with a
/// link to every house. Hidden on error or when there are none.
class JewelryHouseRail extends ConsumerWidget {
  const JewelryHouseRail({
    required this.onOpen,
    required this.onShowAll,
    super.key,
  });

  final ValueChanged<MarketplaceShop> onOpen;
  final VoidCallback onShowAll;

  static const _count = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(jewelryShopsProvider);
    final value = shops.value;
    if (shops.hasError || (value != null && value.isEmpty)) {
      return const SizedBox.shrink();
    }
    final all = value == null
        ? null
        : JewelryHouses.ranked(value).take(_count).toList();
    final width = math.min(MediaQuery.sizeOf(context).width * 0.66, 280.0);
    final scale = MediaQuery.textScalerOf(context);
    final height =
        _HouseCard.bannerHeight(width) +
        _HouseCard.logoOverhang +
        scale.scale(17 * 1.15) +
        scale.scale(12 * 1.3) * 2 +
        26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JewelryHomeHeading(
          title: context.tr(JewelryFlowL10n.homeHousesTitle),
          subtitle: context.tr(JewelryFlowL10n.homeHousesSubtitle),
          actionLabel: context.tr(JewelryFlowL10n.showAllHouses),
          onAction: onShowAll,
        ),
        SizedBox(
          height: height,
          child: all == null
              ? _RailSkeleton(width: width, height: height)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final house = all[i];
                    return SizedBox(
                      width: width,
                      child: _HouseCard(
                        house: house,
                        onTap: () => onOpen(house),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HouseCard extends StatelessWidget {
  const _HouseCard({required this.house, required this.onTap});

  final MarketplaceShop house;
  final VoidCallback onTap;

  static const _logoRadius = 22.0;
  static const logoOverhang = _logoRadius + 4;

  static double bannerHeight(double width) => width / 2.4;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final city = JewelryHouses.cityOf(house);
    final banner = house.bannerUrl;
    final rating = house.ratingCount > 0 ? house.ratingAverage : null;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuxeStage.raised, LuxeStage.obsidian],
        ),
      ),
    );

    return PressTilt(
      semanticLabel: house.name,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 2),
          border: Border.all(color: p.hairline),
          boxShadow: p.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final bh = bannerHeight(c.maxWidth);
                return SizedBox(
                  height: bh + logoOverhang,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: bh,
                        child: banner == null
                            ? placeholder
                            : AppNetworkImage(
                                url: banner,
                                memCacheWidth: 700,
                                error: placeholder,
                              ),
                      ),
                      Positioned(
                        left: 12,
                        top: bh - _logoRadius,
                        child: JewelryHouseLogo(
                          house: house,
                          radius: _logoRadius,
                        ),
                      ),
                      if (rating != null)
                        Positioned(
                          right: 10,
                          top: bh + 6,
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: p.accent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: LuxeType.figure(p.ink, size: 12.5),
                              ),
                              Text(
                                ' (${house.ratingCount})',
                                style: LuxeType.label(p.inkFaint, size: 11.5),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      house.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.display(17, p.ink).copyWith(height: 1.15),
                    ),
                  ),
                  if (house.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 15, color: p.accent),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                [
                  context.tr(JewelryMarketL10n.shopPieces, {
                    'count': house.listingCount ?? 0,
                  }),
                  ?city,
                ].join('  ·  '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LuxeType.label(
                  p.inkMuted,
                  size: 12,
                ).copyWith(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trust strip
// ---------------------------------------------------------------------------

/// Reassurance close: four promises in a 2×2 panel.
class JewelryTrustStrip extends StatelessWidget {
  const JewelryTrustStrip({super.key});

  static const _items = [
    (
      Icons.verified_outlined,
      JewelryFlowL10n.homeTrustVerified,
      JewelryFlowL10n.homeTrustVerifiedBody,
    ),
    (
      Icons.lock_outline_rounded,
      JewelryFlowL10n.homeTrustSecure,
      JewelryFlowL10n.homeTrustSecureBody,
    ),
    (
      Icons.local_shipping_outlined,
      JewelryFlowL10n.homeTrustTracking,
      JewelryFlowL10n.homeTrustTrackingBody,
    ),
    (
      Icons.currency_exchange_rounded,
      JewelryFlowL10n.homeTrustRefunds,
      JewelryFlowL10n.homeTrustRefundsBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget item(int i) {
      final (icon, title, body) = _items[i];
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.accentSoft,
            ),
            child: Icon(icon, size: 18, color: p.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(title),
                  maxLines: 2,
                  style: LuxeType.label(p.ink, size: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(body),
                  maxLines: 2,
                  style: LuxeType.label(p.inkMuted, size: 11.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.tr(JewelryFlowL10n.homeTrustTitle),
              style: LuxeType.display(20, p.ink),
            ),
          ),
          const SizedBox(height: 16),
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: item(row * 2)),
                const SizedBox(width: 12),
                Expanded(child: item(row * 2 + 1)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
