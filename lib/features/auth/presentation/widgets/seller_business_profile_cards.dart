import 'package:flutter/material.dart';

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
          title: 'Company',
          rows: [
            ProfileInfoRow(
              icon: Icons.storefront_outlined,
              label: 'Company name',
              value: profileDisplay(profile.companyName),
            ),
            ProfileInfoRow(
              icon: Icons.category_outlined,
              label: 'Seller type',
              value: profileDisplay(profile.sellerType),
            ),
            ProfileInfoRow(
              icon: Icons.image_outlined,
              label: 'Company logo',
              value: profile.companyLogoUrl == null ? 'Not provided' : 'On file',
            ),
            ProfileInfoRow(
              icon: Icons.panorama_outlined,
              label: 'Storefront banner',
              value:
                  profile.bannerImageUrl == null ? 'Not provided' : 'On file',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: 'Business address',
          rows: [
            ProfileInfoRow(
              icon: Icons.home_outlined,
              label: 'Address line 1',
              value: profileDisplay(profile.addressLine1),
            ),
            ProfileInfoRow(
              icon: Icons.home_work_outlined,
              label: 'Address line 2',
              value: profileDisplay(profile.addressLine2),
            ),
            ProfileInfoRow(
              icon: Icons.location_city_outlined,
              label: 'City',
              value: profileDisplay(profile.city),
            ),
            ProfileInfoRow(
              icon: Icons.map_outlined,
              label: 'State',
              value: profileDisplay(profile.state),
            ),
            ProfileInfoRow(
              icon: Icons.public_outlined,
              label: 'Country',
              value: profileDisplay(profile.country),
            ),
            ProfileInfoRow(
              icon: Icons.markunread_mailbox_outlined,
              label: 'ZIP / Postal code',
              value: profileDisplay(profile.zipCode),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: 'Business contacts',
          rows: [
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Business phone 1',
              value: profileDisplay(profile.businessPhone1),
            ),
            ProfileInfoRow(
              icon: Icons.phone_outlined,
              label: 'Business phone 2',
              value: profileDisplay(profile.businessPhone2),
            ),
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Representative 1',
              value: profileDisplay(profile.representativeName1),
            ),
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Representative 2',
              value: profileDisplay(profile.representativeName2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: 'Tax & KYC documents',
          rows: [
            ProfileInfoRow(
              icon: Icons.credit_card_outlined,
              label: 'PAN number',
              value: profileDisplay(profile.panCardNumber),
            ),
            ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: 'Aadhaar number',
              value: profileDisplay(profile.aadhaarNumber),
            ),
            ProfileInfoRow(
              icon: Icons.numbers_outlined,
              label: 'IEC number',
              value: profileDisplay(profile.iecNumber),
            ),
            ProfileInfoRow(
              icon: Icons.receipt_long_outlined,
              label: 'GST number',
              value: profileDisplay(profile.gstNumber),
            ),
            ProfileInfoRow(
              icon: Icons.upload_file_outlined,
              label: 'PAN card document',
              value: profile.panCardUrl == null ? 'Not provided' : 'On file',
            ),
          ],
        ),
      ],
    );
  }
}
