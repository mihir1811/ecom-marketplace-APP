import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../application/jewelry_catalogue_providers.dart';
import '../../domain/models/marketplace_listing.dart';

/// Always-dark stage for the jewelry houses.
///
/// Featured houses lead in a swipeable row, then every house with sort
/// (featured, newest, most pieces, name) and the filters the live shops
/// actually support (city, price breakup). Stardust twinkles on the warm
/// key light behind it all.
class JewelryShowcaseStage extends ConsumerStatefulWidget {
  const JewelryShowcaseStage({
    required this.topInset,
    required this.onOpenHouse,
    super.key,
  });

  /// Space reserved for the floating header.
  final double topInset;
  final ValueChanged<MarketplaceShop> onOpenHouse;

  @override
  ConsumerState<JewelryShowcaseStage> createState() =>
      _JewelryShowcaseStageState();
}

enum _HouseSort { featured, newest, pieces, name }

class _JewelryShowcaseStageState extends ConsumerState<JewelryShowcaseStage>
    with SingleTickerProviderStateMixin {
  static const _featuredCount = 5;

  /// Continuous clock for the stardust (seconds / 12).
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  _HouseSort _sort = _HouseSort.featured;
  String? _city;
  bool _priceBreakup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// First part of the shop's free-text location ("Jaipur, Rajasthan" →
  /// "Jaipur"), or null.
  static String? _cityOf(MarketplaceShop shop) {
    final raw = shop.policies['location']?.split(',').first.trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  /// Featured order: houses with a banner, then the most pieces; ties keep
  /// the API's newest-first order.
  static List<MarketplaceShop> _ranked(List<MarketplaceShop> shops) {
    final indexed = shops.indexed.toList()
      ..sort((a, b) {
        final banner = (b.$2.bannerUrl != null ? 1 : 0) -
            (a.$2.bannerUrl != null ? 1 : 0);
        if (banner != 0) return banner;
        final pieces = (b.$2.listingCount ?? 0) - (a.$2.listingCount ?? 0);
        return pieces != 0 ? pieces : a.$1 - b.$1;
      });
    return [for (final (_, s) in indexed) s];
  }

  List<MarketplaceShop> _visible(List<MarketplaceShop> shops) {
    final filtered = [
      for (final s in shops)
        if ((_city == null || _cityOf(s) == _city) &&
            (!_priceBreakup || s.showPriceBreakdown))
          s,
    ];
    return switch (_sort) {
      _HouseSort.featured => _ranked(filtered),
      _HouseSort.newest => filtered,
      _HouseSort.pieces => [...filtered]
        ..sort((a, b) => (b.listingCount ?? 0) - (a.listingCount ?? 0)),
      _HouseSort.name => [...filtered]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    };
  }

  void _clearFilters() => setState(() {
    _city = null;
    _priceBreakup = false;
  });

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(jewelryShopsProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LuxeStage.obsidian,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.85),
                  radius: 1.1,
                  // Opaque blends: the stage never shows the page behind.
                  colors: [
                    Color.alphaBlend(
                      LuxeStage.gold.withValues(alpha: 0.16),
                      LuxeStage.obsidian,
                    ),
                    Color.alphaBlend(
                      LuxeStage.gold.withValues(alpha: 0.05),
                      LuxeStage.obsidian,
                    ),
                    LuxeStage.obsidian,
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _StardustPainter(_clock)),
          ),
          Padding(
            // Room at the bottom for the search that floats over the edge.
            padding: EdgeInsets.only(top: widget.topInset, bottom: 64),
            child: shops.when(
              skipLoadingOnRefresh: false,
              loading: () => const _StageSkeleton(),
              error: (error, _) => _StageMessage(
                icon: Icons.cloud_off_rounded,
                title: context.tr(CatalogFlowL10n.errorTitle),
                message: error is Failure
                    ? error.message
                    : context.tr(JewelryFlowL10n.housesError),
                actionLabel: context.tr(CatalogL10n.retry),
                onAction: () => ref.invalidate(jewelryShopsProvider),
              ),
              data: (all) => all.isEmpty
                  ? _StageMessage(
                      icon: Icons.storefront_outlined,
                      title: context.tr(JewelryFlowL10n.housesEmpty),
                      message: context.tr(JewelryFlowL10n.housesEmptyBody),
                    )
                  : _houses(context, all),
            ),
          ),
        ],
      ),
    );
  }

  Widget _houses(BuildContext context, List<MarketplaceShop> all) {
    final featured = _ranked(all).take(_featuredCount).toList();
    final cities = {for (final s in all) ?_cityOf(s)}.toList()..sort();
    final breakupApplies =
        all.any((s) => s.showPriceBreakdown) &&
        all.any((s) => !s.showPriceBreakdown);
    final visible = _visible(all);
    final filtering = _city != null || _priceBreakup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Intro(count: all.length),
        const SizedBox(height: 22),
        _SectionLabel(context.tr(JewelryFlowL10n.featuredHouses)),
        const SizedBox(height: 12),
        _FeaturedRow(houses: featured, onOpen: widget.onOpenHouse),
        const SizedBox(height: 34),
        _SectionLabel(
          context.tr(JewelryFlowL10n.allHouses),
          trailing: context.tr(JewelryFlowL10n.housesCount, {
            'count': visible.length,
          }),
        ),
        const SizedBox(height: 12),
        _ChipRow(
          children: [
            for (final sort in _HouseSort.values)
              _StageChip(
                label: context.tr(switch (sort) {
                  _HouseSort.featured => JewelryFlowL10n.sortFeatured,
                  _HouseSort.newest => JewelryFlowL10n.sortNewest,
                  _HouseSort.pieces => JewelryFlowL10n.sortMostPieces,
                  _HouseSort.name => JewelryFlowL10n.sortName,
                }),
                selected: _sort == sort,
                onTap: () => setState(() => _sort = sort),
              ),
          ],
        ),
        if (cities.length > 1 || breakupApplies) ...[
          const SizedBox(height: 8),
          _ChipRow(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: LuxeStage.inkMuted),
              if (filtering)
                _StageChip(
                  label: context.tr(CatalogL10n.clearAll),
                  icon: Icons.close_rounded,
                  selected: false,
                  onTap: _clearFilters,
                ),
              if (breakupApplies)
                _StageChip(
                  label: context.tr(JewelryFlowL10n.priceBreakup),
                  selected: _priceBreakup,
                  onTap: () => setState(() => _priceBreakup = !_priceBreakup),
                ),
              if (cities.length > 1)
                for (final city in cities)
                  _StageChip(
                    label: city,
                    icon: Icons.place_outlined,
                    selected: _city == city,
                    onTap: () =>
                        setState(() => _city = _city == city ? null : city),
                  ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        AnimatedSize(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          alignment: Alignment.topCenter,
          child: visible.isEmpty
              ? _StageMessage(
                  icon: Icons.filter_alt_off_outlined,
                  title: context.tr(JewelryFlowL10n.housesNoMatch),
                  actionLabel: context.tr(CatalogL10n.clearAll),
                  onAction: _clearFilters,
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final (i, house) in visible.indexed) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _HouseRow(
                          key: ValueKey(house.id),
                          house: house,
                          onTap: () => widget.onOpenHouse(house),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Eyebrow, headline and a one-line intro.
class _Intro extends StatelessWidget {
  const _Intro({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    Widget enter(Widget child, int i) => animate
        ? child
              .animate(delay: (120 + i * 110).ms)
              .fadeIn(duration: 600.ms)
              .moveY(
                begin: 16,
                end: 0,
                duration: 900.ms,
                curve: LuxeMotion.settle,
              )
        : child;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          enter(
            Row(
              children: [
                Container(width: 22, height: 1, color: LuxeStage.gold),
                const SizedBox(width: 10),
                Text(
                  context.tr(JewelryFlowL10n.houseEyebrow).toUpperCase(),
                  style: LuxeType.eyebrow(LuxeStage.gold),
                ),
              ],
            ),
            0,
          ),
          const SizedBox(height: 12),
          enter(
            Text(
              context.tr(JewelryFlowL10n.housesHeadline),
              style: LuxeType.display(38, LuxeStage.ink),
            ),
            1,
          ),
          const SizedBox(height: 10),
          enter(
            Text(
              context.tr(JewelryFlowL10n.housesIntro, {'count': count}),
              style: LuxeType.body(LuxeStage.inkMuted, size: 14),
            ),
            2,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: LuxeType.eyebrow(LuxeStage.gold),
            ),
          ),
          if (trailing != null)
            Text(trailing!, style: LuxeType.label(LuxeStage.inkMuted, size: 12)),
        ],
      ),
    );
  }
}

/// Swipeable featured houses: banner, logo, name and piece count.
class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.houses, required this.onOpen});

  final List<MarketplaceShop> houses;
  final ValueChanged<MarketplaceShop> onOpen;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(width * 0.78, 340.0);
    return SizedBox(
      height: cardWidth * 0.82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: houses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: houses.length == 1 ? width - 32 : cardWidth,
          child: _FeaturedCard(
            house: houses[i],
            onTap: () => onOpen(houses[i]),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.house, required this.onTap});

  final MarketplaceShop house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final banner = house.bannerUrl;
    final city = _JewelryShowcaseStageState._cityOf(house);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuxeStage.raised, LuxeStage.obsidian],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.diamond_outlined,
          size: 40,
          color: LuxeStage.gold.withValues(alpha: 0.5),
        ),
      ),
    );

    return PressTilt(
      semanticLabel: house.name,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          border: Border.all(color: LuxeStage.glassBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            banner == null
                ? placeholder
                : AppNetworkImage(url: banner, error: placeholder),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x26000000), Color(0xD9000000)],
                  stops: [0.25, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: ShapeDecoration(
                  color: LuxeStage.obsidian.withValues(alpha: 0.6),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: LuxeStage.gold.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 12, color: LuxeStage.gold),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(JewelryFlowL10n.sortFeatured).toUpperCase(),
                      style: LuxeType.eyebrow(
                        LuxeStage.gold,
                      ).copyWith(fontSize: 9, letterSpacing: 1.8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _HouseLogo(house: house, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          house.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.display(24, LuxeStage.ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            context.tr(JewelryMarketL10n.shopPieces, {
                              'count': house.listingCount ?? 0,
                            }),
                            ?city,
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuxeType.label(LuxeStage.inkMuted, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const _Arrow(size: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One house in the full list: logo, name, headline, city and pieces.
class _HouseRow extends StatelessWidget {
  const _HouseRow({required this.house, required this.onTap, super.key});

  final MarketplaceShop house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = _JewelryShowcaseStageState._cityOf(house);
    final headline = house.headline?.trim();
    return PressTilt(
      semanticLabel: house.name,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: LuxeStage.glass,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: LuxeStage.glassBorder),
        ),
        child: Row(
          children: [
            _HouseLogo(house: house, radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    house.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuxeType.label(LuxeStage.ink, size: 15),
                  ),
                  if (headline != null && headline.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.body(LuxeStage.inkMuted, size: 12.5),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        context.tr(JewelryMarketL10n.shopPieces, {
                          'count': house.listingCount ?? 0,
                        }),
                        style: LuxeType.label(LuxeStage.gold, size: 11.5),
                      ),
                      if (city != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.place_outlined,
                          size: 12,
                          color: LuxeStage.inkMuted,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.label(
                              LuxeStage.inkMuted,
                              size: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _Arrow(size: 30),
          ],
        ),
      ),
    );
  }
}

class _HouseLogo extends StatelessWidget {
  const _HouseLogo({required this.house, required this.radius});

  final MarketplaceShop house;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final logo = house.logoUrl;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: LuxeStage.gold.withValues(alpha: 0.6)),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: LuxeStage.raised,
        foregroundImage: logo == null ? null : NetworkImage(logo),
        onForegroundImageError: logo == null ? null : (_, _) {},
        child: Icon(
          Icons.storefront_outlined,
          size: radius * 0.9,
          color: LuxeStage.gold,
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LuxeStage.glass,
        border: Border.all(color: LuxeStage.glassBorder),
      ),
      child: Icon(
        Icons.arrow_outward_rounded,
        size: size * 0.45,
        color: LuxeStage.ink,
      ),
    );
  }
}

/// Horizontally scrolling row of stage chips.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}

/// Stadium chip on the dark stage: champagne-white when selected, glass
/// otherwise.
class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? LuxeStage.obsidian : LuxeStage.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: LuxeMotion.medium,
          curve: LuxeMotion.settle,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? LuxeStage.ink : LuxeStage.glass,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? LuxeStage.ink : LuxeStage.glassBorder,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: LuxeType.label(fg, size: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered icon, title, optional message and optional action on the stage.
class _StageMessage extends StatelessWidget {
  const _StageMessage({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: LuxeStage.gold),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: LuxeType.display(24, LuxeStage.ink),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: LuxeType.body(LuxeStage.inkMuted, size: 13.5),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            _StageChip(label: actionLabel!, selected: true, onTap: onAction!),
          ],
        ],
      ),
    );
  }
}

