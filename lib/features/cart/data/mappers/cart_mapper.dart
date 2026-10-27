import '../../../../core/catalog/catalog_purchase_policy.dart';
import '../../../../core/utils/melee_purchase_math.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_product_type.dart';
import '../../domain/models/cart_summary.dart';
import '../../domain/models/delivery_address.dart';

/// Parses cart / delivery JSON into domain models.
abstract final class CartMapper {
  static CartItem cartItemFromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic>
        ? product
        : const <String, dynamic>{};
    final productType = _str(json['productType']) ?? '';
    final specsRaw = json['specifications'];
    final specifications = specsRaw is Map<String, dynamic> ? specsRaw : null;

    final meleeLine = MeleePurchaseMath.linePriceFromCartPayload(
      specifications: specifications,
      product: productMap,
    );
    final lotPrice =
        _num(productMap['totalPrice']) ?? _num(productMap['price']) ?? 0;
    // A line added with an accepted offer is priced at the offered amount;
    // `listedPrice` keeps the original.
    final offerId = _str(specifications?['offerId']);
    final offerPrice = offerId == null ? null : _num(json['price']);
    final linePrice = offerPrice ?? meleeLine;
    final price = linePrice ?? lotPrice;

    final name =
        _str(productMap['name']) ??
        _str(productMap['brand']) ??
        _str(productMap['stockNumber']) ??
        'Product';
    final image =
        _str(productMap['image1']) ??
        _str(productMap['image']) ??
        _firstImage(productMap);

    final availability = _productAvailability(json, productMap);
    final stoneWeight = _str(specifications?['stoneWeight']);
    final displayTitle = (stoneWeight != null &&
            stoneWeight.isNotEmpty &&
            !name.toLowerCase().contains(stoneWeight.toLowerCase()))
        ? '$name · $stoneWeight'
        : name;

