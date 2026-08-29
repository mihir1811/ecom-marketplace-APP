/// Seller identity attached to a marketplace listing (from API `seller` object).
class ListingSellerInfo {
  const ListingSellerInfo({
    required this.displayName,
    this.id,
    this.userId,
    this.email,
    this.phone,
    this.location,
    this.registrationType = ListingSellerRegistrationType.unknown,
  });

  /// Seller record id from the listing payload.
  final String? id;

  /// Linked user id when the API nests `userId` / `user.id`.
  final String? userId;
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

  /// True when this listing belongs to the signed-in seller/user.
  bool isOwnedBy({required String? userId, required String? sellerId}) {
    bool same(String? a, String? b) {
      final left = a?.trim() ?? '';
      final right = b?.trim() ?? '';
      return left.isNotEmpty && left == right;
    }

    return same(id, sellerId) ||
        same(id, userId) ||
        same(this.userId, userId) ||
        same(this.userId, sellerId);
  }
}

enum ListingSellerRegistrationType { individual, business, unknown }

ListingSellerInfo? listingSellerFromSellerId(String? sellerId) {
  final id = sellerId?.trim();
  if (id == null || id.isEmpty) return null;
  return ListingSellerInfo(id: id, displayName: 'Seller');
}

ListingSellerInfo? listingSellerFromListingPayload({
  Object? sellerRaw,
  String? sellerId,
}) {
  final parsed = listingSellerFromMap(sellerRaw);
  if (parsed != null) return parsed;
  return listingSellerFromSellerId(sellerId);
}

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

  final nestedUser = map['user'];
  final nestedUserId = nestedUser is Map
      ? _str(nestedUser['id']) ?? _str(nestedUser['_id'])
      : null;

  final company = _str(map['companyName']);
  final representative = _str(map['representativeName1']) ??
      _str(map['representativeName']) ??
      _str(map['name']) ??
      _str(map['fullName']);
  final displayName = company ?? representative;
  final sellerId = _str(map['id']) ?? _str(map['_id']) ?? _str(map['sellerId']);
  final userId = _str(map['userId']) ?? nestedUserId;
  if (displayName == null && sellerId == null && userId == null) return null;

  final city = _str(map['city']);
  final country = _str(map['country']);
  final location = [city, country].where((p) => p != null).join(', ');

  return ListingSellerInfo(
    id: sellerId,
    userId: userId,
    displayName: displayName ?? 'Seller',
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
