import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_user.dart';
import '../../../../core/auth/confirm_delete_account.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/application/user_profile_providers.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/widgets/profile_info_widgets.dart';
import '../../../auth/presentation/widgets/seller_business_profile_cards.dart';
import '../../../user_bank_account/application/user_bank_account_providers.dart';
import '../../../user_bank_account/domain/models/user_bank_account.dart';

import '../../../../core/l10n/app_localizations.dart';

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
        Expanded(
          child: authUser == null
              ? Center(
                  child: Text(
                    context.tr(RemainingL10n.signInToViewYourProfile),
                  ),
                )
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
                      onDeleteAccount: () => _onDeleteAccount(context, ref),
                    );
                  },
                  data: (profile) => _SellerProfileBody(
                    profile: profile,
                    authUser: authUser,
                    bankState: bankState,
                    onDeleteAccount: () => _onDeleteAccount(context, ref),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _onDeleteAccount(BuildContext context, WidgetRef ref) async {
    final password = await confirmDeleteAccount(context);
    if (password == null || !context.mounted) return;

    final ok = await ref
        .read(authProvider.notifier)
        .requestAccountDeletion(password: password);
    if (!context.mounted) return;

    if (!ok) {
      final message =
          ref.read(authProvider).errorMessage ??
          'Could not delete account. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final deletion = ref.read(authProvider);
    final until = deletion.accountDeletionRecoverUntil;
    final base =
        deletion.accountDeletionMessage ??
        'Your account is scheduled for deletion.';
    final detail = until == null
        ? base
        : '$base Recover by ${until.toLocal()}.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(detail)));
    context.resetTo(AppRouteNames.recoverAccount);
  }
}

class _SellerProfileBody extends StatelessWidget {
  const _SellerProfileBody({
    required this.profile,
    required this.authUser,
    required this.bankState,
    this.onRetry,
    this.loadError,
    this.onDeleteAccount,
  });

  final UserProfile profile;
  final AuthUser authUser;
  final UserBankAccountState bankState;
  final VoidCallback? onRetry;
  final String? loadError;
  final VoidCallback? onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final UserBankAccount? bank = bankState.account;
    final accountHolder = bank?.accountHolderName ?? profile.accountHolderName;
    final accountNumber = bank?.accountNumber ?? profile.accountNumber;
    final ifsc = bank?.ifscCode ?? profile.ifscCode;
    final bankName = bank?.bankName ?? profile.bankName;
    final upi = bank?.upiId ?? profile.upiId;
    final accountType = bank?.accountType?.label ?? profile.accountType;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        _SellerHero(user: authUser, profile: profile),
        if (loadError != null) ...[
          const SizedBox(height: AppSpacing.s12),
          Text(
            '${context.tr(RemainingL10n.showingSignedInAccountDetailsFullProfile)}$loadError',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr(RemainingL10n.retry)),
            ),
        ],
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: context.tr(RemainingL10n.personalDetails),
          rows: [
            ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: context.tr(RemainingL10n.fullName),
              value: profileDisplay(context, profile.fullName),
            ),
            ProfileInfoRow(
              icon: Icons.alternate_email,
              label: context.tr(RemainingL10n.username),
              value: profileDisplay(context, profile.username),
            ),
            ProfileInfoRow(
              icon: Icons.mail_outline,
              label: context.tr(RemainingL10n.email),
              value: profileDisplay(context, profile.email),
            ),
            ProfileInfoRow(
              icon: Icons.verified_outlined,
              label: context.tr(RemainingL10n.verification),
              value: profile.isVerified
                  ? 'Verified'
                  : 'Verification is pending',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        SellerBusinessProfileCards(profile: profile),
        const SizedBox(height: AppSpacing.s16),
        if (bankState.isLoading)
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSpacing.r12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          ProfileInfoCard(
            title: context.tr(RemainingL10n.bankDetails),
            rows: [
              ProfileInfoRow(
                icon: Icons.account_circle_outlined,
                label: context.tr(RemainingL10n.accountHolder),
                value: profileDisplay(context, accountHolder),
              ),
              ProfileInfoRow(
                icon: Icons.account_balance_outlined,
                label: context.tr(RemainingL10n.accountNumber),
                value: profileDisplay(context, accountNumber),
              ),
              ProfileInfoRow(
                icon: Icons.qr_code_outlined,
                label: context.tr(RemainingL10n.ifscCode),
                value: profileDisplay(context, ifsc),
              ),
              ProfileInfoRow(
                icon: Icons.account_balance,
                label: context.tr(RemainingL10n.bankName),
                value: profileDisplay(context, bankName),
              ),
              ProfileInfoRow(
                icon: Icons.savings_outlined,
                label: context.tr(RemainingL10n.accountType),
                value: profileDisplay(context, accountType),
              ),
              ProfileInfoRow(
                icon: Icons.payment_outlined,
                label: context.tr(RemainingL10n.upiId),
                value: profileDisplay(context, upi),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          context.tr(RemainingL10n.profileDetailsAreReadOnlyContact),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted(context),
          ),
        ),
        if (onDeleteAccount != null) ...[
          const SizedBox(height: AppSpacing.s24),
          OutlinedButton.icon(
            onPressed: onDeleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.s16,
                horizontal: AppSpacing.s16,
              ),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(context.tr(RemainingL10n.deleteAccount)),
          ),
        ],
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
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.selectedFill(context),
            backgroundImage: hasPicture
                ? CachedNetworkImageProvider(picture)
                : null,
            child: hasPicture
                ? null
                : Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSelected(context),
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
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  profile.isVerified
                      ? 'Verified seller account'
                      : 'Verification is pending',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
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
