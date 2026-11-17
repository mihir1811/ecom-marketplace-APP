import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/network/response_parser.dart';
import 'package:gemworld/features/auth/data/mappers/user_profile_mapper.dart';

void main() {
  test('maps nested data.user envelope used by GET /user/profile', () {
    final profile = UserProfileMapper.fromResponse({
      'success': true,
      'message': 'Profile fetched successfully.',
      'data': {
        'user': {
          'id': 'user-1',
          'name': 'Prem',
          'userName': 'prem',
          'email': 'premsattvam@gmail.com',
          'role': 'seller',
          'isVerified': false,
        },
        'business': {'companyName': 'Sattvam'},
      },
    });

    expect(profile?.id, 'user-1');
    expect(profile?.fullName, 'Prem');
    expect(profile?.email, 'premsattvam@gmail.com');
    expect(profile?.role, 'seller');
    expect(profile?.isVerified, isFalse);
    expect(profile?.companyName, 'Sattvam');
  });

  test('maps double-wrapped data.data and _id', () {
    final profile = UserProfileMapper.fromResponse({
      'success': true,
      'data': {
        'data': {
          '_id': 'abc',
          'email': 'a@b.com',
          'name': 'A',
          'userName': 'a',
          'role': 'buyer',
          'isVerified': true,
        },
      },
    });

    expect(profile?.id, 'abc');
    expect(profile?.email, 'a@b.com');
    expect(profile?.isVerified, isTrue);
  });

  test('returns null for an empty success envelope', () {
    expect(
      UserProfileMapper.fromResponse({
        'success': true,
        'data': <String, dynamic>{},
      }),
      isNull,
    );
  });

  test('sellerData.isVerified false stays pending even if user.isVerified', () {
    final profile = UserProfileMapper.fromJson({
      'id': 'user-1',
      'name': 'harshil',
      'userName': 'harshil123',
      'email': 'h@x.com',
      'role': 'seller',
      'isVerified': true,
      'sellerData': {'companyName': 'temp', 'isVerified': false},
    });

    expect(profile.isVerified, isFalse);
    expect(profile.companyName, 'temp');
  });

  test('null profile data envelope is empty', () {
    expect(
      UserProfileMapper.fromResponse({
        'success': true,
        'message': 'User retrieved successfully.',
        'data': null,
      }),
      isNull,
    );
  });

  test('entity unwraps Map with non-String-typed nested data', () {
    final root = <String, dynamic>{
      'success': true,
      'data': <dynamic, dynamic>{
        'id': 42,
        'email': 'n@n.com',
        'name': 'Nested',
      },
    };
    final entity = ResponseParser.entity(root);
    expect(entity?['id'], 42);
    expect(entity?['email'], 'n@n.com');
  });
}
