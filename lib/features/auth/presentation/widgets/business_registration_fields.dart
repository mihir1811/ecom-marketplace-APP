import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_validators.dart';
import '../../../../core/auth/business_registration_data.dart';
import '../../../../core/l10n/app_localizations.dart';
import 'kit/auth_kit.dart';

/// Owns business-registration form controllers and picked files.
class BusinessRegistrationFieldsController {
  final companyName = TextEditingController();
  final addressLine1 = TextEditingController();
  final addressLine2 = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final country = TextEditingController();
  final zipCode = TextEditingController();
  final phone1 = TextEditingController();
  final phone2 = TextEditingController();
  final representativeName1 = TextEditingController();
  final representativeName2 = TextEditingController();
  final panCardNumber = TextEditingController();
  final aadhaarNumber = TextEditingController();
  final iecNumber = TextEditingController();
  final gstNumber = TextEditingController();
  final upiId = TextEditingController();
  final accountHolderName = TextEditingController();
  final accountNumber = TextEditingController();
  final ifscCode = TextEditingController();
  final bankName = TextEditingController();

  SellerType sellerType = SellerType.naturalDiamond;
  BankAccountType accountType = BankAccountType.savings;
  XFile? companyLogo;
  XFile? bannerImage;
  XFile? panCard;

  void dispose() {
    companyName.dispose();
    addressLine1.dispose();
    addressLine2.dispose();
    city.dispose();
    state.dispose();
    country.dispose();
    zipCode.dispose();
    phone1.dispose();
    phone2.dispose();
    representativeName1.dispose();
    representativeName2.dispose();
    panCardNumber.dispose();
    aadhaarNumber.dispose();
    iecNumber.dispose();
    gstNumber.dispose();
    upiId.dispose();
    accountHolderName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
    bankName.dispose();
  }

  void clear() {
    companyName.clear();
    addressLine1.clear();
    addressLine2.clear();
    city.clear();
    state.clear();
    country.clear();
    zipCode.clear();
    phone1.clear();
    phone2.clear();
    representativeName1.clear();
    representativeName2.clear();
    panCardNumber.clear();
    aadhaarNumber.clear();
    iecNumber.clear();
    gstNumber.clear();
    upiId.clear();
    accountHolderName.clear();
    accountNumber.clear();
    ifscCode.clear();
    bankName.clear();

    sellerType = SellerType.naturalDiamond;
    accountType = BankAccountType.savings;
    companyLogo = null;
    bannerImage = null;
    panCard = null;
  }

  /// Builds API payload when required company logo is present; otherwise `null`.
  BusinessRegistrationData? toData() {
    final logo = companyLogo;
    if (logo == null) return null;
    return BusinessRegistrationData(
      companyName: companyName.text.trim(),
      addressLine1: addressLine1.text.trim(),
      addressLine2: addressLine2.text.trim(),
      city: city.text.trim(),
      state: state.text.trim(),
      country: country.text.trim(),
      zipCode: zipCode.text.trim(),
      sellerType: sellerType,
      phone1: phone1.text.trim(),
      phone2: phone2.text.trim(),
      representativeName1: representativeName1.text.trim(),
      representativeName2: representativeName2.text.trim(),
      panCardNumber: panCardNumber.text.trim().toUpperCase(),
      aadhaarNumber: aadhaarNumber.text.trim(),
      iecNumber: iecNumber.text.trim(),
      accountHolderName: accountHolderName.text.trim(),
      accountNumber: accountNumber.text.trim(),
      ifscCode: ifscCode.text.trim().toUpperCase(),
      bankName: bankName.text.trim(),
      accountType: accountType,
      companyLogo: logo,
      bannerImage: bannerImage,
      panCard: panCard,
      gstNumber: gstNumber.text.trim().isEmpty ? null : gstNumber.text.trim(),
      upiId: upiId.text.trim().isEmpty ? null : upiId.text.trim(),
    );
  }

