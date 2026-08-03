import '../../domain/models/cart_item.dart';
import '../../domain/models/cart_product_type.dart';
import '../../domain/models/cart_summary.dart';
import '../../domain/models/delivery_address.dart';

/// Parses cart / delivery JSON into domain models.
abstract final class CartMapper {
  static CartItem cartItemFromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap =
        product is Map<String, dynamic> ? product : const <String, dynamic>{};
    final productType = _str(json['productType']) ?? '';
    final price = _num(productMap['totalPrice']) ??
        _num(productMap['price']) ??
        0;
    final name = _str(productMap['name']) ??
        _str(productMap['brand']) ??
        _str(productMap['stockNumber']) ??
        'Product';
    final image = _str(productMap['image1']) ??
        _str(productMap['image']) ??
        _firstImage(productMap);

    return CartItem(
      cartId: _str(json['id']) ?? '',
      productId: _str(json['productId']) ?? _str(productMap['id']) ?? '',
      productType: productType,
      title: name,
      category: CartProductType.label(productType),
      quantity: _int(json['quantity']) ?? 1,
      priceUsd: price,
      imageUrl: image,
      shape: _str(productMap['shape']),
      seller: _str(json['seller']) ?? _str(productMap['sellerName']),
      sellerId: _str(json['sellerId']),
      quantityEditable: false,
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
              discountAmount: _num(p['discountAmount']) ??
                  _num(p['discount']) ??
                  0,
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
            discountAmount: _num(a['discountAmount']) ??
                _num(a['discount']) ??
                0,
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

  /// Merges summary line pricing onto hydrated cart rows.
  static List<CartItem> mergeSummaryPrices(
    List<CartItem> items,
    CartSummary summary,
  ) {
    if (summary.items.isEmpty) return items;
    final byCartId = {
      for (final line in summary.items) line.cartId: line,
    };
    return [
      for (final item in items)
        if (byCartId[item.cartId] case final line?)
          item.copyWith(
            quantity: line.quantity,
            unitPriceUsd: line.unitPrice,
            lineTotalUsd: line.lineTotal,
            priceUsd: line.lineTotal,
          )
        else
          item,
    ];
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
}
