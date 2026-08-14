/// Seller registration fields from login `sellerData` / JWT `seller`.
///
/// Kept on the signed-in session so the owner's profile can show company and
/// address while admin KYC is still pending. This is not public storefront data.
class SellerAccountSnapshot {
  const SellerAccountSnapshot({
    this.companyName,
    this.sellerType,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.businessPhone1,
    this.businessPhone2,
    this.representativeName1,
    this.representativeName2,
    this.panCardNumber,
    this.aadhaarNumber,
    this.iecNumber,
    this.gstNumber,
    this.companyLogoUrl,
    this.bannerImageUrl,
    this.panCardUrl,
  });

  final String? companyName;
  final String? sellerType;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? businessPhone1;
  final String? businessPhone2;
  final String? representativeName1;
  final String? representativeName2;
  final String? panCardNumber;
  final String? aadhaarNumber;
  final String? iecNumber;
  final String? gstNumber;
  final String? companyLogoUrl;
  final String? bannerImageUrl;
  final String? panCardUrl;

  bool get hasAnyField =>
      companyName != null ||
      sellerType != null ||
      addressLine1 != null ||
      addressLine2 != null ||
      city != null ||
      state != null ||
      country != null ||
      zipCode != null ||
      businessPhone1 != null ||
      businessPhone2 != null ||
      representativeName1 != null ||
      representativeName2 != null ||
      panCardNumber != null ||
      aadhaarNumber != null ||
      iecNumber != null ||
      gstNumber != null ||
      companyLogoUrl != null ||
      bannerImageUrl != null ||
      panCardUrl != null;

  factory SellerAccountSnapshot.fromJson(Map<String, dynamic> json) {
    return SellerAccountSnapshot(
      companyName: _str(json['companyName']),
      sellerType: _str(json['sellerType']),
      addressLine1: _str(json['addressLine1']),
      addressLine2: _str(json['addressLine2']),
      city: _str(json['city']),
      state: _str(json['state']),
      country: _str(json['country']),
      zipCode: _str(json['zipCode']) ?? _str(json['zip']),
      businessPhone1: _str(json['phone1']) ??
          _str(json['phone']) ??
          _str(json['businessPhone1']),
      businessPhone2: _str(json['phone2']) ?? _str(json['businessPhone2']),
      representativeName1: _str(json['representativeName1']),
      representativeName2: _str(json['representativeName2']),
      panCardNumber: _str(json['panCardNumber']) ?? _str(json['pan']),
      aadhaarNumber: _str(json['aadhaarNumber']),
      iecNumber: _str(json['iecNumber']),
      gstNumber: _str(json['gstNumber']) ?? _str(json['gstin']),
      companyLogoUrl:
          _str(json['companyLogo']) ?? _str(json['companyLogoUrl']),
      bannerImageUrl:
          _str(json['bannerImage']) ?? _str(json['bannerImageUrl']),
      panCardUrl: _str(json['panCard']) ?? _str(json['panCardUrl']),
    );
  }

  static SellerAccountSnapshot? tryParse(Object? value) {
    if (value is Map<String, dynamic>) {
      final snap = SellerAccountSnapshot.fromJson(value);
      return snap.hasAnyField ? snap : null;
    }
    if (value is Map) {
      final snap = SellerAccountSnapshot.fromJson(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
      return snap.hasAnyField ? snap : null;
    }
    return null;
  }

  /// [preferred] wins; blanks are filled from [fallback].
  static SellerAccountSnapshot? merge(
    SellerAccountSnapshot? preferred,
    SellerAccountSnapshot? fallback,
  ) {
    if (preferred == null) return fallback;
    if (fallback == null) return preferred;
    return SellerAccountSnapshot(
      companyName: _prefer(preferred.companyName, fallback.companyName),
      sellerType: _prefer(preferred.sellerType, fallback.sellerType),
      addressLine1: _prefer(preferred.addressLine1, fallback.addressLine1),
      addressLine2: _prefer(preferred.addressLine2, fallback.addressLine2),
      city: _prefer(preferred.city, fallback.city),
      state: _prefer(preferred.state, fallback.state),
      country: _prefer(preferred.country, fallback.country),
      zipCode: _prefer(preferred.zipCode, fallback.zipCode),
      businessPhone1:
          _prefer(preferred.businessPhone1, fallback.businessPhone1),
      businessPhone2:
          _prefer(preferred.businessPhone2, fallback.businessPhone2),
      representativeName1: _prefer(
        preferred.representativeName1,
        fallback.representativeName1,
      ),
      representativeName2: _prefer(
        preferred.representativeName2,
        fallback.representativeName2,
      ),
      panCardNumber: _prefer(preferred.panCardNumber, fallback.panCardNumber),
      aadhaarNumber: _prefer(preferred.aadhaarNumber, fallback.aadhaarNumber),
      iecNumber: _prefer(preferred.iecNumber, fallback.iecNumber),
      gstNumber: _prefer(preferred.gstNumber, fallback.gstNumber),
      companyLogoUrl:
          _prefer(preferred.companyLogoUrl, fallback.companyLogoUrl),
      bannerImageUrl:
          _prefer(preferred.bannerImageUrl, fallback.bannerImageUrl),
      panCardUrl: _prefer(preferred.panCardUrl, fallback.panCardUrl),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (companyName != null) 'companyName': companyName,
      if (sellerType != null) 'sellerType': sellerType,
      if (addressLine1 != null) 'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (zipCode != null) 'zipCode': zipCode,
      if (businessPhone1 != null) 'phone1': businessPhone1,
      if (businessPhone2 != null) 'phone2': businessPhone2,
      if (representativeName1 != null)
        'representativeName1': representativeName1,
      if (representativeName2 != null)
        'representativeName2': representativeName2,
      if (panCardNumber != null) 'panCardNumber': panCardNumber,
      if (aadhaarNumber != null) 'aadhaarNumber': aadhaarNumber,
      if (iecNumber != null) 'iecNumber': iecNumber,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (companyLogoUrl != null) 'companyLogo': companyLogoUrl,
      if (bannerImageUrl != null) 'bannerImage': bannerImageUrl,
      if (panCardUrl != null) 'panCard': panCardUrl,
    };
  }

  static String? _prefer(String? a, String? b) {
    if (a != null && a.trim().isNotEmpty) return a;
    if (b != null && b.trim().isNotEmpty) return b;
    return null;
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