  String? missingCompanyLogoMessage() {
    if (companyLogo == null) {
      return AccountCommerceL10n.english(
        AccountCommerceL10n.companyLogoRequired,
      );
    }
    return null;
  }

  String? missingFilesMessage() => missingCompanyLogoMessage();
}

/// Seller registration steps (step 1 is basic details).
abstract final class SellerRegistrationSteps {
  static const titles = <String>[
    AccountCommerceL10n.basicDetails,
    AccountCommerceL10n.companyDetails,
    AuthL10n.stepAddress,
    AccountCommerceL10n.contactsKyc,
    AccountCommerceL10n.bankAccount,
  ];

  static const hints = <String>[
    AuthL10n.stepHintBasic,
    AuthL10n.stepHintCompany,
    AuthL10n.stepHintAddress,
    AuthL10n.stepHintKyc,
    AuthL10n.stepHintBank,
  ];

  static const count = 5;
}

const _gap = SizedBox(height: AuthSpace.s12);
const _sectionGap = SizedBox(height: AuthSpace.s24);

/// Two fields side by side on roomy widths, stacked on narrow ones.
class _Pair extends StatelessWidget {
  const _Pair(this.first, this.second);

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 340) {
          return Column(children: [first, _gap, second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: AuthSpace.s12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _FieldCaption extends StatelessWidget {
  const _FieldCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AuthPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AuthSpace.s4, bottom: AuthSpace.s8),
      child: Text(text, style: AuthType.caption(p).copyWith(color: p.inkSoft)),
    );
  }
}

class BusinessCompanyStep extends StatelessWidget {
  const BusinessCompanyStep({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.logoError = false,
  });

  final BusinessRegistrationFieldsController controller;
  final bool enabled;
  final VoidCallback onChanged;

  /// Highlights the logo tile after a failed attempt to continue.
  final bool logoError;

  Future<void> _pickLogo() async {
    final file = await pickAuthImage();
    if (file == null) return;
    controller.companyLogo = file;
    onChanged();
  }

  Future<void> _pickBanner() async {
    final file = await pickAuthImage();
    if (file == null) return;
    controller.bannerImage = file;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: controller.companyName,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.companyName),
          icon: Icons.apartment_outlined,
          autofillHints: const [AutofillHints.organizationName],
          validator: _required(
            context.tr(AccountCommerceL10n.companyNameRequired),
          ),
        ),
        _sectionGap,
        _FieldCaption(context.tr(AccountCommerceL10n.sellerType)),
        AuthChoiceChips<SellerType>(
          value: controller.sellerType,
          enabled: enabled,
          options: [
            for (final type in SellerType.values)
              AuthSegment(value: type, label: context.tr(type.labelKey)),
          ],
          onChanged: (value) {
            controller.sellerType = value;
            onChanged();
          },
        ),
        _sectionGap,
        AuthUploadTile(
          title: context.tr(AuthL10n.companyLogo),
          hint: context.tr(AuthL10n.companyLogoHint),
          file: controller.companyLogo,
          required: true,
          error: logoError && controller.companyLogo == null,
          enabled: enabled,
          onPick: _pickLogo,
        ),
        _gap,
        AuthUploadTile(
          title: context.tr(AuthL10n.bannerImage),
          hint: context.tr(AuthL10n.bannerImageHint),
          file: controller.bannerImage,
          icon: Icons.panorama_outlined,
          enabled: enabled,
          onPick: _pickBanner,
        ),
      ],
    );
  }
}

