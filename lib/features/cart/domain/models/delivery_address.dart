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
    this.line2,
    this.label,
  });

  final String fullName;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? label;

  String get summaryLine {
    final parts = [
      line1,
      if (line2 != null && line2!.trim().isNotEmpty) line2!,
      '$city, $state $postalCode',
      country,
    ];
    return parts.join(', ');
  }
}
