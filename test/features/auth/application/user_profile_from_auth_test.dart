import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/auth/auth_user.dart';
import 'package:gemstone/core/auth/seller_account_snapshot.dart';
import 'package:gemstone/features/auth/application/user_profile_providers.dart';
import 'package:gemstone/features/auth/domain/models/user_profile.dart';

void main() {
  test('userProfileFromAuth copies login sellerData onto own profile', () {
    final user = AuthUser.fromJson({
      'id': 'u1',
      'name': 'harshil',
      'userName': 'harshil123',
      'email': 'h@x.com',
      'role': 'seller',
      'isVerified': true,
      'sellerData': {
        'companyName': 'temp',
        'sellerType': 'naturalDiamond',
        'addressLine1': '12 Market St',
        'city': 'Surat',
        'state': 'Gujarat',
        'country': 'India',
        'zipCode': '395007',
        'companyLogo': 'https://cdn.example/logo.png',
        'bannerImage': 'https://cdn.example/banner.png',
        'isVerified': false,
      },
    });

    final profile = userProfileFromAuth(user);

    expect(profile.isVerified, isFalse);
    expect(profile.companyName, 'temp');
    expect(profile.sellerType, 'naturalDiamond');
    expect(profile.addressLine1, '12 Market St');
    expect(profile.city, 'Surat');
    expect(profile.companyLogoUrl, 'https://cdn.example/logo.png');
    expect(profile.bannerImageUrl, 'https://cdn.example/banner.png');
  });

  test('overlaySellerAccount fills empty profile API fields from snapshot', () {
    const empty = UserProfile(
      id: 'u1',
      fullName: 'harshil',
      username: 'harshil123',
      email: 'h@x.com',
      role: 'seller',
      isVerified: true,
    );
    const user = AuthUser(
      id: 'u1',
      fullName: 'harshil',
      username: 'harshil123',
      email: 'h@x.com',
      role: 'seller',
      isVerified: false,
      sellerAccount: SellerAccountSnapshot(
        companyName: 'temp',
        addressLine1: '12 Market St',
      ),
    );

    final merged = overlaySellerAccount(empty, user);

    expect(merged.isVerified, isFalse);
    expect(merged.companyName, 'temp');
    expect(merged.addressLine1, '12 Market St');
    expect(merged.fullName, 'harshil');
  });

  test('JWT bootstrap keeps cached address when claims only have companyName', () {
    final user = AuthUser.fromJwtClaims(
      {
        'sub': 'u1',
        'userName': 'harshil123',
        'role': 'seller',
        'isVerified': true,
        'seller': {
          'id': 's1',
          'companyName': 'temp',
          'isVerified': false,
        },
      },
      cachedSellerAccount: const SellerAccountSnapshot(
        companyName: 'temp',
        addressLine1: '12 Market St',
        city: 'Surat',
      ),
    );

    expect(user.isVerified, isFalse);
    expect(user.sellerAccount?.companyName, 'temp');
    expect(user.sellerAccount?.addressLine1, '12 Market St');
    expect(user.sellerAccount?.city, 'Surat');
  });
}
