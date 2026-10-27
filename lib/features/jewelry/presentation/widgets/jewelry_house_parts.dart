import 'package:flutter/material.dart';

import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/widgets/luxe/press_tilt.dart';
import '../../domain/models/marketplace_listing.dart';

/// Ordering and grouping helpers for jewelry houses (marketplace shops).
abstract final class JewelryHouses {
  /// First part of the shop's free-text location ("Jaipur, Rajasthan" →
  /// "Jaipur"), or null.
  static String? cityOf(MarketplaceShop shop) {
    final raw = shop.policies['location']?.split(',').first.trim() ?? '';
    return raw.isEmpty ? null : raw;
  }

  /// Featured order: houses with a banner, then the most pieces; ties keep
  /// the API's newest-first order.
  static List<MarketplaceShop> ranked(List<MarketplaceShop> shops) {
    final indexed = shops.indexed.toList()
      ..sort((a, b) {
        final banner =
            (b.$2.bannerUrl != null ? 1 : 0) - (a.$2.bannerUrl != null ? 1 : 0);
        if (banner != 0) return banner;
        final pieces = (b.$2.listingCount ?? 0) - (a.$2.listingCount ?? 0);
        return pieces != 0 ? pieces : a.$1 - b.$1;
      });
    return [for (final (_, s) in indexed) s];
  }
}

/// Obsidian with a warm gold key light near the top.
class JewelryStageBackdrop extends StatelessWidget {
  const JewelryStageBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}

/// One house in a list: logo, name, headline, city and pieces.
class JewelryHouseRow extends StatelessWidget {
  const JewelryHouseRow({required this.house, required this.onTap, super.key});

  final MarketplaceShop house;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = JewelryHouses.cityOf(house);
    final headline = house.headline?.trim();
    return PressTilt(
      semanticLabel: house.name,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: LuxeStage.glass,
          borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall + 4),
          border: Border.all(color: LuxeStage.glassBorder),
        ),
        child: Row(
          children: [
            JewelryHouseLogo(house: house, radius: 24),
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
            const JewelryHouseArrow(size: 30),
          ],
        ),
      ),
    );
  }
}

class JewelryHouseLogo extends StatelessWidget {
  const JewelryHouseLogo({
    required this.house,
    required this.radius,
    super.key,
  });

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

class JewelryHouseArrow extends StatelessWidget {
  const JewelryHouseArrow({required this.size, super.key});

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
class JewelryStageChipRow extends StatelessWidget {
  const JewelryStageChipRow({required this.children, super.key});

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
class JewelryStageChip extends StatelessWidget {
  const JewelryStageChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;

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
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 14, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centered icon, title, optional message and optional action on the stage.
class JewelryStageMessage extends StatelessWidget {
  const JewelryStageMessage({
    required this.icon,
    required this.title,
    super.key,
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
            JewelryStageChip(
              label: actionLabel!,
              selected: true,
              onTap: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}
