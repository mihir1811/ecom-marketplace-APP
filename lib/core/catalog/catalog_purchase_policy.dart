import '../../features/product_detail/domain/models/product_detail.dart';

/// Shared add-to-cart rules for catalog listings (memo/hold/sold/own listing).
abstract final class CatalogPurchasePolicy {
  static String? normalizeCode(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return null;
    if (value == 'yes' ||
        value == 'available' ||
        value == 'in stock' ||
        value.contains('in stock')) {
      return 'yes';
    }
    // Check unavailable before `available` substring matches.
    if (value == 'no' ||
        value == 'unavailable' ||
        value.contains('unavailable') ||
        value.contains('out of stock')) {
      return 'unavailable';
    }
    if (value.contains('available')) return 'yes';
    if (value == 'hold' || value == 'on hold' || value.contains('hold')) {
      return 'hold';
    }
    if (value == 'memo' || value == 'on memo' || value.contains('memo')) {
      return 'memo';
    }
    if (value == 'sold' || value.contains('sold')) return 'sold';
    return value;
  }

  static bool isOnHoldOrMemo(String? raw) {
    return switch (normalizeCode(raw)) {
      'hold' || 'memo' => true,
      _ => _labelImpliesHoldOrMemo(raw),
    };
  }

  static bool isSoldOrUnavailable(String? raw) {
    return switch (normalizeCode(raw)) {
      'sold' || 'unavailable' || 'no' => true,
      _ => false,
    };
  }

  static bool canAddToCart({
    String? availabilityStatus,
    ProductAvailability? availability,
  }) {
    if (isSoldOrUnavailable(availabilityStatus)) return false;
    if (isOnHoldOrMemo(availabilityStatus)) return false;
    if (availability?.tone == ProductStockTone.unavailable) return false;
    final label = availability?.label;
    if (isOnHoldOrMemo(label) || isSoldOrUnavailable(label)) return false;
    return true;
  }

  static String? addToCartBlockMessage({
    required bool ownListing,
    String? availabilityStatus,
    ProductAvailability? availability,
  }) {
    if (ownListing) return 'You cannot purchase your own listing';
    if (isOnHoldOrMemo(availabilityStatus) || isOnHoldOrMemo(availability?.label)) {
      final code = normalizeCode(availabilityStatus) ??
          normalizeCode(availability?.label);
      if (code == 'memo') {
        return 'This item is on memo and cannot be added to cart';
      }
      return 'This item is on hold and cannot be added to cart';
    }
    if (!canAddToCart(
      availabilityStatus: availabilityStatus,
      availability: availability,
    )) {
      return 'This item is unavailable';
    }
    return null;
  }

  static bool _labelImpliesHoldOrMemo(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return false;
    return value.contains('on hold') ||
        value == 'hold' ||
        value.contains('on memo') ||
        value == 'memo';
  }
}
