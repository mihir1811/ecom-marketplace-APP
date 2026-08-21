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
import '../../../auth/presentation/widgets/seller_business_profile_cards.dart';
import '../../../../core/widgets/dark_theme_scope.dart';
import '../widgets/buyer_layout.dart';

/// Individual / buyer account profile (read-only).
class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider.select((s) => s.user));
    final profileAsync = ref.watch(userProfileProvider);

    return DarkThemeScope(
      child: BuyerLayout(
        title: 'My profile',
        child: authUser == null
            ? const Center(child: Text('Sign in to view your profile.'))
            : profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  final fallback = userProfileFromAuth(authUser);
                  return _BuyerProfileBody(
                    profile: fallback,
                    authUser: authUser,
                    onRetry: () => ref.invalidate(userProfileProvider),
                    loadError: e is Failure ? e.message : e.toString(),
                  );
                },
                data: (profile) =>
                    _BuyerProfileBody(profile: profile, authUser: authUser),
              ),
      ),
    );
  }
}

class _BuyerProfileBody extends StatelessWidget {
  const _BuyerProfileBody({
    required this.profile,
    required this.authUser,
    this.onRetry,
    this.loadError,
  });

  final UserProfile profile;
  final AuthUser authUser;
  final VoidCallback? onRetry;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        _ProfileHero(user: authUser, profile: profile),
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
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        ProfileInfoCard(
          title: 'Account status',
          rows: [
            ProfileInfoRow(
              icon: Icons.person_outline,
              label: 'Account type',
              value: profile.isSeller
                  ? 'Seller (business)'
                  : 'Individual (buying only)',
            ),
            ProfileInfoRow(
              icon: Icons.verified_outlined,
              label: 'Account verification',
              value: profile.isVerified
                  ? 'Verified'
                  : 'Verification is pending',
            ),
            ProfileInfoRow(
              icon: Icons.security_outlined,
              label: 'Role',
              value: profileDisplay(profile.role),
            ),
          ],
        ),
        if (profile.isSeller) ...[
          const SizedBox(height: AppSpacing.s16),
          SellerBusinessProfileCards(profile: profile),
        ],
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.profile});

  final AuthUser user;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final picture = profile.profilePicture.trim().isNotEmpty
        ? profile.profilePicture.trim()
        : user.profilePicture.trim();
    final hasPicture = picture.isNotEmpty;
    final displayName = profile.fullName.trim().isNotEmpty
        ? profile.fullName
        : (profile.username.trim().isNotEmpty
              ? profile.username
              : 'Your account');

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
            radius: 36,
            backgroundColor: AppColors.selectedFill(context),
            backgroundImage: hasPicture
                ? CachedNetworkImageProvider(picture)
                : null,
            child: hasPicture
                ? null
                : Text(
                    _initials(displayName),
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSelected(context),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                if (profile.email.trim().isNotEmpty)
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                  child: Text(
                    profile.isSeller ? 'Seller' : 'Individual',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
