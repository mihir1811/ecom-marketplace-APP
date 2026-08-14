import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_user.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/application/user_profile_providers.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/widgets/profile_info_widgets.dart';
import '../../../user_bank_account/application/user_bank_account_providers.dart';
import '../../../user_bank_account/domain/models/user_bank_account.dart';
import '../widgets/seller_layout.dart';

/// Seller account profile (read-only).
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider.select((s) => s.user));
    final profileAsync = ref.watch(userProfileProvider);
    final bankState = ref.watch(userBankAccountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => openSellerDrawer(context),
                icon: const Icon(Icons.menu),
              ),
              Text(
                'Profile',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: authUser == null
              ? const Center(child: Text('Sign in to view your profile.'))
              : profileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) {
                    final fallback = userProfileFromAuth(authUser);
                    return _SellerProfileBody(
                      profile: fallback,
                      authUser: authUser,
                      bankState: bankState,
                      onRetry: () => ref.invalidate(userProfileProvider),
                      loadError: e is Failure ? e.message : e.toString(),
                    );
                  },
                  data: (profile) => _SellerProfileBody(
                    profile: profile,
                    authUser: authUser,
                    bankState: bankState,
                  ),
                ),
        ),
      ],
    );
  }
}

class _SellerProfileBody extends StatelessWidget {
  const _SellerProfileBody({
    required this.profile,
    required this.authUser,
    required this.bankState,
    this.onRetry,
    this.loadError,
  });

  final UserProfile profile;
  final AuthUser authUser;
  final UserBankAccountState bankState;
  final VoidCallback? onRetry;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    final UserBankAccount? bank = bankState.account;
    final accountHolder =
        bank?.accountHolderName ?? profile.accountHolderName;
    final accountNumber = bank?.accountNumber ?? profile.accountNumber;
    final ifsc = bank?.ifscCode ?? profile.ifscCode;
    final bankName = bank?.bankName ?? profile.bankName;
    final upi = bank?.upiId ?? profile.upiId;
    final accountType =
        bank?.accountType?.label ?? profile.accountType;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        _SellerHero(user: authUser, profile: profile),
        if (loadError != null) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Showing signed-in account details. Full profile could not load: '
            '$loadError',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: 'Personal details',
          rows: [
            ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: 'Full name',
              value: profileDisplay(profile.fullName),
            ),
            ProfileInfoRow(
              icon: Icons.alternate_email,
              label: 'Username',
              value: profileDisplay(profile.username),
            ),
            ProfileInfoRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: profileDisplay(profile.email),
            ),
            ProfileInfoRow(
              icon: Icons.verified_outlined,
              label: 'Verification',
              value: profile.isVerified ? 'Verified' : 'Pending verification',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
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
              value: profile.companyLogoUrl == null
                  ? 'Not provided'
                  : 'On file',
            ),
            ProfileInfoRow(
              icon: Icons.panorama_outlined,
              label: 'Storefront banner',
              value: profile.bannerImageUrl == null
                  ? 'Not provided'
                  : 'On file',
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
        const SizedBox(height: AppSpacing.s16),
        if (bankState.isLoading)
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(AppSpacing.r12),
              border: Border.all(color: AppColors.warmBorder),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          ProfileInfoCard(
            title: 'Bank details',
            rows: [
              ProfileInfoRow(
                icon: Icons.account_circle_outlined,
                label: 'Account holder',
                value: profileDisplay(accountHolder),
              ),
              ProfileInfoRow(
                icon: Icons.account_balance_outlined,
                label: 'Account number',
                value: profileDisplay(accountNumber),
              ),
              ProfileInfoRow(
                icon: Icons.qr_code_outlined,
                label: 'IFSC code',
                value: profileDisplay(ifsc),
              ),
              ProfileInfoRow(
                icon: Icons.account_balance,
                label: 'Bank name',
                value: profileDisplay(bankName),
              ),
              ProfileInfoRow(
                icon: Icons.savings_outlined,
                label: 'Account type',
                value: profileDisplay(accountType),
              ),
              ProfileInfoRow(
                icon: Icons.payment_outlined,
                label: 'UPI ID',
                value: profileDisplay(upi),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Profile details are read-only. Contact support if you need '
          'corrections.',
          style: AppTypography.caption.copyWith(
            color: AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }
}

class _SellerHero extends StatelessWidget {
  const _SellerHero({required this.user, required this.profile});

  final AuthUser user;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final picture = profile.profilePicture.trim().isNotEmpty
        ? profile.profilePicture.trim()
        : user.profilePicture.trim();
    final hasPicture = picture.isNotEmpty;
    final name = profile.fullName.trim().isNotEmpty
        ? profile.fullName
        : (profile.username.trim().isNotEmpty ? profile.username : 'Seller');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.sandSurface,
            backgroundImage:
                hasPicture ? CachedNetworkImageProvider(picture) : null,
            child: hasPicture
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email.trim().isEmpty
                      ? '@${profile.username}'
                      : profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  profile.isVerified
                      ? 'Verified seller account'
                      : 'Seller account · pending verification',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
