import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/account_commerce_messages.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_validators.dart';
import '../../../../core/auth/business_registration_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

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

/// Seller registration step titles (steps 2–5; step 1 is basic details).
abstract final class SellerRegistrationSteps {
  static const titles = <String>[
    AccountCommerceL10n.basicDetails,
    AccountCommerceL10n.companyDetails,
    AccountCommerceL10n.addressLine1,
    AccountCommerceL10n.contactsKyc,
    AccountCommerceL10n.bankAccount,
  ];

  static const count = 5;
}

class BusinessCompanyStep extends StatelessWidget {
  const BusinessCompanyStep({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final BusinessRegistrationFieldsController controller;
  final bool enabled;
  final VoidCallback onChanged;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    controller.companyLogo = file;
    onChanged();
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    controller.bannerImage = file;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.companyName,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.companyName),
            prefixIcon: const Icon(Icons.apartment_outlined),
          ),
          validator: _required(
            context.tr(AccountCommerceL10n.companyNameRequired),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        DropdownButtonFormField<SellerType>(
          key: ValueKey(controller.sellerType),
          initialValue: controller.sellerType,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.sellerType),
            prefixIcon: const Icon(Icons.category_outlined),
          ),
          items: [
            for (final type in SellerType.values)
              DropdownMenuItem(
                value: type,
                child: Text(context.tr(type.labelKey)),
              ),
          ],
          onChanged: enabled
              ? (value) {
                  if (value == null) return;
                  controller.sellerType = value;
                  onChanged();
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilePickButton(
          label:
              controller.companyLogo?.name ??
              context.tr(AccountCommerceL10n.uploadCompanyLogo),
          icon: Icons.add_photo_alternate_outlined,
          enabled: enabled,
          onPressed: _pickLogo,
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilePickButton(
          label:
              controller.bannerImage?.name ??
              context.tr(AccountCommerceL10n.uploadBanner),
          icon: Icons.image_outlined,
          enabled: enabled,
          onPressed: _pickBanner,
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
        TextFormField(
          controller: controller.addressLine1,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.addressLine1),
            prefixIcon: const Icon(Icons.home_outlined),
          ),
          validator: _required(
            context.tr(AccountCommerceL10n.address1Required),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.addressLine2,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.addressLine2),
            prefixIcon: const Icon(Icons.home_work_outlined),
          ),
          validator: _required(
            context.tr(AccountCommerceL10n.address2Required),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.city,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.city),
            prefixIcon: const Icon(Icons.location_city_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.cityRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.state,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.stateProvince),
            prefixIcon: const Icon(Icons.map_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.stateRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.country,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.country),
            prefixIcon: const Icon(Icons.public_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.countryRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.zipCode,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.postalCode),
            prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.postalRequired)),
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
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    controller.panCard = file;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.phone1,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.primaryPhone),
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.phone1Required)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.phone2,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.secondaryPhone),
            prefixIcon: const Icon(Icons.phone_android_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.phone2Required)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.representativeName1,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.representative1),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.rep1Required)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.representativeName2,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.representative2),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.rep2Required)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.panCardNumber,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.panNumber),
            prefixIcon: const Icon(Icons.credit_card_outlined),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return context.tr(AccountCommerceL10n.panRequired);
            if (!isValidPan(v)) return context.tr(AccountCommerceL10n.validPan);
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        _FilePickButton(
          label: controller.panCard?.name ?? 'Upload PAN card image (optional)',
          icon: Icons.upload_file_outlined,
          enabled: enabled,
          onPressed: _pickPan,
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.aadhaarNumber,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.aadhaarNumber),
            prefixIcon: const Icon(Icons.fingerprint),
          ),
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
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.iecNumber,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.iecNumber),
            prefixIcon: const Icon(Icons.receipt_long_outlined),
          ),
          validator: _required(context.tr(AccountCommerceL10n.iecRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.gstNumber,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.gstNumber),
            prefixIcon: const Icon(Icons.receipt_outlined),
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
        TextFormField(
          controller: controller.accountHolderName,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.accountHolderName),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: _required(context.tr(AccountCommerceL10n.holderRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.accountNumber,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.accountNumber),
            prefixIcon: const Icon(Icons.account_balance_outlined),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) {
              return context.tr(AccountCommerceL10n.accountNumberRequired);
            }
            if (!isValidBankAccountNumber(v)) {
              return 'Account number must be 8–20 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.ifscCode,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.ifscCode),
            prefixIcon: const Icon(Icons.qr_code_outlined),
          ),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (v.isEmpty) return context.tr(AccountCommerceL10n.ifscRequired);
            if (!isValidIfsc(v)) {
              return context.tr(AccountCommerceL10n.validIfsc);
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.bankName,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.bankName),
            prefixIcon: const Icon(Icons.account_balance),
          ),
          validator: _required(context.tr(AccountCommerceL10n.bankRequired)),
        ),
        const SizedBox(height: AppSpacing.s16),
        DropdownButtonFormField<BankAccountType>(
          key: ValueKey(controller.accountType),
          initialValue: controller.accountType,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.accountTypeOptional),
            prefixIcon: const Icon(Icons.savings_outlined),
          ),
          items: [
            for (final type in BankAccountType.values)
              DropdownMenuItem(
                value: type,
                child: Text(context.tr(type.labelKey)),
              ),
          ],
          onChanged: enabled
              ? (value) {
                  if (value == null) return;
                  controller.accountType = value;
                  onChanged();
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        TextFormField(
          controller: controller.upiId,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: context.tr(AccountCommerceL10n.upiOptional),
            prefixIcon: const Icon(Icons.alternate_email),
          ),
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

class _FilePickButton extends StatelessWidget {
  const _FilePickButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s16,
            horizontal: AppSpacing.s24,
          ),
          side: BorderSide(color: AppColors.border(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.r8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: AppSpacing.s12),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Compact step progress for seller registration.
class SellerRegistrationStepHeader extends StatelessWidget {
  const SellerRegistrationStepHeader({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final title = context.tr(SellerRegistrationSteps.titles[currentStep]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(AccountCommerceL10n.stepOf, {
            'current': currentStep + 1,
            'total': SellerRegistrationSteps.count,
          }),
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            for (var i = 0; i < SellerRegistrationSteps.count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= currentStep
                        ? AppColors.selectedFill(context)
                        : AppColors.border(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r4),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          title,
          style: AppTypography.headline.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
