import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/format_catalog_price.dart';
import '../../../../core/widgets/catalog_card_image_pager.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../buyer/application/wishlist_provider.dart';
import '../../../buyer/domain/models/wishlist_item.dart';
import '../../../buyer/presentation/widgets/wishlist_toggle_button.dart';
import '../../../comparison/application/comparison_provider.dart';
import '../../../comparison/domain/models/compare_item.dart';
import '../../../comparison/presentation/widgets/compare_toggle_helper.dart';
import '../../../diamond_projects/presentation/widgets/diamond_project_pick_checkbox.dart';
import '../../../product_detail/domain/adapters/diamond_product_detail.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../../recently_viewed/application/recently_viewed_providers.dart';
import '../../../recently_viewed/presentation/widgets/recently_viewed_badge.dart';
import '../../domain/models/diamond.dart';
import '../../domain/models/diamond_display.dart';
import 'diamond_cards.dart' show diamondGradesLine;
import 'diamond_svg_data.dart';

/// Text block height of [DiamondLuxeGridCard] for a given text scale, so
/// the grid can use fixed extents (fast layout, exact scroll restore).
double diamondLuxeGridTextExtent(TextScaler scaler) =>
    9 +
    14 +
    scaler.scale(19 * 1.1) +
    6 +
    scaler.scale(12.5 * 1.25) +
    2 +
    scaler.scale(11.5 * 1.25) +
    12 +
    scaler.scale(15 * 1.2) +
    // Safety for font metrics that exceed the nominal line height.
    6;

/// "$8,191/ct · 7.21 × 5.10 × 3.18" — rounded, grouped, typographic ×.
String? _metaLine(Diamond d) {
  final parts = <String>[];
  final ppc = d.pricePerCarat;
  if (ppc != null && ppc > 0) {
    parts.add(
      '${AppCurrency.format(formatGroupedWhole(ppc.roundToDouble()))}/ct',
    );
  }
  final measure = DiamondDisplay.optional(d.measurement);
  if (measure != null) {
    parts.add(measure.replaceAll(RegExp(r'\s*[xX]\s*'), ' × '));
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

String _title(Diamond d) {
  final shape = DiamondDisplay.shape(d.shape);
  final carat = '${d.carat.toStringAsFixed(2)} ct';
  return shape == DiamondDisplay.missing ? carat : '$carat $shape';
}

Widget _thumb(BuildContext context, Diamond d) {
  final p = LuxePalette.of(context);
  final fallback = ColoredBox(
    color: p.surfaceRaised,
    child: Center(child: renderShapeSvg(d.shape, size: 52, color: p.accent)),
  );
  return CatalogCardImagePager(
    imageUrls: catalogListingImageUrls(
      imageUrl: d.imageUrl,
      imageUrls: d.imageUrls,
    ),
    fallback: fallback,
    memCacheWidth: 420,
  );
}

/// Two-column result card: media with status, save, compare; serif title,
/// grades, key metrics and price.
class DiamondLuxeGridCard extends ConsumerWidget {
  const DiamondLuxeGridCard({
    required this.diamond,
    required this.onTap,
    super.key,
    this.showProjectPick = false,
  });

  final Diamond diamond;
  final VoidCallback onTap;
  final bool showProjectPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final d = diamond;
    final viewed = ref.watch(isRecentlyViewedProvider(d.id));
    return _CardFrame(
      onTap: onTap,
      viewed: viewed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpace.radius - 5),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _thumb(context, d),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: AvailabilityStatusBadge(status: d.available),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showProjectPick) ...[
                            DiamondProjectPickBadge(diamondId: d.id),
                            const SizedBox(width: 4),
                          ],
                          DiamondSaveButton(diamond: d),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: DiamondCompareButton(diamond: d),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(19, p.ink).copyWith(height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  diamondGradesLine(d) ?? DiamondDisplay.missing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  _metaLine(d) ?? ' ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkFaint, size: 11.5),
                ),
                const SizedBox(height: 12),
                _PriceRow(diamond: d),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width result row for list view.
class DiamondLuxeListCard extends ConsumerWidget {
  const DiamondLuxeListCard({
    required this.diamond,
    required this.onTap,
    super.key,
    this.showProjectPick = false,
  });

  final Diamond diamond;
  final VoidCallback onTap;
  final bool showProjectPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final d = diamond;
    final viewed = ref.watch(isRecentlyViewedProvider(d.id));
    final lab = DiamondDisplay.labBadge(d.lab ?? d.certificate);
    final stock = d.stockNumber?.trim();
    final measure = DiamondDisplay.optional(d.measurement);
    final detail = [
      ?lab,
      if (measure != null) measure.replaceAll(RegExp(r'\s*[xX]\s*'), ' × '),
      if (stock != null && stock.isNotEmpty) '#$stock',
    ].join(' · ');

    return _CardFrame(
      onTap: onTap,
      viewed: viewed,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpace.radius - 6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _thumb(context, d),
                    Positioned(
                      top: 7,
                      left: 7,
                      child: AvailabilityStatusBadge(status: d.available),
                    ),
                    if (showProjectPick)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: DiamondProjectPickBadge(diamondId: d.id),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title(d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.display(20, p.ink),
                          ),
                        ),
                        DiamondSaveButton(diamond: d, onLight: true),
                      ],
                    ),
                    Text(
                      diamondGradesLine(d) ?? DiamondDisplay.missing,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(p.inkMuted, size: 12.5),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuxeType.label(p.inkFaint, size: 11.5),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _PriceRow(diamond: d, showList: true)),
                        DiamondCompareButton(diamond: d, onLight: true),
                      ],
                    ),
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

