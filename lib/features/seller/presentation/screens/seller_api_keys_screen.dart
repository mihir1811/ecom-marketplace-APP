import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemstone/core/theme/app_fonts.dart';

import '../../../../core/widgets/navigation/top_bar/top_bar_create_action.dart';
import '../../../../core/auth/auth_validators.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../api_share/application/api_share_providers.dart';
import '../../../api_share/domain/models/api_share.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_studio.dart';
import '../atelier/atelier_theme.dart';

/// Partner access: issue API keys that let partners read and act on the
/// seller's inventory, scope what each key may do, and revoke it.
class SellerApiKeysScreen extends ConsumerStatefulWidget {
  const SellerApiKeysScreen({super.key});

  @override
  ConsumerState<SellerApiKeysScreen> createState() =>
      _SellerApiKeysScreenState();
}

class _SellerApiKeysScreenState extends ConsumerState<SellerApiKeysScreen> {
  final _search = TextEditingController();
  String _query = '';
  ApiSharePermission? _filter;
  String? _revoking;

  /// Mutation errors are already shown where they happened (sheet / toast);
  /// the page banner is reserved for list-load failures.
  String? _handledError;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ApiShareNotifier get _notifier => ref.read(apiShareProvider.notifier);

  Future<void> _refresh() => _notifier.refresh();

