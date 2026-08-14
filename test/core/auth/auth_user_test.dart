import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_user.dart';

void main() {
  test('fromJson reads isVerified false and _id', () {
    final user = AuthUser.fromJson({
      '_id': 'u1',
      'name': 'Prem',
      'userName': 'prem',
      'email': 'premsattvam@gmail.com',
      'role': 'seller',
      'isVerified': false,
    });

    expect(user.id, 'u1');
    expect(user.isVerified, isFalse);
  });

  test('pending verificationStatus is not verified', () {
    expect(
      parseAccountVerified({'verificationStatus': 'PENDING'}),
      isFalse,
    );
    expect(parseAccountVerified({'isApproved': false}), isFalse);
    expect(parseAccountVerified({'isVerified': 'false'}), isFalse);
  });

  test('seller email OTP true does not count as admin verification', () {
    final user = AuthUser.fromJson({
      'id': '6854f7f4-805c-4cf9-8dae-54f9810eb5d3',
      'name': 'harshil',
      'email': 'harshilmalaviya000@gmail.com',
      'userName': 'harshil123',
      'role': 'seller',
      'registrationType': 'business',
      'isVerified': true,
      'sellerData': {
        'id': '34410f92-4c18-4d02-a78f-61146c646036',
        'companyName': 'temp',
        'isVerified': false,
        'addressLine1': '12 Market St',
        'city': 'Surat',
        'companyLogo': 'https://cdn.example/logo.png',
      },
    });

    expect(user.isVerified, isFalse);
    expect(user.sellerAccount?.companyName, 'temp');
    expect(user.sellerAccount?.addressLine1, '12 Market St');
    expect(user.sellerAccount?.city, 'Surat');
    expect(user.sellerAccount?.companyLogoUrl, 'https://cdn.example/logo.png');
  });

  test('JWT seller.isVerified false keeps account pending', () {
    final user = AuthUser.fromJwtClaims({
      'sub': 'u1',
      'userName': 'harshil123',
      'role': 'seller',
      'isVerified': true,
      'seller': {
        'id': 's1',
        'isVerified': false,
      },
    });

    expect(user.isVerified, isFalse);
  });
}