class BusinessAddressStep extends StatelessWidget {
  const BusinessAddressStep({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final BusinessRegistrationFieldsController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: controller.addressLine1,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.addressLine1),
          icon: Icons.home_outlined,
          autofillHints: const [AutofillHints.streetAddressLine1],
          validator: _required(
            context.tr(AccountCommerceL10n.address1Required),
          ),
        ),
        _gap,
        AuthTextField(
          controller: controller.addressLine2,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.addressLine2),
          icon: Icons.home_work_outlined,
          autofillHints: const [AutofillHints.streetAddressLine2],
          validator: _required(
            context.tr(AccountCommerceL10n.address2Required),
          ),
        ),
        _gap,
        _Pair(
          AuthTextField(
            controller: controller.city,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.city),
            autofillHints: const [AutofillHints.addressCity],
            validator: _required(context.tr(AccountCommerceL10n.cityRequired)),
          ),
          AuthTextField(
            controller: controller.state,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.stateProvince),
            autofillHints: const [AutofillHints.addressState],
            validator: _required(context.tr(AccountCommerceL10n.stateRequired)),
          ),
        ),
        _gap,
        _Pair(
          AuthTextField(
            controller: controller.country,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.country),
            autofillHints: const [AutofillHints.countryName],
            validator: _required(
              context.tr(AccountCommerceL10n.countryRequired),
            ),
          ),
          AuthTextField(
            controller: controller.zipCode,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.postalCode),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.postalCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _required(
              context.tr(AccountCommerceL10n.postalRequired),
            ),
          ),
        ),
      ],
    );
  }
}

class BusinessContactsKycStep extends StatelessWidget {
  const BusinessContactsKycStep({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final BusinessRegistrationFieldsController controller;
  final bool enabled;
  final VoidCallback onChanged;

  Future<void> _pickPan() async {
    final file = await pickAuthImage();
    if (file == null) return;
    controller.panCard = file;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    String? phone(String? value, String requiredKey) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return context.tr(requiredKey);
      if (!isValidIndianPhone(v)) {
        return context.tr(AccountCommerceL10n.validPhone);
      }
      return null;
    }

    final phoneFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthSectionLabel(context.tr(AuthL10n.sectionContacts)),
        _Pair(
          AuthTextField(
            controller: controller.phone1,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.primaryPhone),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: phoneFormatters,
            validator: (v) => phone(v, AccountCommerceL10n.phone1Required),
          ),
          AuthTextField(
            controller: controller.phone2,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.secondaryPhone),
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: phoneFormatters,
            validator: (v) => phone(v, AccountCommerceL10n.phone2Required),
          ),
        ),
        _gap,
        AuthTextField(
          controller: controller.representativeName1,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.representative1),
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          validator: _required(context.tr(AccountCommerceL10n.rep1Required)),
        ),
        _gap,
        AuthTextField(
          controller: controller.representativeName2,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.representative2),
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.words,
          validator: _required(context.tr(AccountCommerceL10n.rep2Required)),
        ),
        _sectionGap,
        AuthSectionLabel(context.tr(AuthL10n.sectionIdentity)),
        _PanCardNumberField(
          controller: controller.panCardNumber,
          enabled: enabled,
        ),
        _gap,
        AuthUploadTile(
          title: context.tr(AuthL10n.panCardImage),
          hint: context.tr(AuthL10n.panCardImageHint),
          file: controller.panCard,
          icon: Icons.upload_file_outlined,
          enabled: enabled,
          onPick: _pickPan,
        ),
        _gap,
        AuthTextField(
          controller: controller.aadhaarNumber,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.aadhaarNumber),
          icon: Icons.fingerprint,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return context.tr(AccountCommerceL10n.aadhaarRequired);
            }
            if (!isValidAadhaar(v)) {
              return context.tr(AccountCommerceL10n.validAadhaar);
            }
            return null;
          },
        ),
        _gap,
        _Pair(
          AuthTextField(
            controller: controller.iecNumber,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.iecNumber),
            validator: _required(context.tr(AccountCommerceL10n.iecRequired)),
          ),
          AuthTextField(
            controller: controller.gstNumber,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.gstNumber),
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
          ),
        ),
      ],
    );
  }
}

