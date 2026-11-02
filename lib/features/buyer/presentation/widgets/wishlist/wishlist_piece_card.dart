import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../../product_detail/product_detail_navigation.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';
import '../../../domain/models/wishlist_item.dart';
import '../../maison/maison_kit.dart';

IconData wishlistCategoryIcon(WishlistCategory c) => switch (c) {
  WishlistCategory.diamond => Icons.diamond_outlined,
  WishlistCategory.gemstone => Icons.auto_awesome_outlined,
  WishlistCategory.jewelry => Icons.workspace_premium_outlined,
  WishlistCategory.watch => Icons.watch_outlined,
  WishlistCategory.bullion => Icons.savings_outlined,
};

String wishlistCategoryLabel(WishlistCategory c) => switch (c) {
  WishlistCategory.diamond => 'Diamonds',
  WishlistCategory.gemstone => 'Gemstones',
  WishlistCategory.jewelry => 'Jewelry',
  WishlistCategory.watch => 'Watches',
  WishlistCategory.bullion => 'Bullion',
};

/// A saved piece, as a gallery tile ([compact] false) or a list row.
/// Tapping opens the product; the heart removes it.
class WishlistPieceCard extends ConsumerStatefulWidget {
  const WishlistPieceCard({
    required this.item,
    required this.onRemove,
    this.compact = false,
    super.key,
  });

  final WishlistItem item;
  final VoidCallback onRemove;
  final bool compact;

  @override
  ConsumerState<WishlistPieceCard> createState() => _WishlistPieceCardState();
}

class _WishlistPieceCardState extends ConsumerState<WishlistPieceCard> {
  bool _opening = false;

  WishlistItem get item => widget.item;

  Future<void> _open() async {
    if (_opening) return;
    if (openRememberedProductDetail(context, item.id)) return;
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.atelier;
    final failedText = context.tr(AccountCommerceL10n.productOpenFailed);
    setState(() => _opening = true);
    try {
      final detail = await CatalogProductDetailLoader.load(
        ref.read,
        productType: item.productType,
        productId: item.id,
      );
      if (!mounted) return;
      if (detail == null) {
        showMaisonToast(messenger, palette, failedText, tone: AtelierTone.ruby);
        return;
      }
      openProductDetail(context, detail);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _row(context) : _tile(context);
  }

  Widget _tile(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: _opening ? null : _open,
      semanticLabel: '${item.title}, ${item.priceLabel}',
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Image(item: item, iconSize: 34),
                  // Soft vignette so the glass chips read on any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x33000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _HeartButton(onTap: widget.onRemove),
                  ),
                  _OpeningVeil(visible: _opening),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.title(p.ink, size: 14),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtelierType.caption(p.muted, size: 11.5),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.display(p.ink, size: 20),
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: p.gold,
                        ),
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

  Widget _row(BuildContext context) {
    final p = context.atelier;
    return Pressable(
      onTap: _opening ? null : _open,
      semanticLabel: '${item.title}, ${item.priceLabel}',
      borderRadius: BorderRadius.circular(AtelierRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.lg),
          border: Border.all(color: p.hairline),
          boxShadow: p.softShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AtelierRadius.md),
              child: SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Image(item: item, iconSize: 26),
                    _OpeningVeil(visible: _opening),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FavoriteProductType.label(item.productType).toUpperCase(),
                    style: AtelierType.overline(p.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.title(p.ink, size: 14.5),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    item.priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.display(p.ink, size: 19),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            _HeartButton(onTap: widget.onRemove, onSurface: true),
          ],
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({required this.item, required this.iconSize});

  final WishlistItem item;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [p.goldSoft, p.sunken], radius: 0.9),
      ),
      child: Center(
        child: Icon(
          wishlistCategoryIcon(item.category),
          size: iconSize,
          color: p.gold,
        ),
      ),
    );
    final asset = item.imageAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    final url = item.imageUrl?.trim();
    if (url == null || url.isEmpty) return fallback;
    return AppNetworkImage(
      url: url,
      fit: BoxFit.cover,
      memCacheWidth: 600,
      error: fallback,
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.onTap, this.onSurface = false});

  final VoidCallback onTap;
  final bool onSurface;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Tooltip(
      message: context.tr(AccountCommerceL10n.removeWishlist),
      child: Pressable(
        onTap: onTap,
        scale: 0.82,
        semanticLabel: context.tr(AccountCommerceL10n.removeWishlist),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onSurface
                ? p.ruby.withValues(alpha: p.isDark ? 0.14 : 0.07)
                : Colors.white.withValues(alpha: 0.92),
            boxShadow: onSurface
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Icon(Icons.favorite_rounded, size: 18, color: p.ruby),
        ),
      ),
    );
  }
}

class _OpeningVeil extends StatelessWidget {
  const _OpeningVeil({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: AtelierMotion.base,
        opacity: visible ? 1 : 0,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