  Future<void> _copyKey(ApiShareKey key) async {
    await Clipboard.setData(ClipboardData(text: key.apiKey));
    AppHaptics.success();
    if (!mounted) return;
    showAtelierToast(
      context,
      context.tr(RemainingL10n.apiKeyCopied),
      tone: AtelierTone.emerald,
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _generate() async {
    final created = await showAtelierSheet<ApiShareKey>(
      context: context,
      title: context.tr(RemainingL10n.generateApiKey),
      builder: (_) => _GenerateKeySheet(
        onGenerate: (name, email, permissions) async {
          final result = await _notifier.generate(
            name: name,
            email: email,
            permissions: permissions,
          );
          if (result case ResultFailure(failure: final f)) {
            _handledError = f.message;
          }
          return result;
        },
      ),
    );
    if (created == null || !mounted) return;
    AppHaptics.success();
    setState(() {
      _filter = null;
      _search.clear();
      _query = '';
    });
    await showAtelierDialog<void>(
      context: context,
      builder: (_) => _KeyCreatedDialog(apiKey: created),
    );
  }

  Future<void> _editPermissions(ApiShareKey key) async {
    final saved = await showAtelierSheet<bool>(
      context: context,
      title: context.tr(RemainingL10n.editPermissions),
      subtitle: context.tr(RemainingL10n.permissionsForName, {
        'name': key.name,
      }),
      builder: (_) => _EditPermissionsSheet(
        initial: key.permissions,
        onSave: (permissions) async {
          final result = await _notifier.updatePermissions(
            id: key.id,
            permissions: permissions,
          );
          if (result case ResultFailure(failure: final f)) {
            _handledError = f.message;
          }
          return result;
        },
      ),
    );
    if (saved != true || !mounted) return;
    AppHaptics.success();
    showAtelierToast(
      context,
      context.tr(RemainingL10n.permissionsUpdated),
      tone: AtelierTone.emerald,
    );
  }

  Future<void> _revoke(ApiShareKey key) async {
    final confirmed = await showAtelierConfirm(
      context: context,
      title: context.tr(RemainingL10n.revokeApiKey),
      message:
          '“${key.name}” will stop working immediately for partners using it.',
      confirmLabel: context.tr(RemainingL10n.revoke),
      cancelLabel: context.tr(RemainingL10n.cancel),
      destructive: true,
      icon: Icons.key_off_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _revoking = key.id);
    final result = await _notifier.revoke(key.id);
    if (!mounted) return;
    setState(() => _revoking = null);
    switch (result) {
      case Success():
        AppHaptics.success();
        showAtelierToast(context, context.tr(RemainingL10n.apiKeyRevoked));
      case ResultFailure(failure: final failure):
        _handledError = failure.message;
        AppHaptics.error();
        showAtelierToast(context, failure.message, tone: AtelierTone.ruby);
    }
  }

  List<ApiShareKey> _visible(List<ApiShareKey> keys) {
    final q = _query.trim().toLowerCase();
    return [
      for (final k in keys)
        if ((_filter == null || k.permissions.contains(_filter)) &&
            (q.isEmpty ||
                k.name.toLowerCase().contains(q) ||
                k.email.toLowerCase().contains(q)))
          k,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final state = ref.watch(apiShareProvider);
    final keys = state.keys;
    final firstLoad = state.isLoading && keys.isEmpty;
    final partners = keys.map((k) => k.email.trim().toLowerCase()).toSet();
    final visible = _visible(keys);
    final loadError =
        state.errorMessage != null && state.errorMessage != _handledError
        ? state.errorMessage
        : null;

    return TopBarCreateAction(
      create: TopBarCreate(
        label: 'API key',
        tooltip: context.tr(RemainingL10n.generateApiKey),
        onPressed: state.isMutating ? null : _generate,
      ),
      child: ColoredBox(
        color: p.canvas,
        child: AtelierPage(
          onRefresh: _refresh,
          maxWidth: 900,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    firstLoad
                        ? context.tr(RemainingL10n.apiKeys)
                        : '${keys.length} ${keys.length == 1 ? 'key' : 'keys'}'
                              ' · ${partners.length} '
                              '${partners.length == 1 ? 'partner' : 'partners'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(p.ink, size: 13),
                  ),
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.refresh),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.refresh_rounded, size: 20, color: p.inkSoft),
                  onPressed: state.isLoading || state.isMutating
                      ? null
                      : _refresh,
                ),
              ],
            ),
            if (loadError != null && keys.isNotEmpty) ...[
              const SizedBox(height: 6),
              AtelierNotice(
                tone: AtelierTone.ruby,
                icon: Icons.cloud_off_rounded,
                text: loadError,
                actionLabel: context.tr(RemainingL10n.retry),
                onAction: _refresh,
              ),
            ],
            if (keys.isNotEmpty) ...[
              const SizedBox(height: 6),
              AtelierSegmented<ApiSharePermission?>(
                dense: true,
                segments: [
                  AtelierSegment(
                    value: null,
                    label: context.tr(RemainingL10n.all),
                    count: keys.length,
                  ),
                  for (final perm in ApiSharePermission.values)
                    AtelierSegment(
                      value: perm,
                      label: perm.title,
                      count: keys
                          .where((k) => k.permissions.contains(perm))
                          .length,
                    ),
                ],
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ],
            if (keys.length > 3) ...[
              const SizedBox(height: 6),
              AtelierSearchField(
                controller: _search,
                hint: 'Search by key name or partner email',
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
            const SizedBox(height: 6),
            _keyList(state, visible, loadError),
          ],
        ),
      ),
    );
  }

  Widget _keyList(
    ApiShareState state,
    List<ApiShareKey> visible,
    String? loadError,
  ) {
    final p = context.atelier;
    if (state.isLoading && state.keys.isEmpty) {
      return const AtelierSkeletonList(count: 3, height: 96);
    }
    if (loadError != null && state.keys.isEmpty) {
      return AtelierErrorState(
        compact: true,
        title: 'Couldn’t load your keys',
        message: loadError,
        onRetry: _refresh,
      );
    }
    if (state.keys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '${context.tr(RemainingL10n.noApiKeysYetGenerateOneTo)}\n'
          'Name the partner, pick scopes — the key is emailed to them.',
          textAlign: TextAlign.center,
          style: AtelierType.caption(p.muted, size: 12),
        ),
      );
    }
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No matching keys',
              style: AtelierType.caption(p.muted, size: 12),
            ),
            TextButton(
              onPressed: () => setState(() {
                _filter = null;
                _search.clear();
                _query = '';
              }),
              child: Text(
                'Clear filters',
                style: AtelierType.label(p.gold, size: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final k in visible)
          Padding(
            key: ValueKey(k.id),
            padding: const EdgeInsets.only(bottom: 6),
            child: _ApiKeyCard(
              apiKey: k,
              revoking: _revoking == k.id,
              busy: state.isMutating,
              onCopy: () => _copyKey(k),
              onEdit: () => _editPermissions(k),
              onRevoke: () => _revoke(k),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Permission vocabulary
// ---------------------------------------------------------------------------

extension on ApiSharePermission {
  String get title => switch (this) {
    ApiSharePermission.hold => 'Hold',
    ApiSharePermission.sell => 'Sell',
    ApiSharePermission.insert => 'Insert',
    ApiSharePermission.update => 'Update',
  };

  String get blurb => switch (this) {
    ApiSharePermission.hold => 'Reserve stones for a buyer',
    ApiSharePermission.sell => 'Mark stones as sold',
    ApiSharePermission.insert => 'Add new stones to inventory',
    ApiSharePermission.update => 'Edit existing stone details',
  };

  /// Changes the catalogue itself rather than a stone's availability.
  bool get edits =>
      this == ApiSharePermission.insert || this == ApiSharePermission.update;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _date(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

// ---------------------------------------------------------------------------
// Key card
// ---------------------------------------------------------------------------

/// Name · email · date; key with show/copy; scopes with edit and revoke.
class _ApiKeyCard extends StatefulWidget {
  const _ApiKeyCard({
    required this.apiKey,
    required this.revoking,
    required this.busy,
    required this.onCopy,
    required this.onEdit,
    required this.onRevoke,
  });

  final ApiShareKey apiKey;
  final bool revoking;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onRevoke;

  @override
  State<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends State<_ApiKeyCard> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final k = widget.apiKey;
    final locked = widget.busy || widget.revoking;
    final created = k.createdAt;
    final updated = k.updatedAt;
    final edited =
        created != null &&
        updated != null &&
        updated.difference(created).inMinutes >= 1;

    return Opacity(
      opacity: widget.revoking ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 2),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AtelierRadius.md),
          border: Border.all(color: p.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: k.name,
                            style: AtelierType.label(p.ink, size: 13.5),
                          ),
                          if (k.email.trim().isNotEmpty)
                            TextSpan(
                              text: '  ${k.email}',
                              style: AtelierType.caption(p.muted, size: 11.5),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (created != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        edited ? 'Edited ${_date(updated)}' : _date(created),
                        style: AtelierType.caption(p.muted, size: 11),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _KeyWell(
                value: _shown ? k.apiKey : k.maskedApiKey,
                shown: _shown,
                onToggle: () {
                  AppHaptics.selection();
                  setState(() => _shown = !_shown);
                },
                onCopy: locked ? null : widget.onCopy,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final perm in ApiSharePermission.values)
                        _ScopeChip(
                          permission: perm,
                          granted: k.permissions.contains(perm),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr(RemainingL10n.editPermissions),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.tune_rounded, size: 19, color: p.inkSoft),
                  onPressed: locked ? null : widget.onEdit,
                ),
                if (widget.revoking)
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: p.ruby,
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: context.tr(RemainingL10n.revoke),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.key_off_outlined, size: 19, color: p.ruby),
                    onPressed: locked ? null : widget.onRevoke,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Monospace key with reveal and copy.
class _KeyWell extends StatelessWidget {
  const _KeyWell({
    required this.value,
    required this.shown,
    required this.onToggle,
    required this.onCopy,
  });

  final String value;
  final bool shown;
  final VoidCallback onToggle;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.xs),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              value,
              maxLines: shown ? 3 : 1,
              style: AtelierType.label(p.ink, size: 12.5).copyWith(
                fontFamily: AppFonts.monoFontFamily,
                letterSpacing: shown ? 0.3 : 1.2,
              ),
            ),
          ),
          IconButton(
            tooltip: shown ? 'Hide key' : 'Show key',
            visualDensity: VisualDensity.compact,
            onPressed: onToggle,
            icon: Icon(
              shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 17,
              color: p.inkSoft,
            ),
          ),
          IconButton(
            tooltip: context.tr(RemainingL10n.copyKey),
            visualDensity: VisualDensity.compact,
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: 16, color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Scope name: tinted when granted, struck through when not.
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.permission, required this.granted});

  final ApiSharePermission permission;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final c = permission.edits ? p.amber : p.gold;
    return Tooltip(
      message:
          '${permission.title}: ${permission.blurb}'
          '${granted ? '' : ' (not granted)'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: granted ? c.withValues(alpha: p.isDark ? 0.16 : 0.1) : null,
          borderRadius: BorderRadius.circular(AtelierRadius.xs),
          border: Border.all(
            color: granted ? c.withValues(alpha: 0.35) : p.hairline,
          ),
        ),
        child: Text(
          permission.apiValue,
          style: AtelierType.label(granted ? p.ink : p.muted, size: 10.5)
              .copyWith(
                letterSpacing: 0.6,
                decoration: granted ? null : TextDecoration.lineThrough,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission picker (shared by generate + edit)
// ---------------------------------------------------------------------------

class _PermissionPicker extends StatelessWidget {
  const _PermissionPicker({
    required this.selected,
    required this.onChanged,
    required this.enabled,
    this.error,
  });

  final Set<ApiSharePermission> selected;
  final ValueChanged<Set<ApiSharePermission>> onChanged;
  final bool enabled;
  final String? error;

  void _toggle(ApiSharePermission perm) {
    final next = {...selected};
    next.contains(perm) ? next.remove(perm) : next.add(perm);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final all = selected.length == ApiSharePermission.values.length;
    const perms = ApiSharePermission.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(RemainingL10n.permissions),
                style: AtelierType.label(p.inkSoft, size: 12),
              ),
            ),
            TextButton(
              onPressed: enabled
                  ? () =>
                        onChanged(all ? <ApiSharePermission>{} : perms.toSet())
                  : null,
              style: TextButton.styleFrom(
                foregroundColor: p.gold,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                all ? 'Clear all' : 'Select all',
                style: AtelierType.label(p.gold, size: 12),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(color: p.hairline),
          ),
          child: Column(
            children: [
              for (var i = 0; i < perms.length; i++) ...[
                if (i > 0) Container(height: 1, color: p.hairline),
                _PermissionToggle(
                  permission: perms[i],
                  on: selected.contains(perms[i]),
                  onTap: enabled ? () => _toggle(perms[i]) : null,
                ),
              ],
            ],
          ),
        ),
        AtelierFieldError(error: error),
      ],
    );
  }
}

/// Checkbox row: scope name and what it allows.
class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.permission,
    required this.on,
    required this.onTap,
  });

  final ApiSharePermission permission;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      checked: on,
      label: '${permission.title}, ${permission.blurb}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                on ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                size: 20,
                color: on ? p.gold : p.muted,
              ),
              const SizedBox(width: 8),
              Text(permission.title, style: AtelierType.label(p.ink, size: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  permission.blurb,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.caption(p.muted, size: 11.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets & dialogs
// ---------------------------------------------------------------------------

class _GenerateKeySheet extends StatefulWidget {
  const _GenerateKeySheet({required this.onGenerate});

  final Future<Result<ApiShareKey, Failure>> Function(
    String name,
    String email,
    List<ApiSharePermission> permissions,
  )
  onGenerate;

  @override
  State<_GenerateKeySheet> createState() => _GenerateKeySheetState();
}

class _GenerateKeySheetState extends State<_GenerateKeySheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  Set<ApiSharePermission> _selected = {
    ApiSharePermission.hold,
    ApiSharePermission.sell,
  };
  String? _nameError;
  String? _emailError;
  String? _permissionError;
  String? _submitError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() {
      _nameError = name.isEmpty
          ? context.tr(RemainingL10n.nameIsRequired)
          : null;
      _emailError = email.isEmpty
          ? context.tr(RemainingL10n.emailIsRequired)
          : !isValidEmail(email)
          ? context.tr(RemainingL10n.enterAValidEmailAddress)
          : null;
      _permissionError = _selected.isEmpty
          ? context.tr(RemainingL10n.selectAtLeastOnePermission)
          : null;
    });
    return _nameError == null &&
        _emailError == null &&
        _permissionError == null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _submitError = null);
    if (!_validate()) {
      AppHaptics.error();
      return;
    }
    setState(() => _saving = true);
    final result = await widget
        .onGenerate(_name.text.trim(), _email.text.trim(), [
          for (final perm in ApiSharePermission.values)
            if (_selected.contains(perm)) perm,
        ]);
    if (!mounted) return;
    switch (result) {
      case Success(value: final key):
        Navigator.of(context).pop(key);
      case ResultFailure(failure: final failure):
        AppHaptics.error();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AtelierTextField(
            controller: _name,
            label: 'Partner name',
            hint: 'e.g. Brilliant Exports',
            error: _nameError,
            enabled: !_saving,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: AtelierSpace.s10),
          AtelierTextField(
            controller: _email,
            label: 'Partner email',
            hint: 'partner@company.com',
            error: _emailError,
            enabled: !_saving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AtelierSpace.s8),
          _PermissionPicker(
            selected: _selected,
            enabled: !_saving,
            error: _permissionError,
            onChanged: (next) => setState(() {
              _selected = next;
              _permissionError = null;
            }),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AtelierSpace.s10),
            AtelierNotice(
              tone: AtelierTone.ruby,
              icon: Icons.error_outline_rounded,
              text: _submitError!,
            ),
          ],
          const SizedBox(height: AtelierSpace.s12),
          Row(
            children: [
              Expanded(
                child: AtelierButton(
                  label: context.tr(RemainingL10n.cancel),
                  variant: AtelierButtonVariant.secondary,
                  compact: true,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AtelierSpace.s10),
              Expanded(
                flex: 2,
                child: AtelierButton(
                  label: _saving
                      ? context.tr(RemainingL10n.generatingApiKey)
                      : context.tr(RemainingL10n.generate),
                  icon: Icons.vpn_key_rounded,
                  variant: AtelierButtonVariant.gold,
                  compact: true,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditPermissionsSheet extends StatefulWidget {
  const _EditPermissionsSheet({required this.initial, required this.onSave});

  final List<ApiSharePermission> initial;
  final Future<Result<ApiShareKey, Failure>> Function(
    List<ApiSharePermission> permissions,
  )
  onSave;

  @override
  State<_EditPermissionsSheet> createState() => _EditPermissionsSheetState();
}

class _EditPermissionsSheetState extends State<_EditPermissionsSheet> {
  late Set<ApiSharePermission> _selected = widget.initial.toSet();
  String? _permissionError;
  String? _submitError;
  bool _saving = false;

  bool get _changed {
    final initial = widget.initial.toSet();
    return initial.length != _selected.length ||
        !initial.containsAll(_selected);
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_selected.isEmpty) {
      AppHaptics.error();
      setState(
        () => _permissionError = context.tr(
          RemainingL10n.selectAtLeastOnePermission,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _submitError = null;
    });
    final result = await widget.onSave([
      for (final perm in ApiSharePermission.values)
        if (_selected.contains(perm)) perm,
    ]);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case ResultFailure(failure: final failure):
        AppHaptics.error();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PermissionPicker(
            selected: _selected,
            enabled: !_saving,
            error: _permissionError,
            onChanged: (next) => setState(() {
              _selected = next;
              _permissionError = null;
            }),
          ),
          const SizedBox(height: AtelierSpace.s4),
          Text(
            'Changes apply to this key immediately — partners don’t '
            'need a new key.',
            style: AtelierType.caption(context.atelier.muted, size: 11.5),
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: _submitError == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AtelierSpace.s12),
                    child: AtelierNotice(
                      tone: AtelierTone.ruby,
                      icon: Icons.error_outline_rounded,
                      text: _submitError!,
                    ),
                  ),
          ),
          const SizedBox(height: AtelierSpace.s12),
          Row(
            children: [
              Expanded(
                child: AtelierButton(
                  label: context.tr(RemainingL10n.cancel),
                  variant: AtelierButtonVariant.secondary,
                  compact: true,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AtelierSpace.s10),
              Expanded(
                child: AtelierButton(
                  label: _changed
                      ? context.tr(RemainingL10n.save)
                      : 'No changes',
                  variant: AtelierButtonVariant.primary,
                  compact: true,
                  loading: _saving,
                  onPressed: _changed ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeyCreatedDialog extends StatefulWidget {
  const _KeyCreatedDialog({required this.apiKey});

  final ApiShareKey apiKey;

  @override
  State<_KeyCreatedDialog> createState() => _KeyCreatedDialogState();
}

class _KeyCreatedDialogState extends State<_KeyCreatedDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.apiKey.apiKey));
    AppHaptics.success();
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final k = widget.apiKey;
    return AtelierDialogFrame(
      icon: Icons.vpn_key_rounded,
      tone: AtelierTone.emerald,
      title: context.tr(RemainingL10n.apiKeyCreated),
      message: context.tr(RemainingL10n.apiKeyEmailed, {'email': k.email}),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.sunken,
              borderRadius: BorderRadius.circular(AtelierRadius.md),
              border: Border.all(color: p.gold.withValues(alpha: 0.35)),
            ),
            child: SelectableText(
              k.apiKey,
              style: AtelierType.label(
                p.ink,
                size: 13,
              ).copyWith(fontFamily: AppFonts.monoFontFamily, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final perm in ApiSharePermission.values)
                _ScopeChip(
                  permission: perm,
                  granted: k.permissions.contains(perm),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const AtelierNotice(
            tone: AtelierTone.amber,
            icon: Icons.shield_outlined,
            text:
                'Treat this key like a password — anyone holding it can act '
                'with these scopes.',
          ),
        ],
      ),
      actions: [
        AtelierButton(
          label: _copied ? 'Copied' : context.tr(RemainingL10n.copy),
          icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
          variant: AtelierButtonVariant.secondary,
          onPressed: _copy,
        ),
        AtelierButton(
          label: context.tr(RemainingL10n.done),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