/// Glass placeholders shaped like the intro, featured row and list.
class _StageSkeleton extends StatelessWidget {
  const _StageSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(width * 0.78, 340.0);
    Widget block(double? w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: LuxeStage.glass,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    final skeleton = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(120, 10),
              const SizedBox(height: 16),
              block(220, 34),
              const SizedBox(height: 12),
              block(260, 12),
            ],
          ),
        ),
        const SizedBox(height: 34),
        SizedBox(
          height: cardWidth * 0.82,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              block(cardWidth, cardWidth * 0.82, LuxeSpace.radius),
              const SizedBox(width: 12),
              block(cardWidth, cardWidth * 0.82, LuxeSpace.radius),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                block(double.infinity, 76, LuxeSpace.radiusSmall + 4),
              ],
            ],
          ),
        ),
      ],
    );

    if (MediaQuery.disableAnimationsOf(context)) return skeleton;
    return skeleton
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.55, end: 1, duration: 900.ms);
  }
}

/// Twinkling four-point glints scattered across the stage.
class _StardustPainter extends CustomPainter {
  _StardustPainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;

  static final _stars = () {
    final rng = math.Random(7);
    return [
      for (var i = 0; i < 34; i++)
        (
          x: rng.nextDouble(),
          y: rng.nextDouble() * 0.78,
          r: 0.8 + rng.nextDouble() * 2.6,
          phase: rng.nextDouble(),
          speed: 1 + rng.nextInt(3),
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    final dot = Paint();
    for (final s in _stars) {
      final wave = math.sin((clock.value * s.speed + s.phase) * 2 * math.pi);
      final a = math.pow(math.max(0.0, wave), 3).toDouble();
      if (a < 0.02) continue;
      final c = Offset(s.x * size.width, s.y * size.height);
      final color = Color.lerp(LuxeStage.gold, Colors.white, s.phase)!;
      final len = s.r * (2.5 + a * 2.5);
      line.color = color.withValues(alpha: a * 0.8);
      canvas
        ..drawLine(c.translate(-len, 0), c.translate(len, 0), line)
        ..drawLine(c.translate(0, -len), c.translate(0, len), line);
      dot.color = color.withValues(alpha: a);
      canvas.drawCircle(c, s.r * 0.55, dot);
    }
  }

  @override
  bool shouldRepaint(_StardustPainter old) => old.clock != clock;
}
