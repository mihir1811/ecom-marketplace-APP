import '../../domain/models/user_bank_account.dart';

abstract final class UserBankAccountMapper {
  static UserBankAccount fromJson(Map<String, dynamic> json) {
    return UserBankAccount(
      id: json['id']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifscCode: json['ifscCode']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      accountType: BankAccountType.fromApi(json['accountType']?.toString()),
      upiId: _nullableString(json['upiId']),
      createdAtLabel: _label(_parseDate(json['createdAt'])),
      updatedAtLabel: _label(_parseDate(json['updatedAt'])),
    );
  }

  static UserBankAccountStatus statusFromJson(Map<String, dynamic>? root) {
    final data = root?['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final bankRaw = map['bankAccount'];
    return UserBankAccountStatus(
      hasBankAccount: map['hasBankAccount'] == true,
      bankAccount: bankRaw is Map<String, dynamic> ? fromJson(bankRaw) : null,
    );
  }

  static String? _nullableString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static String? _label(DateTime? date) {
    if (date == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}