class BusinessBankStep extends StatelessWidget {
  const BusinessBankStep({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final BusinessRegistrationFieldsController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthSectionLabel(context.tr(AuthL10n.sectionPayouts)),
        AuthTextField(
          controller: controller.accountHolderName,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.accountHolderName),
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          validator: _required(context.tr(AccountCommerceL10n.holderRequired)),
        ),
        _gap,
        AuthTextField(
          controller: controller.accountNumber,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.accountNumber),
          icon: Icons.account_balance_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(20),
          ],
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return context.tr(AccountCommerceL10n.accountNumberRequired);
            }
            if (!isValidBankAccountNumber(v)) {
              return context.tr(AuthL10n.accountNumberDigits);
            }
            return null;
          },
        ),
        _gap,
        _Pair(
          AuthTextField(
            controller: controller.ifscCode,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.ifscCode),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) {
                return context.tr(AccountCommerceL10n.ifscRequired);
              }
              if (!isValidIfsc(v)) {
                return context.tr(AccountCommerceL10n.validIfsc);
              }
              return null;
            },
          ),
          AuthTextField(
            controller: controller.bankName,
            enabled: enabled,
            label: context.tr(AccountCommerceL10n.bankName),
            validator: _required(context.tr(AccountCommerceL10n.bankRequired)),
          ),
        ),
        _sectionGap,
        _FieldCaption(context.tr(AccountCommerceL10n.accountTypeOptional)),
        AuthSegmented<BankAccountType>(
          value: controller.accountType,
          enabled: enabled,
          segments: [
            for (final type in BankAccountType.values)
              AuthSegment(value: type, label: context.tr(type.labelKey)),
          ],
          onChanged: (value) {
            controller.accountType = value;
            onChanged();
          },
        ),
        _gap,
        AuthTextField(
          controller: controller.upiId,
          enabled: enabled,
          label: context.tr(AccountCommerceL10n.upiOptional),
          icon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

FormFieldValidator<String> _required(String message) {
  return (value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return message;
    return null;
  };
}

/// PAN format AAAAA9999A — switches keyboard: letters → digits → letter.
TextInputType _panKeyboardTypeForLength(int length) {
  if (length < 5) return TextInputType.text;
  if (length < 9) return TextInputType.number;
  return TextInputType.text;
}

class _PanCardNumberField extends StatefulWidget {
  const _PanCardNumberField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  State<_PanCardNumberField> createState() => _PanCardNumberFieldState();
}

class _PanCardNumberFieldState extends State<_PanCardNumberField> {
  final _focusNode = FocusNode();
  late TextInputType _keyboardType;

  @override
  void initState() {
    super.initState();
    _keyboardType = _panKeyboardTypeForLength(widget.controller.text.length);
    widget.controller.addListener(_syncKeyboardType);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncKeyboardType);
    _focusNode.dispose();
    super.dispose();
  }

  void _syncKeyboardType() {
    final next = _panKeyboardTypeForLength(widget.controller.text.length);
    if (next == _keyboardType) return;
    setState(() => _keyboardType = next);
    if (!_focusNode.hasFocus) return;
    // Rebuild + refocus so the soft keyboard actually switches type.
    _focusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthTextField(
      key: ValueKey(_keyboardType),
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: _keyboardType,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        const _PanCardInputFormatter(),
        LengthLimitingTextInputFormatter(10),
      ],
      label: context.tr(AccountCommerceL10n.panNumber),
      icon: Icons.credit_card_outlined,
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return context.tr(AccountCommerceL10n.panRequired);
        if (!isValidPan(v)) return context.tr(AccountCommerceL10n.validPan);
        return null;
      },
    );
  }
}

/// Enforces PAN shape AAAAA9999A and forces uppercase letters.
class _PanCardInputFormatter extends TextInputFormatter {
  const _PanCardInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length && buffer.length < 10; i++) {
      final char = raw[i];
      final index = buffer.length;
      final isLetterSlot = index < 5 || index == 9;
      if (isLetterSlot) {
        if (RegExp(r'[A-Z]').hasMatch(char)) buffer.write(char);
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
