import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../auth/application/login_history_providers.dart';
import '../../../auth/domain/models/login_session.dart';
import '../widgets/seller_layout.dart';

class SellerLoginHistoryScreen extends ConsumerWidget {
  const SellerLoginHistoryScreen({super.key});

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke device?'),
        content: const Text(
          'This will sign out the selected session on that device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result =
        await ref.read(loginHistoryProvider.notifier).revoke(sessionId);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device session revoked')),
        );
      case ResultFailure(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginHistoryProvider);

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
                'Login history & devices',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              if (state.errorMessage != null)
                Text(
                  state.errorMessage!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const _SectionHeader(title: 'Active seller devices'),
                if (state.activeDevices.isEmpty)
                  const _EmptyHint(text: 'No active seller dashboard devices.')
                else
                  for (final device in state.activeDevices)
                    _DeviceTile(
                      title: device.deviceInfo,
                      subtitle:
                          '${device.ipAddress} · ${device.loginAtLabel}',
                      trailing: device.isRemembered ? 'Remembered' : null,
                      onRevoke: state.isMutating
                          ? null
                          : () => _revoke(context, ref, device.id),
                    ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Login history'),
                if (state.sessions.isEmpty)
                  const _EmptyHint(text: 'No login history yet.')
                else
                  for (final session in state.sessions)
                    _SessionTile(
                      session: session,
                      onRevoke: session.isActive && !state.isMutating
                          ? () => _revoke(context, ref, session.id)
                          : null,
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: AppColors.textMutedLight),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onRevoke,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onRevoke == null
            ? (trailing != null ? Text(trailing!) : null)
            : TextButton(onPressed: onRevoke, child: const Text('Revoke')),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.onRevoke});

  final LoginSession session;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.warmBorder),
      ),
      child: ListTile(
        title: Text(session.deviceInfo),
        subtitle: Text(
          '${session.ipAddress}\n${session.loginAtLabel}'
          '${session.isActive ? ' · Active' : ''}',
        ),
        isThreeLine: true,
        trailing: onRevoke == null
            ? null
            : TextButton(onPressed: onRevoke, child: const Text('Revoke')),
      ),
    );
  }
}
