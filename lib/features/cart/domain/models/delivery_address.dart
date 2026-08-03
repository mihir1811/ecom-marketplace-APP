/// Saved delivery destination for checkout.
class DeliveryAddress {
  const DeliveryAddress({
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.id,
    this.line2,
    this.label,
    this.isDefault = false,
  });

  final String? id;
  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? label;
  final bool isDefault;

  String get summaryLine {
    final parts = [
      line1,
      if (line2 != null && line2!.trim().isNotEmpty) line2!,
      '$city, $state $postalCode',
      country,
    ];
    return parts.join(', ');
  }

  DeliveryAddress copyWith({String? id, bool? isDefault}) {
    return DeliveryAddress(
      id: id ?? this.id,
      fullName: fullName,
      phone: phone,
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      label: label,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Cart delivery selection state from GET /delivery-options/cart.
class CartDeliveryState {
  const CartDeliveryState({
    this.selectedAddress,
    this.addresses = const [],
    this.canCheckout = false,
  });

  final DeliveryAddress? selectedAddress;
  final List<DeliveryAddress> addresses;
  final bool canCheckout;
}
