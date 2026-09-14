import '../../../../core/auth/auth_user.dart';
import '../../../../core/network/response_parser.dart';
import '../../../../core/utils/media_url.dart';
import '../../domain/models/user_profile.dart';

abstract final class UserProfileMapper {
  static UserProfile fromJson(Map<String, dynamic> json) {
    final user =
        ResponseParser.asMap(json['user']) ??
        ResponseParser.asMap(json['profile']) ??
        json;
    final business =
        ResponseParser.asMap(json['business']) ??
        ResponseParser.asMap(json['sellerData']) ??
        ResponseParser.asMap(json['seller']) ??
        ResponseParser.asMap(json['sellerProfile']) ??
        ResponseParser.asMap(user['business']) ??
        ResponseParser.asMap(user['sellerData']) ??
        ResponseParser.asMap(user['seller']) ??
        const <String, dynamic>{};
    final bank =
        ResponseParser.asMap(json['bankAccount']) ??
        ResponseParser.asMap(json['bank']) ??
        ResponseParser.asMap(business['bankAccount']) ??
        ResponseParser.asMap(user['bankAccount']) ??
        const <String, dynamic>{};

    return UserProfile(
      id:
          _str(user['id']) ??
          _str(user['_id']) ??
          _str(user['userId']) ??
          _str(json['id']) ??
          _str(json['_id']) ??
          '',
      fullName:
          _str(user['name']) ??
          _str(user['fullName']) ??
          _str(json['name']) ??
          '',
      username:
          _str(user['userName']) ??
          _str(user['username']) ??
          _str(json['userName']) ??
          '',
      email: _str(user['email']) ?? _str(json['email']) ?? '',
      role: _str(user['role']) ?? _str(json['role']) ?? '',
      profilePicture:
          MediaUrl.resolve(
            _str(user['profilePicture']) ??
                _str(user['avatar']) ??
                _str(user['image']) ??
                _str(user['photo']) ??
                _str(json['profilePicture']) ??
                _str(json['avatar']),
          ) ??
          '',
      isVerified: parseAccountVerified(user) && parseAccountVerified(json),
      companyName: _str(business['companyName']) ?? _str(user['companyName']),
      addressLine1:
          _str(business['addressLine1']) ?? _str(user['addressLine1']),
      addressLine2: _str(business['addressLine2']),
      city: _str(business['city']),
      state: _str(business['state']),
      country: _str(business['country']),
      zipCode: _str(business['zipCode']) ?? _str(business['zip']),
      sellerType: _str(business['sellerType']),
      businessPhone1:
          _str(business['phone1']) ??
          _str(business['phone']) ??
          _str(user['phone1']) ??
          _str(json['phone1']),
      businessPhone2:
          _str(business['phone2']) ??
          _str(user['phone2']) ??
          _str(json['phone2']),
      representativeName1:
          _str(business['representativeName1']) ??
          _str(user['representativeName1']),
      representativeName2:
          _str(business['representativeName2']) ??
          _str(user['representativeName2']),
      panCardNumber:
          _str(business['panCardNumber']) ??
          _str(business['pan']) ??
          _str(user['panCardNumber']) ??
          _str(user['pan']),
      aadhaarNumber:
          _str(business['aadhaarNumber']) ?? _str(user['aadhaarNumber']),
      iecNumber: _str(business['iecNumber']) ?? _str(user['iecNumber']),
      gstNumber:
          _str(business['gstNumber']) ??
          _str(business['gstin']) ??
          _str(user['gstNumber']) ??
          _str(user['gstin']),
      companyLogoUrl: MediaUrl.resolve(
        _str(business['companyLogo']) ?? _str(business['companyLogoUrl']),
      ),
      bannerImageUrl: MediaUrl.resolve(
        _str(business['bannerImage']) ?? _str(business['bannerImageUrl']),
      ),
      panCardUrl: MediaUrl.resolve(
        _str(business['panCard']) ?? _str(business['panCardUrl']),
      ),
      accountHolderName: _str(bank['accountHolderName']),
      accountNumber: _str(bank['accountNumber']),
      ifscCode: _str(bank['ifscCode']),
      bankName: _str(bank['bankName']),
      accountType: _str(bank['accountType']),
      upiId: _str(bank['upiId']),
    );
  }

  static UserProfile? fromResponse(Map<String, dynamic>? root) {
    final entity = ResponseParser.entity(root);
    if (entity == null) return null;
    final profile = fromJson(entity);
    if (profile.id.isEmpty && profile.email.isEmpty) return null;
    return profile;
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
