import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/auth_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/buyer_layout.dart';

/// Individual / buyer account profile — shows logged-in basic account info.
class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider.select((s) => s.user));

    return BuyerLayout(
      title: 'My profile',
      child: user == null
          ? const Center(child: Text('Sign in to view your profile.'))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                _ProfileHero(user: user),
                const SizedBox(height: AppSpacing.s16),
                _InfoCard(
                  title: 'Account details',
                  rows: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Full name',
                      value: _display(user.fullName),
                    ),
                    _InfoRow(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: _display(user.username),
                    ),
                    _InfoRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: _display(user.email),
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _display(user.phone),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                _InfoCard(
                  title: 'Account status',
                  rows: [
                     _InfoRow(
                       icon: Icons.person_outline,
                       label: 'Account type',
                       value: user.isSeller
                           ? 'Seller (business)'
                           : 'Individual (buying only)',
                     ),
                    _InfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Email verification',
                      value: user.isVerified ? 'Verified' : 'Not verified',
                    ),
                    _InfoRow(
                      icon: Icons.security_outlined,
                      label: 'Role',
                      value: _display(user.role),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  static String _display(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? 'Not provided' : v;
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final picture = user.profilePicture.trim();
    final hasPicture = picture.isNotEmpty;

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
            radius: 36,
            backgroundColor: AppColors.sandSurface,
            backgroundImage: hasPicture
                ? CachedNetworkImageProvider(picture)
                : null,
            child: hasPicture
                ? null
                : Text(
                    _initials(user.fullName.isNotEmpty
                        ? user.fullName
                        : user.username),
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.trim().isEmpty
                      ? (user.username.trim().isEmpty
                          ? 'Your account'
                          : user.username)
                      : user.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                if (user.email.trim().isNotEmpty)
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                const SizedBox(height: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sandSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.r8),
                  ),
                  child: Text(
                    user.isSeller ? 'Seller' : 'Individual',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.s12),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: AppColors.sandSurface,
              borderRadius: BorderRadius.circular(AppSpacing.r8),
            ),
            child: Text(
              title,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMutedLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