    return CartItem(
      cartId: _str(json['id']) ?? '',
      productId: _str(json['productId']) ?? _str(productMap['id']) ?? '',
      productType: productType,
      title: displayTitle,
      category: CartProductType.label(productType),
      // Cart line count — melee partial amount lives in specifications, not qty.
      quantity: _int(json['quantity']) ?? 1,
      priceUsd: price,
      unitPriceUsd: linePrice,
      lineTotalUsd: linePrice,
      offerId: offerPrice == null ? null : offerId,
      listedPriceUsd: offerPrice == null
          ? null
          : _num(json['listedPrice']) ?? lotPrice,
      imageUrl: image,
      shape: _str(productMap['shape']),
      seller: _str(json['seller']) ?? _str(productMap['sellerName']),
      sellerId: _str(json['sellerId']),
      // Backend `/cart/update` rejects qty changes for jewellery and most types.
      quantityEditable: false,
      isAvailable: availability.isAvailable,
      availabilityLabel: availability.label,
    );
  }

  static CartSummary summaryFromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final items = <CartSummaryLine>[];
    if (itemsJson is List) {
      for (final item in itemsJson) {
        if (item is! Map<String, dynamic>) continue;
        items.add(
          CartSummaryLine(
            cartId: _str(item['cartId']) ?? '',
            productId: _str(item['productId']) ?? '',
            productType: _str(item['productType']) ?? '',
            quantity: _int(item['quantity']) ?? 1,
            unitPrice: _num(item['unitPrice']) ?? 0,
            lineTotal: _num(item['lineTotal']) ?? 0,
            sellerId: _str(item['sellerId']),
            name: _str(item['name']),
            image: _str(item['image']),
          ),
        );
      }
    }

    final promosJson = json['appliedPromoCodes'];
    final promos = <AppliedPromoCode>[];
    if (promosJson is List) {
      for (final p in promosJson) {
        if (p is String) {
          promos.add(AppliedPromoCode(code: p));
        } else if (p is Map<String, dynamic>) {
          final code = _str(p['code']) ?? _str(p['promoCode']);
          if (code == null || code.isEmpty) continue;
          promos.add(
            AppliedPromoCode(
              code: code,
              discountAmount:
                  _num(p['discountAmount']) ?? _num(p['discount']) ?? 0,
              sellerId: _str(p['sellerId']),
            ),
          );
        }
      }
    }

    final autosJson = json['automaticDiscounts'];
    final autos = <AutomaticDiscount>[];
    if (autosJson is List) {
      for (final a in autosJson) {
        if (a is! Map<String, dynamic>) continue;
        autos.add(
          AutomaticDiscount(
            label: _str(a['label']) ?? _str(a['name']) ?? 'Discount',
            discountAmount:
                _num(a['discountAmount']) ?? _num(a['discount']) ?? 0,
          ),
        );
      }
    }

    return CartSummary(
      items: items,
      subtotal: _num(json['subtotal']) ?? 0,
      automaticDiscountTotal: _num(json['automaticDiscountTotal']) ?? 0,
      promoDiscountTotal: _num(json['promoDiscountTotal']) ?? 0,
      totalDiscount: _num(json['totalDiscount']) ?? 0,
      discountedSubtotal: _num(json['discountedSubtotal']) ?? 0,
      totalUsd:
          _num(json['totalUsd']) ??
          _num(json['grandTotalUsd']) ??
          _num(json['total']),
      totalInr:
          _num(json['totalInr']) ??
          _num(json['grandTotalInr']) ??
          _num(json['estimatedTotalInr']),
      appliedPromoCodes: promos,
      automaticDiscounts: autos,
    );
  }

  static DeliveryAddress addressFromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: _str(json['id']),
      fullName: _str(json['fullName']) ?? '',
      phone: _str(json['phone']) ?? '',
      line1: _str(json['addressLine1']) ?? '',
      line2: _str(json['addressLine2']),
      city: _str(json['city']) ?? '',
      state: _str(json['state']) ?? '',
      postalCode: _str(json['zipCode']) ?? '',
      country: _str(json['country']) ?? '',
      label: _str(json['label']),
      isDefault: json['isDefault'] == true,
    );
  }

  static Map<String, dynamic> addressToCreateBody(DeliveryAddress a) {
    return {
      'fullName': a.fullName,
      'phone': a.phone,
      'addressLine1': a.line1,
      if (a.line2 != null && a.line2!.isNotEmpty) 'addressLine2': a.line2,
      'city': a.city,
      'state': a.state,
      'country': a.country,
      'zipCode': a.postalCode,
      if (a.label != null && a.label!.isNotEmpty) 'label': a.label,
      'isDefault': a.isDefault,
    };
  }

  static CartDeliveryState deliveryStateFromJson(Map<String, dynamic> json) {
    final selected = json['selectedAddress'];
    final addressesJson = json['addresses'];
    final addresses = <DeliveryAddress>[];
    if (addressesJson is List) {
      for (final a in addressesJson) {
        if (a is Map<String, dynamic>) {
          addresses.add(addressFromJson(a));
        }
      }
    }
    return CartDeliveryState(
      selectedAddress: selected is Map<String, dynamic>
          ? addressFromJson(selected)
          : null,
      addresses: addresses,
      canCheckout: json['canCheckout'] == true,
    );
  }

  /// Builds cart rows from summary lines (used for badge / light refresh).
  static List<CartItem> itemsFromSummary(CartSummary summary) {
    return [
      for (final line in summary.items)
        if (line.cartId.isNotEmpty)
          CartItem(
            cartId: line.cartId,
            productId: line.productId,
            productType: line.productType,
            title: (line.name != null && line.name!.isNotEmpty)
                ? line.name!
                : 'Product',
            category: CartProductType.label(line.productType),
            quantity: line.quantity,
            priceUsd: line.lineTotal,
            unitPriceUsd: line.unitPrice,
            lineTotalUsd: line.lineTotal,
            imageUrl: line.image,
            sellerId: line.sellerId,
            quantityEditable: false,
          ),
    ];
  }

  /// Merges summary line pricing onto hydrated cart rows.
  ///
  /// When a row already has melee [CartItem.lineTotalUsd] from specifications
  /// (`calculatedPrice` / lot share), keep that price — summary often prices
  /// separable melee as `pricePerPcs × pcs`, which disagrees with detail.
  static List<CartItem> mergeSummaryPrices(
    List<CartItem> items,
    CartSummary summary,
  ) {
    if (summary.items.isEmpty) return items;
    final byCartId = {for (final line in summary.items) line.cartId: line};
    return [
      for (final item in items)
        if (byCartId[item.cartId] case final line?)
          item.lineTotalUsd != null
              ? item.copyWith(
                  title: (line.name != null && line.name!.isNotEmpty)
                      ? line.name
                      : item.title,
                  quantity: line.quantity,
                )
              : item.copyWith(
                  title: (line.name != null && line.name!.isNotEmpty)
                      ? line.name
                      : item.title,
                  quantity: line.quantity,
                  unitPriceUsd: line.unitPrice,
                  lineTotalUsd: line.lineTotal,
                  priceUsd: line.lineTotal,
                )
        else
          item,
    ];
  }

  /// Prefer hydrated `/cart` rows; fall back to summary lines when cart is empty.
  static List<CartItem> mergeCartAndSummary(
    List<CartItem> cartItems,
    CartSummary summary,
  ) {
    if (cartItems.isEmpty) return itemsFromSummary(summary);
    return mergeSummaryPrices(cartItems, summary);
  }

  /// Aligns summary money with cart rows after melee price correction.
  static CartSummary reconcileSummaryPrices(
    CartSummary summary,
    List<CartItem> items,
  ) {
    if (items.isEmpty) return summary;

    final byId = {for (final item in items) item.cartId: item};
    var changed = false;
    final lines = <CartSummaryLine>[];

    if (summary.items.isEmpty) {
      for (final item in items) {
        lines.add(
          CartSummaryLine(
            cartId: item.cartId,
            productId: item.productId,
            productType: item.productType,
            quantity: item.quantity,
            unitPrice: item.unitPriceUsd ?? item.displayPriceUsd,
            lineTotal: item.displayPriceUsd,
            sellerId: item.sellerId,
            name: item.title,
            image: item.imageUrl,
          ),
        );
      }
      changed = true;
    } else {
      for (final line in summary.items) {
        final item = byId[line.cartId];
        if (item == null) {
          lines.add(line);
          continue;
        }
        final corrected = item.displayPriceUsd;
        if ((corrected - line.lineTotal).abs() > 0.009) {
          changed = true;
          lines.add(
            CartSummaryLine(
              cartId: line.cartId,
              productId: line.productId,
              productType: line.productType,
              quantity: line.quantity,
              unitPrice: item.unitPriceUsd ?? corrected,
              lineTotal: corrected,
              sellerId: line.sellerId ?? item.sellerId,
              name: line.name ?? item.title,
              image: line.image ?? item.imageUrl,
            ),
          );
        } else {
          lines.add(line);
        }
      }
    }

    if (!changed) return summary;

    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    final discounted = (subtotal - summary.totalDiscount).clamp(
      0.0,
      double.infinity,
    );
    return CartSummary(
      items: lines,
      subtotal: subtotal,
      automaticDiscountTotal: summary.automaticDiscountTotal,
      promoDiscountTotal: summary.promoDiscountTotal,
      totalDiscount: summary.totalDiscount,
      discountedSubtotal: discounted,
      totalUsd: summary.totalUsd,
      totalInr: summary.totalInr,
      appliedPromoCodes: summary.appliedPromoCodes,
      automaticDiscounts: summary.automaticDiscounts,
    );
  }

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _int(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String? _firstImage(Map<String, dynamic> product) {
    for (final key in ['image1', 'image2', 'image3', 'imageUrl', 'thumbnail']) {
      final v = _str(product[key]);
      if (v != null) return v;
    }
    final images = product['images'];
    if (images is List && images.isNotEmpty) {
      return _str(images.first);
    }
    return null;
  }

  /// Resolves purchasability from cart row + nested product fields.
  static ({bool isAvailable, String? label}) _productAvailability(
    Map<String, dynamic> row,
    Map<String, dynamic> product,
  ) {
    if (row['isSold'] == true || product['isSold'] == true) {
      return (isAvailable: false, label: 'Sold');
    }
    if (row['isAvailable'] == false || product['isAvailable'] == false) {
      return (isAvailable: false, label: 'Unavailable');
    }

    final status =
        (_str(row['status']) ??
                _str(product['status']) ??
                _str(product['productStatus']) ??
                '')
            .toLowerCase();
    if (status == 'sold' ||
        status == 'unavailable' ||
        status == 'deleted' ||
        status == 'inactive') {
      return (
        isAvailable: false,
        label: status == 'sold' ? 'Sold' : 'Unavailable',
      );
    }

    final raw =
        (_str(row['available']) ??
                _str(row['availability']) ??
                _str(row['availabilityStatus']) ??
                _str(product['available']) ??
                _str(product['availability']) ??
                _str(product['availabilityStatus']) ??
                '')
            .toLowerCase();

    if (CatalogPurchasePolicy.isOnHoldOrMemo(raw)) {
      return (
        isAvailable: false,
        label: CatalogPurchasePolicy.normalizeCode(raw) == 'memo'
            ? 'On memo'
            : 'On hold',
      );
    }

    return switch (raw) {
      'hold' || 'on hold' || 'memo' || 'on memo' => (
        isAvailable: false,
        label: raw == 'memo' || raw == 'on memo' ? 'On memo' : 'On hold',
      ),
      'no' ||
      'sold' ||
      'unavailable' ||
      'false' ||
      '0' ||
      'n/a' ||
      'na' ||
      'out of stock' ||
      'outofstock' => (
        isAvailable: false,
        label: raw == 'sold' ? 'Sold' : 'Unavailable',
      ),
      _ => (isAvailable: true, label: null),
    };
  }
}
