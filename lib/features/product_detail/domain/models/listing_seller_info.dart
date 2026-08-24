/// Seller identity attached to a marketplace listing (from API `seller` object).
class ListingSellerInfo {
  const ListingSellerInfo({
    required this.displayName,
    this.email,
    this.phone,
    this.location,
    this.registrationType = ListingSellerRegistrationType.unknown,
  });

  final String displayName;
  final String? email;
  final String? phone;
  final String? location;
  final ListingSellerRegistrationType registrationType;

  bool get isIndividual =>
      registrationType == ListingSellerRegistrationType.individual;

  bool get hasAnyData =>
      displayName.trim().isNotEmpty ||
      (email?.trim().isNotEmpty ?? false) ||
      (phone?.trim().isNotEmpty ?? false) ||
      (location?.trim().isNotEmpty ?? false);
}

enum ListingSellerRegistrationType { individual, business, unknown }

ListingSellerInfo? listingSellerFromMap(Object? raw) {
  if (raw is! Map) return null;

  final map = raw.map((k, v) => MapEntry(k.toString(), v));
  final registrationRaw =
      _str(map['registrationType']) ?? _str(map['sellerType']);
  final registration = switch (registrationRaw?.toLowerCase()) {
    'individual' => ListingSellerRegistrationType.individual,
    'business' => ListingSellerRegistrationType.business,
    _ => ListingSellerRegistrationType.unknown,
  };

  final company = _str(map['companyName']);
  final representative = _str(map['representativeName1']) ??
      _str(map['representativeName']) ??
      _str(map['name']) ??
      _str(map['fullName']);
  final displayName = company ?? representative;
  if (displayName == null) return null;

  final city = _str(map['city']);
  final country = _str(map['country']);
  final location = [city, country].where((p) => p != null).join(', ');

  return ListingSellerInfo(
    displayName: displayName,
    email: _str(map['email']),
    phone: _str(map['phone1']) ?? _str(map['phone']) ?? _str(map['businessPhone1']),
    location: location.isEmpty ? null : location,
    registrationType: registration,
  );
}

String? _str(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
