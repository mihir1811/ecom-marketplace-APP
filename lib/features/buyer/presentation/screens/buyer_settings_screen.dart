import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/buyer_layout.dart';

class BuyerSettingsScreen extends ConsumerStatefulWidget {
  const BuyerSettingsScreen({super.key});

  @override
  ConsumerState<BuyerSettingsScreen> createState() =>
      _BuyerSettingsScreenState();
}

class _BuyerSettingsScreenState extends ConsumerState<BuyerSettingsScreen> {
  bool _orderAlerts = true;
  bool _messageAlerts = true;
  bool _marketingEmails = false;

  @override
  Widget build(BuildContext context) {
    return BuyerLayout(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          Text(
            'Notifications',
            style: AppTypography.label.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          _Card(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Order updates'),
                subtitle: const Text('Tracking and delivery alerts'),
                value: _orderAlerts,
                activeThumbColor: AppColors.warmWhite,
                activeTrackColor: AppColors.charcoal,
                onChanged: (v) => setState(() => _orderAlerts = v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Messages'),
                subtitle: const Text('Seller replies and chat'),
                value: _messageAlerts,
                activeThumbColor: AppColors.warmWhite,
                activeTrackColor: AppColors.charcoal,
                onChanged: (v) => setState(() => _messageAlerts = v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marketing emails'),
                subtitle: const Text('Promotions and marketplace news'),
                value: _marketingEmails,
                activeThumbColor: AppColors.warmWhite,
                activeTrackColor: AppColors.charcoal,
                onChanged: (v) => setState(() => _marketingEmails = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
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
