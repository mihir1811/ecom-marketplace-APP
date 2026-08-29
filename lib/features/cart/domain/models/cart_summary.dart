/// Pricing summary from GET /cart/summary (amounts in USD unless noted).
class CartSummary {
  const CartSummary({
    this.items = const [],
    this.subtotal = 0,
    this.automaticDiscountTotal = 0,
    this.promoDiscountTotal = 0,
    this.totalDiscount = 0,
    this.discountedSubtotal = 0,
    this.totalUsd,
    this.totalInr,
    this.appliedPromoCodes = const [],
    this.automaticDiscounts = const [],
  });

  final List<CartSummaryLine> items;
  final double subtotal;
  final double automaticDiscountTotal;
  final double promoDiscountTotal;
  final double totalDiscount;
  final double discountedSubtotal;

  /// Optional grand total from API (USD). When set, order summary prefers it.
  final double? totalUsd;

  /// Optional grand total from API (INR). When set, order summary prefers it.
  final double? totalInr;

  final List<AppliedPromoCode> appliedPromoCodes;
  final List<AutomaticDiscount> automaticDiscounts;

  bool get isEmpty => items.isEmpty && subtotal <= 0;

  bool get hasApiTotal =>
      (totalUsd != null && totalUsd! > 0) ||
      (totalInr != null && totalInr! > 0);

  static const empty = CartSummary();
}

class CartSummaryLine {
  const CartSummaryLine({
    required this.cartId,
    required this.productId,
    required this.productType,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.sellerId,
    this.name,
    this.image,
  });

  final String cartId;
  final String productId;
  final String productType;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? sellerId;
  final String? name;
  final String? image;
}

class AppliedPromoCode {
  const AppliedPromoCode({
    required this.code,
    this.discountAmount = 0,
    this.sellerId,
  });

  final String code;
  final double discountAmount;
  final String? sellerId;
}

class AutomaticDiscount {
  const AutomaticDiscount({required this.label, this.discountAmount = 0});

  final String label;
  final double discountAmount;
}
