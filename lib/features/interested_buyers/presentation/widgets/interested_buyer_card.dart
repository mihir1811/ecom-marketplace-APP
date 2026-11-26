import 'package:flutter/material.dart';

import '../../../seller/presentation/atelier/atelier_components.dart';
import '../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../seller/presentation/atelier/atelier_theme.dart';
import '../../domain/models/interested_buyer.dart';

/// "3h", "2d" — how long the line has sat in the cart.
String interestedTimeInCart(DateTime? addedAt, {DateTime? now}) {
  if (addedAt == null) return '—';
  final d = (now ?? DateTime.now()).difference(addedAt);
  if (d.isNegative || d.inHours < 1) return 'under 1h';
  if (d.inHours < 24) return '${d.inHours}h';
  return '${d.inDays}d';
}

/// The line shown for a row whose `canOffer` is false.
String? interestedOfferBlockText(InterestedBuyer row) {
  final block = row.offerBlock;
  if (block == null) return null;
  if (block != InterestedOfferBlock.contactLimit) return block.text;
  final next = row.nextContactAt;
  return next == null
      ? '${block.text} Try again later, or sooner if they reply.'
      : '${block.text} Try again on ${atelierDate(next)}, or sooner if they '
            'reply.';
}

/// One cart line: buyer name, item, cart price, time in cart, last contact,
/// open offer, and Message / Give discount / Chat.
class InterestedBuyerCard extends StatelessWidget {
  const InterestedBuyerCard({
    required this.row,
    required this.onMessage,
    required this.onOffer,
    required this.onChat,
    required this.onOpenOffers,
    super.key,
  });

  final InterestedBuyer row;
  final VoidCallback onMessage;
  final VoidCallback onOffer;
  final VoidCallback onChat;
  final VoidCallback onOpenOffers;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final product = row.product;
    final last = row.lastContact;
    final open = row.openOffer;
    final blockText = row.canOffer ? null : interestedOfferBlockText(row);
    final meta = [
      product.typeLabel,
      if (product.stockNumber != null) 'Stock ${product.stockNumber}',
      if (row.quantity > 0) 'Qty ${_qty(row.quantity)}',
    ];
    const gap = SizedBox(height: 6);

    return AtelierCard(
      semanticLabel: '${row.buyerName} · ${product.displayTitle}',
      borderColor: row.contacted ? null : p.amber.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AtelierSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AtelierThumb(url: product.image, size: 48),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.display(p.ink, size: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AtelierPill(
                label: last == null ? 'New' : last.kind.label,
                tone: last == null
                    ? AtelierTone.amber
                    : row.buyerReplied
                    ? AtelierTone.emerald
                    : AtelierTone.neutral,
                dense: true,
              ),
            ],
          ),
          gap,
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 15, color: p.gold),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  row.buyerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.label(p.ink, size: 13.5),
                ),
              ),
              Text(
                atelierMoney(row.lineTotal, decimals: 2),
                style: AtelierType.figure(p.ink, size: 15),
              ),
            ],
          ),
          gap,
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              AtelierKeyValue(
                label: 'In cart',
                value: interestedTimeInCart(row.addedAt),
              ),
              if (last != null)
                AtelierKeyValue(
                  label: last.kind.label,
                  value: last.at == null ? '—' : atelierDate(last.at!),
                ),
              if (row.buyerReplied)
                const AtelierKeyValue(label: 'Buyer', value: 'Replied'),
              if (row.nextContactAt != null)
                AtelierKeyValue(
                  label: 'Next contact',
                  value: atelierDate(row.nextContactAt!),
                ),
              if (product.minimumOfferPrice != null)
                AtelierKeyValue(
                  label: 'Your minimum',
                  value: atelierMoney(product.minimumOfferPrice!, decimals: 2),
                ),
            ],
          ),
          if (open != null) ...[
            gap,
            AtelierNotice(
              text:
                  '${open.label} · ${atelierMoney(open.amount, decimals: 2)}',
              tone: AtelierTone.gold,
              icon: Icons.local_offer_outlined,
              actionLabel: 'Offers',
              onAction: onOpenOffers,
              dense: true,
            ),
          ] else if (blockText != null) ...[
            gap,
            AtelierNotice(
              text: blockText,
              tone: AtelierTone.neutral,
              icon: Icons.block_rounded,
              dense: true,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (row.chatPath != null) ...[
                Expanded(
                  child: AtelierButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline_rounded,
                    compact: true,
                    variant: AtelierButtonVariant.secondary,
                    onPressed: onChat,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: AtelierButton(
                  label: 'Message',
                  icon: Icons.mail_outline_rounded,
                  compact: true,
                  variant: AtelierButtonVariant.secondary,
                  onPressed: row.canMessage ? onMessage : null,
                ),
              ),
              if (open == null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: AtelierButton(
                    label: 'Give discount',
                    icon: Icons.sell_outlined,
                    compact: true,
                    variant: AtelierButtonVariant.gold,
                    onPressed: row.canOffer ? onOffer : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _qty(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
}
