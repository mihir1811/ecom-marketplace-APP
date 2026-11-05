import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/auth/account_access.dart';
import 'package:gemworld/core/auth/auth_state.dart';
import 'package:gemworld/core/auth/auth_user.dart';

void main() {
  AuthUser user({required bool verified}) => AuthUser(
        id: 'u1',
        fullName: 'Test',
        username: 'test',
        email: 't@example.com',
        role: 'buyer',
        isVerified: verified,
      );

  test('hides protected chrome while admin KYC is pending', () {
    final pending = AuthState(user: user(verified: false));
    expect(pending.isVerificationPending, isTrue);
    expect(pending.canTransact, isFalse);
    expect(AccountAccess.showProtected(pending), isFalse);
  });

  test('shows protected chrome after admin KYC', () {
    final verified = AuthState(user: user(verified: true));
    expect(verified.isVerificationPending, isFalse);
    expect(verified.canTransact, isTrue);
    expect(AccountAccess.showProtected(verified), isTrue);
  });
}
