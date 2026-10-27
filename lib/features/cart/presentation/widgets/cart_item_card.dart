import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/luxe_tokens.dart';
import '../../../../core/utils/app_currency.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/luxe/luxe_feedback.dart';
import '../../../../core/widgets/luxe/luxe_quantity_stepper.dart';
import '../../../diamonds/presentation/widgets/diamond_svg_data.dart';
import '../../../product_detail/application/catalog_product_detail_loader.dart';
import '../../../product_detail/product_detail_navigation.dart';
import '../../application/cart_provider.dart';
import '../../domain/models/cart_item.dart';

/// Cart line: image, title, seller, price, quantity and remove.
/// Tapping the card opens the product detail.
class CartItemCard extends ConsumerStatefulWidget {
  const CartItemCard({required this.item, super.key});

  final CartItem item;

  @override
  ConsumerState<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends ConsumerState<CartItemCard> {
  bool _opening = false;
  bool _removing = false;

  Future<void> _openProduct() async {
    if (_opening) return;
    final item = widget.item;
    if (item.productId.isEmpty) return;

    if (openRememberedProductDetail(context, item.productId)) return;

    setState(() => _opening = true);
    try {
      final detail = await CatalogProductDetailLoader.load(
        ref.read,
        productType: item.productType,
        productId: item.productId,
      );
      if (!mounted) return;
      if (detail != null) {
        openProductDetail(context, detail);
        return;
      }
      showLuxeToast(
        context,
        context.tr(AccountCommerceL10n.productOpenFailed),
        tone: LuxeTone.error,
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _removing = true);
    final result = await ref
        .read(cartProvider.notifier)
        .removeItem(widget.item.cartId);
    if (!mounted) return;
    setState(() => _removing = false);
    if (result case ResultFailure(:final failure)) {
      showLuxeToast(context, failure.message, tone: LuxeTone.error);
    } else {
      AppHaptics.medium();
    }
  }

  Future<void> _setQuantity(int next) async {
    final result = await ref
        .read(cartProvider.notifier)
        .updateQuantity(cartId: widget.item.cartId, quantity: next);
    if (!mounted) return;
    if (result case ResultFailure(:final failure)) {
      showLuxeToast(context, failure.message, tone: LuxeTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    final item = widget.item;
    final mutating = ref.watch(cartIsMutatingProvider);
    final available = item.isAvailable;
    final busy = mutating || _opening || _removing;
    final unavailableLabel = item.availabilityLabel ?? 'Unavailable';

    return AnimatedOpacity(
      duration: LuxeMotion.fast,
      opacity: _removing ? 0.45 : 1,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuxeSpace.radius),
          side: BorderSide(
            color: available ? p.hairline : p.caution.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _opening ? null : _openProduct,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(
                  item: item,
                  opening: _opening,
                  dimmed: !available,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LuxeType.display(
                                  19,
                                  available ? p.ink : p.inkMuted,
                                ).copyWith(
                                  height: 1.1,
                                  decoration: available
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: _removing
                                ? Padding(
                                    padding: const EdgeInsets.all(9),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.6,
                                      color: p.inkMuted,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: context.tr(
                                      AccountCommerceL10n.remove,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: busy ? null : _remove,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: p.inkMuted,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (item.seller != null && item.seller!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 13,
                              color: p.inkFaint,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                item.seller!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LuxeType.label(p.inkMuted, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (!available) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: ShapeDecoration(
                            color: p.caution.withValues(alpha: 0.12),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            unavailableLabel,
                            style: LuxeType.label(p.caution, size: 11.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  text: AppCurrency.format(
                                    item.displayPriceUsd.toStringAsFixed(2),
                                  ),
                                  children: [
                                    // Accepted offer: offered amount over
                                    // the struck list price.
                                    if (item.isOfferLine &&
                                        item.listedPriceUsd != null &&
                                        item.listedPriceUsd! >
                                            item.displayPriceUsd)
                                      TextSpan(
                                        text: '  ${AppCurrency.format(item.listedPriceUsd!.toStringAsFixed(2))}',
                                        style: LuxeType.label(
                                          p.inkFaint,
                                          size: 12,
                                        ).copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          decorationColor: p.inkFaint,
                                        ),
                                      ),
                                    if (item.isOfferLine)
                                      TextSpan(
                                        text: '  ${context.tr(DiamondFlowL10n.offerPriceTag)}',
                                        style: LuxeType.label(
                                          p.positive,
                                          size: 11.5,
                                        ),
                                      ),
                                  ],
                                ),
                                style: LuxeType.figure(
                                  available ? p.ink : p.inkFaint,
                                  size: 17,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: available
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ),
                          if (item.quantityEditable)
                            IgnorePointer(
                              ignoring: !available || busy,
                              child: AnimatedOpacity(
                                duration: LuxeMotion.fast,
                                opacity: !available || busy ? 0.5 : 1,
                                child: Transform.scale(
                                  scale: 0.86,
                                  alignment: Alignment.centerRight,
                                  child: LuxeQuantityStepper(
                                    value: item.quantity,
                                    onChanged: _setQuantity,
                                  ),
                                ),
                              ),
                            )
                          else if (item.quantity > 1)
                            Text(
                              context.tr(AccountCommerceL10n.quantity, {
                                'count': item.quantity,
                              }),
                              style: LuxeType.label(p.inkMuted, size: 12),
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

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.item,
    required this.opening,
    required this.dimmed,
  });

  final CartItem item;
  final bool opening;
  final bool dimmed;

  static const double size = 92;

  @override
  Widget build(BuildContext context) {
    final p = LuxePalette.of(context);
    Widget fallback() => Center(
      child: item.shape != null
          ? renderShapeSvg(item.shape!, size: 40, color: p.accent)
          : Icon(Icons.diamond_outlined, color: p.accent),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(LuxeSpace.radiusSmall),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            AppNetworkImage(
              url: item.imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              memCacheWidth: 184,
              error: fallback(),
            )
          else
            fallback(),
          if (dimmed) ColoredBox(color: p.canvas.withValues(alpha: 0.5)),
          if (opening)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
