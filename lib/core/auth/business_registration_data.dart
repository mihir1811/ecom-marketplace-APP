import 'package:image_picker/image_picker.dart';

/// Account path chosen on the registration screen.
enum RegistrationAccountType {
  individual,
  business,
}

extension RegistrationAccountTypeApi on RegistrationAccountType {
  String get apiValue => switch (this) {
        RegistrationAccountType.individual => 'individual',
        RegistrationAccountType.business => 'business',
      };
}

/// Seller catalogue categories accepted by `/auth/register` for business.
enum SellerType {
  naturalDiamond,
  labGrownDiamond,
  jewellery,
  gemstone,
  bullion,
  watch,
}

extension SellerTypeApi on SellerType {
  String get apiValue => name;

  String get label => switch (this) {
        SellerType.naturalDiamond => 'Natural diamond',
        SellerType.labGrownDiamond => 'Lab-grown diamond',
        SellerType.jewellery => 'Jewellery',
        SellerType.gemstone => 'Gemstone',
        SellerType.bullion => 'Bullion',
        SellerType.watch => 'Watch',
      };
}

/// Bank account types accepted by business registration.
enum BankAccountType {
  savings,
  current,
}

extension BankAccountTypeApi on BankAccountType {
  String get apiValue => switch (this) {
        BankAccountType.savings => 'SAVINGS',
        BankAccountType.current => 'CURRENT',
      };

  String get label => switch (this) {
        BankAccountType.savings => 'Savings',
        BankAccountType.current => 'Current',
      };
}

/// Extra fields required when [RegistrationAccountType.business] is selected.
class BusinessRegistrationData {
  const BusinessRegistrationData({
    required this.companyName,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.sellerType,
    required this.phone1,
    required this.phone2,
    required this.representativeName1,
    required this.representativeName2,
    required this.panCardNumber,
    required this.aadhaarNumber,
    required this.iecNumber,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.accountType,
    required this.companyLogo,
    required this.panCard,
    this.gstNumber,
    this.website,
  });

  final String companyName;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final SellerType sellerType;
  final String phone1;
  final String phone2;
  final String representativeName1;
  final String representativeName2;
  final String panCardNumber;
  final String aadhaarNumber;
  final String iecNumber;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final BankAccountType accountType;
  final XFile companyLogo;
  final XFile panCard;
  final String? gstNumber;
  final String? website;
}
