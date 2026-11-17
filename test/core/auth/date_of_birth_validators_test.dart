import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/auth/auth_validators.dart';

void main() {
  group('dateOfBirth helpers', () {
    test('formats API value as YYYY-MM-DD', () {
      expect(formatDateOfBirthForApi(DateTime(1995, 6, 15)), '1995-06-15');
      expect(formatDateOfBirthForApi(DateTime(2000, 1, 5)), '2000-01-05');
    });

    test('requires a date', () {
      expect(validateDateOfBirth(null), isNotNull);
    });

    test('rejects future dates', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(validateDateOfBirth(tomorrow), isNotNull);
    });

    test('rejects under-18', () {
      final now = DateTime.now();
      final under18 = DateTime(now.year - 17, now.month, now.day);
      expect(validateDateOfBirth(under18), isNotNull);
    });

    test('accepts adult date of birth', () {
      final now = DateTime.now();
      final adult = DateTime(now.year - 25, now.month, now.day);
      expect(validateDateOfBirth(adult), isNull);
    });
  });
}
