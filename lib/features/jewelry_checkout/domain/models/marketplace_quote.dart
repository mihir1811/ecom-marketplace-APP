import 'bag_line.dart';
import 'marketplace_charge.dart';

/// Today's price and availability for one bag line.
class QuoteLine {
  const QuoteLine({
    required this.skuId,
    required this.title,
    required this.shopName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.maxQuantity,
    required this.cancellationWindowHours,
    this.listingId,
    this.listingSlug,
    this.imageUrl,
    this.options = const {},
    this.customValues = const {},
    this.problem,
    this.taxes = const [],
    this.taxAmount = 0,
  });

  final String skuId;
  final String? listingId;
  final String? listingSlug;
  final String title;
  final String? imageUrl;
  final String shopName;
  final Map<String, String> options;
  final Map<String, String> customValues;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  /// Caps the quantity stepper: 20 for made-to-order, else stock up to 20.
  final int maxQuantity;
  final int cancellationWindowHours;

  /// Why the line can't be bought (null when it can), written for buyers.
  final String? problem;

  /// Taxes on this line, in rupees ([taxAmount] is their sum).
  final List<MarketplaceCharge> taxes;
  final double taxAmount;

  /// The bag line this quote line prices.
  String get key => BagLine.keyFor(skuId, customValues);
}

/// `POST /marketplace/cart/quote`. Lines with a problem are left out of
/// [subtotal]; checkout is refused until [ready]. [total] is subtotal +
/// [taxTotal] + shipping: what Razorpay charges.
class CartQuote {
  const CartQuote({
    required this.lines,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.ready,
    this.taxes = const [],
    this.taxTotal = 0,
  });

  final List<QuoteLine> lines;
  final double subtotal;

  /// One row per tax and rate across the bag; empty before taxes go live.
  final List<MarketplaceCharge> taxes;
  final double taxTotal;
  final double shipping;
  final double total;
  final bool ready;

  QuoteLine? lineFor(BagLine line) {
    for (final q in lines) {
      if (q.key == line.key) return q;
    }
    return null;
  }
}
