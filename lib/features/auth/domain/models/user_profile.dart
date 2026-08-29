/// Full account profile from `GET /user/profile` (buyer + seller fields).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.profilePicture = '',
    this.isVerified = true,
    this.companyName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.sellerType,
    this.businessPhone1,
    this.businessPhone2,
    this.representativeName1,
    this.representativeName2,
    this.panCardNumber,
    this.aadhaarNumber,
    this.iecNumber,
    this.gstNumber,
    this.companyLogoUrl,
    this.bannerImageUrl,
    this.panCardUrl,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
    this.accountType,
    this.upiId,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final String profilePicture;
  final bool isVerified;

  // Business / seller registration fields
  final String? companyName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? sellerType;
  final String? businessPhone1;
  final String? businessPhone2;
  final String? representativeName1;
  final String? representativeName2;
  final String? panCardNumber;
  final String? aadhaarNumber;
  final String? iecNumber;
  final String? gstNumber;
  final String? companyLogoUrl;
  final String? bannerImageUrl;
  final String? panCardUrl;

  // Bank (may also come from /user-bank-account)
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;
  final String? accountType;
  final String? upiId;

  bool get isSeller => role.toLowerCase() == 'seller';

  UserProfile copyWith({String? fullName, String? username}) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email,
      role: role,
      profilePicture: profilePicture,
      isVerified: isVerified,
      companyName: companyName,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      country: country,
      zipCode: zipCode,
      sellerType: sellerType,
      businessPhone1: businessPhone1,
      businessPhone2: businessPhone2,
      representativeName1: representativeName1,
      representativeName2: representativeName2,
      panCardNumber: panCardNumber,
      aadhaarNumber: aadhaarNumber,
      iecNumber: iecNumber,
      gstNumber: gstNumber,
      companyLogoUrl: companyLogoUrl,
      bannerImageUrl: bannerImageUrl,
      panCardUrl: panCardUrl,
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      bankName: bankName,
      accountType: accountType,
      upiId: upiId,
    );
  }
}
