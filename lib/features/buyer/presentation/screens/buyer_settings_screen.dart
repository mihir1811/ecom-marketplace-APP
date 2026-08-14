import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/buyer_layout.dart';

class BuyerSettingsScreen extends ConsumerWidget {
  const BuyerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BuyerLayout(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          Text(
            'Account',
            style: AppTypography.label.copyWith(
              color: AppColors.textMutedLight,
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
                onTap: () => context.go(AppRouteNames.buyerProfile),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline),
                title: const Text('Help center'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(AppRouteNames.buyerHelpCenter),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About GemWorld'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRouteNames.aboutUs),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Policies & Legal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRouteNames.policies),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRouteNames.termsAndConditions),
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
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRouteNames.home);
                },
              ),
            ],
          ),
        ],
      ),
    );
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
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warmBorder),
      ),
      child: Column(children: children),
    );
  }
}
