import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_validators.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/filters/filter_chip.dart';
import '../../../api_share/application/api_share_providers.dart';
import '../../../api_share/domain/models/api_share.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/translations/remaining_messages.dart';

class SellerApiKeysScreen extends ConsumerStatefulWidget {
  const SellerApiKeysScreen({super.key});

  @override
  ConsumerState<SellerApiKeysScreen> createState() =>
      _SellerApiKeysScreenState();
}

class _SellerApiKeysScreenState extends ConsumerState<SellerApiKeysScreen> {
  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showGenerateDialog() async {
    final created = await showAppDialog<ApiShareKey>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _GenerateApiKeyDialog(
        onGenerate: (name, email, permissions) {
          return ref
              .read(apiShareProvider.notifier)
              .generate(name: name, email: email, permissions: permissions);
        },
      ),
    );
    if (created == null || !mounted) return;
    await _showGeneratedKey(created);
  }

  Future<void> _showGeneratedKey(ApiShareKey apiKey) async {
    if (!mounted) return;
    await showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(RemainingL10n.apiKeyCreated)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(RemainingL10n.apiKeyEmailed, {'email': apiKey.email}),
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.s12),
            SelectableText(
              apiKey.apiKey,
              style: AppTypography.caption.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: apiKey.apiKey));
              if (!mounted) return;
              _snack(context.tr(RemainingL10n.apiKeyCopied));
            },
            child: Text(context.tr(RemainingL10n.copy)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr(RemainingL10n.done)),
          ),
        ],
      ),
    );
  }

  Future<void> _editPermissions(ApiShareKey key) async {
    final permissions = await showAppDialog<List<ApiSharePermission>>(
      context: context,
      builder: (context) => _EditPermissionsDialog(
        title: context.tr(RemainingL10n.permissionsForName, {'name': key.name}),
        initial: key.permissions,
      ),
    );
    if (permissions == null || !mounted) return;

    final result = await ref
        .read(apiShareProvider.notifier)
        .updatePermissions(id: key.id, permissions: permissions);
    if (!mounted) return;
    switch (result) {
      case Success():
        _snack(context.tr(RemainingL10n.permissionsUpdated));
      case ResultFailure(failure: final failure):
        _snack(failure.message);
    }
  }

  Future<void> _revoke(ApiShareKey key) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(RemainingL10n.revokeApiKey)),
        content: Text(
          '“${key.name}” will stop working immediately for partners using it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr(RemainingL10n.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr(RemainingL10n.revoke)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(apiShareProvider.notifier).revoke(key.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        _snack(context.tr(RemainingL10n.apiKeyRevoked));
      case ResultFailure(failure: final failure):
        _snack(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiShareProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                tooltip: context.tr(RemainingL10n.refresh),
                onPressed: state.isLoading || state.isMutating
                    ? null
                    : () => ref.read(apiShareProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.icon(
                onPressed: state.isMutating ? null : _showGenerateDialog,
                icon: const Icon(Icons.add),
                label: Text(context.tr(RemainingL10n.generate)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Text(
                context.tr(RemainingL10n.createApiKeysForPartnersTo),
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                  child: Text(
                    state.errorMessage!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.keys.isEmpty)
                Text(
                  context.tr(RemainingL10n.noApiKeysYetGenerateOneTo),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted(context),
                  ),
                )
              else
                for (final key in state.keys) ...[
                  _ApiKeyTile(
                    apiKey: key,
                    busy: state.isMutating,
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: key.apiKey));
                      _snack(context.tr(RemainingL10n.apiKeyCopied));
                    },
                    onEdit: () => _editPermissions(key),
                    onRevoke: () => _revoke(key),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GenerateApiKeyDialog extends StatefulWidget {
  const _GenerateApiKeyDialog({required this.onGenerate});

  final Future<Result<ApiShareKey, Failure>> Function(
    String name,
    String email,
    List<ApiSharePermission> permissions,
  )
  onGenerate;

  @override
  State<_GenerateApiKeyDialog> createState() => _GenerateApiKeyDialogState();
}

class _GenerateApiKeyDialogState extends State<_GenerateApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _selected = <ApiSharePermission>{
    ApiSharePermission.hold,
    ApiSharePermission.sell,
  };
  String? _permissionError;
  String? _submitError;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _permissionError = null;
      _submitError = null;
    });
    if (_formKey.currentState?.validate() != true) return;
    if (_selected.isEmpty) {
      setState(
        () => _permissionError = context.tr(
          RemainingL10n.selectAtLeastOnePermission,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await widget.onGenerate(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _selected.toList(),
    );
    if (!mounted) return;

    switch (result) {
      case Success(value: final key):
        Navigator.of(context).pop(key);
      case ResultFailure(failure: final failure):
        setState(() {
          _saving = false;
          _submitError = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(RemainingL10n.generateApiKey),
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_saving,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr(RemainingL10n.name),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return context.tr(RemainingL10n.nameIsRequired);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_saving,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.tr(RemainingL10n.email),
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty)
                          return context.tr(RemainingL10n.emailIsRequired);
                        if (!isValidEmail(v)) {
                          return context.tr(
                            RemainingL10n.enterAValidEmailAddress,
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      context.tr(RemainingL10n.permissions),
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in ApiSharePermission.values)
                          FilterChipWidget(
                            label: p.apiValue,
                            isSelected: _selected.contains(p),
                            onTap: _saving
                                ? () {}
                                : () {
                                    setState(() {
                                      if (_selected.contains(p)) {
                                        _selected.remove(p);
                                      } else {
                                        _selected.add(p);
                                      }
                                      _permissionError = null;
                                    });
                                  },
                          ),
                      ],
                    ),
                    if (_permissionError != null) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        _permissionError!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        _submitError!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    if (_saving) ...[
                      const SizedBox(height: AppSpacing.s16),
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        context.tr(RemainingL10n.generatingApiKey),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(context.tr(RemainingL10n.cancel)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(context.tr(RemainingL10n.generate)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPermissionsDialog extends StatefulWidget {
  const _EditPermissionsDialog({required this.title, required this.initial});

  final String title;
  final List<ApiSharePermission> initial;

  @override
  State<_EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<_EditPermissionsDialog> {
  late final Set<ApiSharePermission> _selected;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial.toSet();
  }

  void _submit() {
    if (_selected.isEmpty) {
      setState(
        () => _permissionError = context.tr(
          RemainingL10n.selectAtLeastOnePermission,
        ),
      );
      return;
    }
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in ApiSharePermission.values)
                    FilterChipWidget(
                      label: p.apiValue,
                      isSelected: _selected.contains(p),
                      onTap: () {
                        setState(() {
                          if (_selected.contains(p)) {
                            _selected.remove(p);
                          } else {
                            _selected.add(p);
                          }
                          _permissionError = null;
                        });
                      },
                    ),
                ],
              ),
              if (_permissionError != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _permissionError!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr(RemainingL10n.cancel)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: Text(context.tr(RemainingL10n.save)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiKeyTile extends StatelessWidget {
  const _ApiKeyTile({
    required this.apiKey,
    required this.busy,
    required this.onCopy,
    required this.onEdit,
    required this.onRevoke,
  });

  final ApiShareKey apiKey;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final perms = apiKey.permissions.map((p) => p.apiValue).join(' · ');
    return Material(
      color: AppColors.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    apiKey.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.copyKey),
                  onPressed: busy ? null : onCopy,
                  icon: const Icon(Icons.copy_outlined),
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.editPermissions),
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.tune),
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.revoke),
                  onPressed: busy ? null : onRevoke,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              apiKey.email,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              apiKey.maskedApiKey,
              style: AppTypography.caption.copyWith(fontFamily: 'monospace'),
            ),
            if (perms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                perms,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
