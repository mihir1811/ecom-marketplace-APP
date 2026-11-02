import 'package:flutter/material.dart';

import '../../haptics/app_haptics.dart';
import '../../theme/luxe_tokens.dart';
import '../../utils/app_currency.dart';
import '../../utils/format_catalog_price.dart';

/// Text block height of [LuxeProductGridCard] for a given text scale, so
/// grids can use fixed extents (fast layout, exact scroll restore).
double luxeGridCardTextExtent(TextScaler scaler) =>
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

/// Corner overlays placed over a card's media.
class LuxeMediaOverlays {
  const LuxeMediaOverlays({
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;
}

/// Two-column catalog card: square media with corner controls, serif title,
/// grades line, quiet meta line and price row.
class LuxeProductGridCard extends StatelessWidget {
  const LuxeProductGridCard({
    required this.media,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    super.key,
    this.meta,
    this.metaLeading,
    this.overlays = const LuxeMediaOverlays(),
    this.highlighted = false,
    this.outlineColor,
  });

  final Widget media;
  final String title;
  final String subtitle;
  final String? meta;

  /// Small badge before [meta] (e.g. the Sponsored pill).
  final Widget? metaLeading;
  final Widget price;
  final VoidCallback onTap;
  final LuxeMediaOverlays overlays;

  /// Accent border, e.g. for recently viewed items.
  final bool highlighted;

  /// Overrides the border colour (e.g. sponsored results).
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final metaText = Text(
      meta ?? ' ',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: LuxeType.label(p.inkFaint, size: 11.5),
    );
    return LuxeCardFrame(
      onTap: onTap,
      highlighted: highlighted,
      outlineColor: outlineColor,
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
                    media,
                    if (overlays.topLeft != null)
                      Positioned(top: 8, left: 8, child: overlays.topLeft!),
                    if (overlays.topRight != null)
                      Positioned(top: 6, right: 6, child: overlays.topRight!),
                    if (overlays.bottomLeft != null)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: overlays.bottomLeft!,
                      ),
                    if (overlays.bottomRight != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: overlays.bottomRight!,
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.display(19, p.ink).copyWith(height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuxeType.label(p.inkMuted, size: 12.5),
                ),
                const SizedBox(height: 2),
                if (metaLeading == null)
                  metaText
                else
                  Row(
                    children: [
                      metaLeading!,
                      const SizedBox(width: 6),
                      Expanded(child: metaText),
                    ],
                  ),
                const SizedBox(height: 12),
                price,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width catalog row: thumbnail with corner badges, title with a
/// trailing action, grades, detail line and a price row with a trailing
/// action.
class LuxeProductListCard extends StatelessWidget {
  const LuxeProductListCard({
    required this.media,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    super.key,
    this.detail,
    this.titleAction,
    this.priceAction,
    this.thumbTopLeft,
    this.thumbBottomLeft,
    this.highlighted = false,
    this.detailLeading,
    this.outlineColor,
  });

  /// Height of the thumbnail; the row stride is this plus padding and gap.
  static const thumbSize = 112.0;

  final Widget media;
  final String title;
  final String subtitle;
  final String? detail;
  final Widget price;
  final VoidCallback onTap;
  final Widget? titleAction;
  final Widget? priceAction;
  final Widget? thumbTopLeft;
  final Widget? thumbBottomLeft;
  final bool highlighted;

  /// Small badge before [detail] (e.g. the Sponsored pill).
  final Widget? detailLeading;

  /// Overrides the border colour (e.g. sponsored results).
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return LuxeCardFrame(
      onTap: onTap,
      highlighted: highlighted,
      outlineColor: outlineColor,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: thumbSize,
              height: thumbSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LuxeSpace.radius - 6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    media,
                    if (thumbTopLeft != null)
                      Positioned(top: 7, left: 7, child: thumbTopLeft!),
                    if (thumbBottomLeft != null)
                      Positioned(bottom: 6, left: 6, child: thumbBottomLeft!),
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
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LuxeType.display(20, p.ink),
                          ),
                        ),
                        ?titleAction,
                      ],
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuxeType.label(p.inkMuted, size: 12.5),
                    ),
                    if ((detail != null && detail!.isNotEmpty) ||
                        detailLeading != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (detailLeading != null) ...[
                            detailLeading!,
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              detail ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LuxeType.label(p.inkFaint, size: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: price),
                        ?priceAction,
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

/// Card surface with a soft press-scale and an optional accent border.
class LuxeCardFrame extends StatefulWidget {
  const LuxeCardFrame({
    required this.child,
    required this.onTap,
    super.key,
    this.highlighted = false,
    this.outlineColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool highlighted;

  /// Overrides the border colour.
  final Color? outlineColor;

  @override
  State<LuxeCardFrame> createState() => _LuxeCardFrameState();
}

class _LuxeCardFrameState extends State<LuxeCardFrame> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) => _setDown(false),
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
              color:
                  widget.outlineColor ??
                  (widget.highlighted
                      ? p.accent.withValues(alpha: 0.45)
                      : p.hairline),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 32px round control (40px hit area) used over card media or rows.
class LuxeMiniCircle extends StatelessWidget {
  const LuxeMiniCircle({
    required this.child,
    required this.onTap,
    required this.tooltip,
    super.key,
    this.glass = true,
    this.active = false,
    this.activeColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  /// Frosted fill for use over imagery; otherwise a quiet raised fill.
  final bool glass;
  final bool active;

  /// Fill when [active]; defaults to ink.
  final Color? activeColor;

  /// Icon colour matching the resting fill, for children to use.
  static Color restingIconColor(BuildContext context, {bool glass = true}) {
    final p = LuxePalette.of(context);
    return (!glass || !p.isDark) ? p.inkMuted : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final bg = active
        ? (activeColor ?? p.ink)
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
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: LuxeMotion.medium,
              curve: LuxeMotion.settle,
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

/// Price with an optional struck list price and markdown pill.
class LuxePriceRow extends StatelessWidget {
  const LuxePriceRow({
    required this.price,
    super.key,
    this.listPrice,
    this.discountPercent,
    this.showList = false,
    this.currencySymbol,
    this.prefix,
  });

  final double price;

  /// Defaults to [AppCurrency.symbol]; rupee listings pass `₹`.
  final String? currencySymbol;

  /// Quiet word before the price, e.g. "from" for a price range.
  final String? prefix;

  /// Pre-discount price; shown struck through when [showList] and higher.
  final double? listPrice;
  final double? discountPercent;

  /// Only where the card is wide enough to show the list price whole.
  final bool showList;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final list = listPrice != null && listPrice! > price ? listPrice : null;
    final symbol = currencySymbol ?? AppCurrency.symbol;
    return Row(
      children: [
        if (prefix != null) ...[
          Text(prefix!, style: LuxeType.label(p.inkMuted, size: 11.5)),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            '$symbol${formatGroupedWhole(price)}',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: LuxeType.figure(
              p.ink,
              size: 15,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (showList && list != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$symbol${formatGroupedWhole(list)}',
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
        if (discountPercent != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: ShapeDecoration(
              color: p.caution.withValues(alpha: 0.12),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '−${formatDiscountPercent(discountPercent!)}%',
              style: LuxeType.figure(p.caution, size: 11),
            ),
          ),
        ],
      ],
    );
  }
}
