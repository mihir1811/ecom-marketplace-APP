import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/auth/confirm_delete_account.dart';
import '../../../../core/auth/confirm_sign_out.dart';
import '../../../../core/router/app_navigation.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_preference_provider.dart';
import '../widgets/buyer_layout.dart';

class BuyerSettingsScreen extends ConsumerWidget {
  const BuyerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(themePreferenceProvider);
    return BuyerLayout(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          Text(
            'Appearance',
            style: AppTypography.label.copyWith(
              color: AppColors.textMuted(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          _Card(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark theme'),
                subtitle: Text(
                  'Enables dark mode across the app.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                value: darkMode,
                onChanged: (v) => ref
                    .read(themePreferenceProvider.notifier)
                    .setDarkMode(v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Account',
            style: AppTypography.label.copyWith(
              color: AppColors.textMuted(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          _Card(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: const Text('My profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.openRoute(AppRouteNames.buyerProfile),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline),
                title: const Text('Help center'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.openRoute(AppRouteNames.buyerHelpCenter),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About GemWorld'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.openRoute(AppRouteNames.aboutUs),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Policies & Legal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.openRoute(AppRouteNames.policies),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.openRoute(AppRouteNames.termsAndConditions),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Sign out',
                  style: AppTypography.label.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  final confirmed = await confirmSignOut(context);
                  if (!confirmed || !context.mounted) return;
                  ref.read(authProvider.notifier).logout();
                  context.resetTo(AppRouteNames.home);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.error,
                ),
                title: Text(
                  'Delete account',
                  style: AppTypography.label.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Schedules deletion with a 7-day recovery window.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                ),
                onTap: () => _onDeleteAccount(context, ref),
              ),
            ],
          ),
        ],
      ),
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
      final message = ref.read(authProvider).errorMessage ??
          'Could not delete account. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final deletion = ref.read(authProvider);
    final until = deletion.accountDeletionRecoverUntil;
    final base = deletion.accountDeletionMessage ??
        'Your account is scheduled for deletion.';
    final detail =
        until == null ? base : '$base Recover by ${until.toLocal()}.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(detail)),
    );
    context.resetTo(AppRouteNames.recoverAccount);
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(children: children),
    );
  }
}
