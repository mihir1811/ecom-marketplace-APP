import '../../domain/models/user_profile.dart';

abstract final class UserProfileMapper {
  static UserProfile fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']) ?? json;
    final business = _asMap(json['business']) ??
        _asMap(json['seller']) ??
        _asMap(json['sellerProfile']) ??
        _asMap(user['business']) ??
        _asMap(user['seller']) ??
        const <String, dynamic>{};
    final bank = _asMap(json['bankAccount']) ??
        _asMap(json['bank']) ??
        _asMap(business['bankAccount']) ??
        _asMap(user['bankAccount']) ??
        const <String, dynamic>{};

    return UserProfile(
      id: _str(user['id']) ?? _str(json['id']) ?? '',
      fullName: _str(user['name']) ??
          _str(user['fullName']) ??
          _str(json['name']) ??
          '',
      username: _str(user['userName']) ??
          _str(user['username']) ??
          _str(json['userName']) ??
          '',
      email: _str(user['email']) ?? _str(json['email']) ?? '',
      role: _str(user['role']) ?? _str(json['role']) ?? '',
      profilePicture: _str(user['profilePicture']) ??
          _str(json['profilePicture']) ??
          '',
      isVerified: user['isVerified'] as bool? ??
          json['isVerified'] as bool? ??
          true,
      companyName: _str(business['companyName']),
      addressLine1: _str(business['addressLine1']),
      addressLine2: _str(business['addressLine2']),
      city: _str(business['city']),
      state: _str(business['state']),
      country: _str(business['country']),
      zipCode: _str(business['zipCode']) ?? _str(business['zip']),
      sellerType: _str(business['sellerType']),
      businessPhone1: _str(business['phone1']) ?? _str(business['phone']),
      businessPhone2: _str(business['phone2']),
      representativeName1: _str(business['representativeName1']),
      representativeName2: _str(business['representativeName2']),
      panCardNumber: _str(business['panCardNumber']) ?? _str(business['pan']),
      aadhaarNumber: _str(business['aadhaarNumber']),
      iecNumber: _str(business['iecNumber']),
      gstNumber: _str(business['gstNumber']) ?? _str(business['gstin']),
      companyLogoUrl: _str(business['companyLogo']) ??
          _str(business['companyLogoUrl']),
      bannerImageUrl: _str(business['bannerImage']) ??
          _str(business['bannerImageUrl']),
      panCardUrl: _str(business['panCard']) ?? _str(business['panCardUrl']),
      accountHolderName: _str(bank['accountHolderName']),
      accountNumber: _str(bank['accountNumber']),
      ifscCode: _str(bank['ifscCode']),
      bankName: _str(bank['bankName']),
      accountType: _str(bank['accountType']),
      upiId: _str(bank['upiId']),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
