enum BankAccountType {
  savings('SAVINGS', 'Savings'),
  current('CURRENT', 'Current');

  const BankAccountType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static BankAccountType? fromApi(String? raw) {
    for (final type in BankAccountType.values) {
      if (type.apiValue == raw) return type;
    }
    return null;
  }
}

class UserBankAccount {
  const UserBankAccount({
    required this.id,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.accountType,
    this.upiId,
    this.createdAtLabel,
    this.updatedAtLabel,
  });

  final String id;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final BankAccountType? accountType;
  final String? upiId;
  final String? createdAtLabel;
  final String? updatedAtLabel;
}

class UserBankAccountStatus {
  const UserBankAccountStatus({required this.hasBankAccount, this.bankAccount});

  final bool hasBankAccount;
  final UserBankAccount? bankAccount;
}

class UserBankAccountInput {
  const UserBankAccountInput({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.accountType,
    this.upiId,
  });

  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final BankAccountType? accountType;
  final String? upiId;

  Map<String, dynamic> toJson() => {
    'accountHolderName': accountHolderName.trim(),
    'accountNumber': accountNumber.trim(),
    'ifscCode': ifscCode.trim(),
    'bankName': bankName.trim(),
    if (accountType != null) 'accountType': accountType!.apiValue,
    if (upiId != null && upiId!.trim().isNotEmpty) 'upiId': upiId!.trim(),
  };
}