class _CardFrame extends StatefulWidget {
  const _CardFrame({
    required this.child,
    required this.onTap,
    required this.viewed,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool viewed;

  @override
  State<_CardFrame> createState() => _CardFrameState();
}

class _CardFrameState extends State<_CardFrame> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        AppHaptics.selection();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: LuxeMotion.fast,
        curve: LuxeMotion.press,
        child: AnimatedContainer(
          duration: LuxeMotion.medium,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LuxeSpace.radius),
            border: Border.all(
              color: widget.viewed
                  ? p.accent.withValues(alpha: 0.45)
                  : p.hairline,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.diamond, this.showList = false});

  final Diamond diamond;

  /// Struck list price; only where the card is wide enough to show it whole.
  final bool showList;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final d = diamond;
    final belowList = catalogMarkdownPercent(d.discount);
    final rapList = (d.rap != null && d.rap! > 0 && d.carat > 0)
        ? d.rap! * d.carat
        : null;
    final inferred = belowList == null
        ? null
        : catalogListFromNet(d.price, belowList);
    final list = rapList != null && rapList > d.price
        ? rapList
        : (inferred != null && inferred > d.price ? inferred : null);

    return Row(
      children: [
        Text(
          AppCurrency.format(formatGroupedWhole(d.price)),
          maxLines: 1,
          style: LuxeType.figure(
            p.ink,
            size: 15,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        if (showList && list != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppCurrency.format(formatGroupedWhole(list)),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: LuxeType.label(p.inkFaint, size: 11).copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: p.inkFaint,
              ),
            ),
          ),
        ],
        if (belowList != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: ShapeDecoration(
              color: p.caution.withValues(alpha: 0.12),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '−${formatDiscountPercent(belowList)}%',
              style: LuxeType.figure(p.caution, size: 11),
            ),
          ),
        ],
      ],
    );
  }
}

/// Heart toggle for a diamond, styled for imagery (glass) or light rows.
class DiamondSaveButton extends ConsumerWidget {
  const DiamondSaveButton({
    required this.diamond,
    super.key,
    this.onLight = false,
  });

  final Diamond diamond;

  /// True when placed on a card surface rather than over the photo.
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final saved = ref.watch(isInWishlistProvider(diamond.id));
    return _MiniCircle(
      tooltip: context.tr(HomeL10n.wishlist),
      glass: !onLight,
      onTap: () => toggleWishlistItem(
        context,
        ref,
        WishlistItem.fromDiamond(diamond),
        onAdded: () => rememberProductDetail(diamondProductDetail(diamond)),
      ),
      child: AnimatedSwitcher(
        duration: LuxeMotion.fast,
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(saved),
          size: 17,
          color: saved
              ? const Color(0xFFE5484D)
              : (onLight || !p.isDark ? p.inkMuted : Colors.white),
        ),
      ),
    );
  }
}

/// Compare toggle for a diamond (adds to the comparison tray).
class DiamondCompareButton extends ConsumerWidget {
  const DiamondCompareButton({
    required this.diamond,
    super.key,
    this.onLight = false,
  });

  final Diamond diamond;
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = LuxePalette.of(context);
    final inCompare = ref.watch(isInComparisonProvider(diamond.id));
    return _MiniCircle(
      tooltip: context.tr(CatalogL10n.compare),
      glass: !onLight,
      active: inCompare,
      onTap: () =>
          handleCompareToggle(context, ref, CompareItem.fromDiamond(diamond)),
      child: Icon(
        inCompare ? Icons.check_rounded : Icons.compare_arrows_rounded,
        size: 17,
        color: inCompare
            ? p.canvas
            : (onLight || !p.isDark ? p.inkMuted : Colors.white),
      ),
    );
  }
}

class _MiniCircle extends StatelessWidget {
  const _MiniCircle({
    required this.child,
    required this.onTap,
    required this.tooltip,
    required this.glass,
    this.active = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool glass;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final bg = active
        ? p.ink
        : (glass
              ? (p.isDark ? const Color(0x52000000) : const Color(0xE6FFFFFF))
              : p.surfaceRaised);
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: active,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          // 40px hit area around a 32px visual.
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: LuxeMotion.medium,
              width: 32,
              height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
