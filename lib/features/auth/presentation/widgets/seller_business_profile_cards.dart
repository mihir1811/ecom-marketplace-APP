import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/user_profile.dart';
import 'profile_info_widgets.dart';

/// Owner-only company / KYC fields from registration (not public storefront).
class SellerBusinessProfileCards extends StatelessWidget {
  const SellerBusinessProfileCards({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileInfoCard(
          title: context.tr(AccountCommerceL10n.company),
          rows: [
            ProfileInfoRow(
              icon: Icons.storefront_outlined,
              label: context.tr(AccountCommerceL10n.companyName),
              value: profileDisplay(context, profile.companyName),
            ),
            ProfileInfoRow(
              icon: Icons.category_outlined,
              label: context.tr(AccountCommerceL10n.sellerType),
              value: profileDisplay(context, profile.sellerType),
            ),
            ProfileInfoRow(
              icon: Icons.image_outlined,
              label: 'Company logo',
              value: profile.companyLogoUrl == null
                  ? context.tr(AccountCommerceL10n.notProvided)
                  : context.tr(AccountCommerceL10n.onFile),
            ),
            ProfileInfoRow(
              icon: Icons.panorama_outlined,
              label: 'Storefront banner',
              value: profile.bannerImageUrl == null
                  ? context.tr(AccountCommerceL10n.notProvided)
                  : context.tr(AccountCommerceL10n.onFile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: context.tr(AccountCommerceL10n.businessAddress),
          rows: [
            ProfileInfoRow(
              icon: Icons.home_outlined,
              label: context.tr(AccountCommerceL10n.addressLine1),
              value: profileDisplay(context, profile.addressLine1),
            ),
            ProfileInfoRow(
              icon: Icons.home_work_outlined,
              label: context.tr(AccountCommerceL10n.addressLine2),
              value: profileDisplay(context, profile.addressLine2),
            ),
            ProfileInfoRow(
              icon: Icons.location_city_outlined,
              label: context.tr(AccountCommerceL10n.city),
              value: profileDisplay(context, profile.city),
            ),
            ProfileInfoRow(
              icon: Icons.map_outlined,
              label: context.tr(AccountCommerceL10n.state),
              value: profileDisplay(context, profile.state),
            ),
            ProfileInfoRow(
              icon: Icons.public_outlined,
              label: context.tr(AccountCommerceL10n.country),
              value: profileDisplay(context, profile.country),
            ),
            ProfileInfoRow(
              icon: Icons.markunread_mailbox_outlined,
              label: context.tr(AccountCommerceL10n.postalCodeCaps),
              value: profileDisplay(context, profile.zipCode),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: context.tr(AccountCommerceL10n.businessContacts),
          rows: [
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone 1',
              value: profileDisplay(context, profile.businessPhone1),
            ),
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone 2',
              value: profileDisplay(context, profile.businessPhone2),
            ),
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Rep 1',
              value: profileDisplay(context, profile.representativeName1),
            ),
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Rep 2',
              value: profileDisplay(context, profile.representativeName2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: context.tr(AccountCommerceL10n.taxKyc),
          rows: [
            ProfileInfoRow(
              icon: Icons.credit_card_outlined,
              label: 'PAN',
              value: profileDisplay(context, profile.panCardNumber),
            ),
            ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: 'Aadhaar',
              value: profileDisplay(context, profile.aadhaarNumber),
            ),
            ProfileInfoRow(
              icon: Icons.numbers_outlined,
              label: 'IEC',
              value: profileDisplay(context, profile.iecNumber),
            ),
            ProfileInfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'GST',
              value: profileDisplay(context, profile.gstNumber),
            ),
            ProfileInfoRow(
              icon: Icons.upload_file_outlined,
              label: 'PAN doc',
              value: profile.panCardUrl == null
                  ? context.tr(AccountCommerceL10n.notProvided)
                  : context.tr(AccountCommerceL10n.onFile),
            ),
          ],
        ),
      ],
    );
  }
}
