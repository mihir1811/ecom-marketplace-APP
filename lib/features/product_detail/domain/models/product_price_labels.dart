import '../../../../core/utils/format_catalog_price.dart';
import 'product_detail.dart';

/// Display strings for a product price: sale, struck list price, discount
/// and per-unit line. One implementation for every price presentation.
class ProductPriceLabels {
  const ProductPriceLabels({
    required this.sale,
    required this.list,
    required this.discountPercent,
    required this.unit,
    this.saveAmount,
    this.currencySymbol = '',
  });

  /// Resolves labels for [price].
  ///
  /// [amountOverride] replaces the sale amount (e.g. highest auction bid) and
  /// suppresses the catalog discount. [localizedUnit] is the translated unit
  /// suffix ("per carat").
  factory ProductPriceLabels.resolve(
    ProductPrice price, {
    double? amountOverride,
    bool showCatalogDiscount = true,
    String? localizedUnit,
    bool grouped = false,
  }) {
    final unit =
        price.isOnRequest ||
            price.unitAmountLabel == null ||
            localizedUnit == null
        ? null
        : '${price.currencySymbol}${price.unitAmountLabel} $localizedUnit';
    final discount = price.discountPercent;
    final override = amountOverride;
    final suppressDiscount = !showCatalogDiscount || override != null;
    final hasDiscount = !suppressDiscount && price.hasDiscount;
    final formatAmount = grouped
        ? formatGroupedWhole
        : override != null
        ? formatCatalogPrice
        : (price.displayAmountIsListPrice
              ? formatGroupedWhole
              : formatCatalogPrice);

    // Catalog lot price from API — never scale with melee pcs/carat draft.
    final amount = override ?? price.displayAmount;
    final c = price.currencySymbol;

    String sale;
    String? list;
    double? save;
    if (price.isOnRequest && override == null) {
      sale = price.display;
      list = null;
    } else if (!hasDiscount) {
      sale = '$c${formatAmount(amount)}';
      list = null;
    } else if (price.listAmount != null && price.listAmount! > amount) {
      list = '$c${formatAmount(price.listAmount!)}';
      sale = '$c${formatAmount(amount)}';
      save = price.listAmount! - amount;
    } else if (price.displayAmountIsListPrice) {
      // List in amountLabel → discounted = list × (1 − %/100).
      final listAmount = amount;
      final saleAmount = listAmount * (1 - discount! / 100);
      list = '$c${formatAmount(listAmount)}';
      sale = '$c${formatAmount(saleAmount)}';
      save = listAmount - saleAmount;
    } else {
      // Net already in amountLabel → list inferred from %.
      sale = '$c${formatAmount(amount)}';
      final listAmount = catalogListFromNet(amount, discount!) ?? amount;
      list = '$c${formatAmount(listAmount)}';
      save = listAmount - amount;
    }

    return ProductPriceLabels(
      sale: sale,
      list: list,
      discountPercent: hasDiscount ? discount : null,
      unit: override == null ? unit : null,
      saveAmount: save == null || save <= 0 ? null : save,
      currencySymbol: c,
    );
  }

  final String sale;
  final String? list;
  final double? discountPercent;
  final String? unit;

  /// List minus sale, when a discount applies.
  final double? saveAmount;

  final String currencySymbol;

  bool get hasDiscount => list != null && discountPercent != null;
}
