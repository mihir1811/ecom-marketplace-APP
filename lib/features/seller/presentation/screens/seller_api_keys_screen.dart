import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_validators.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/gem3d/gem_mesh.dart';
import '../../../../core/widgets/gem3d/gem_renderer.dart';
import '../../../api_share/application/api_share_providers.dart';
import '../../../api_share/domain/models/api_share.dart';
import '../atelier/atelier_components.dart';
import '../atelier/atelier_feedback.dart';
import '../atelier/atelier_motion.dart';
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
      subtitle: 'We email the key to your partner the moment it’s created.',
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
    final catalogue = keys
        .where((k) => k.permissions.any((perm) => perm.edits))
        .length;
    final visible = _visible(keys);
    final loadError =
        state.errorMessage != null && state.errorMessage != _handledError
        ? state.errorMessage
        : null;

    return ColoredBox(
      color: p.canvas,
      child: AtelierPage(
        onRefresh: _refresh,
        maxWidth: 1080,
        children: [
          AtelierHero(
            overline: 'Partner access',
            title: context.tr(RemainingL10n.apiKeys),
            subtitle: context.tr(RemainingL10n.createApiKeysForPartnersTo),
            cut: GemCut.emerald,
            look: GemLook.ice,
            action: AtelierButton(
              label: context.tr(RemainingL10n.generateApiKey),
              icon: Icons.add_rounded,
              variant: AtelierButtonVariant.gold,
              onPressed: state.isMutating ? null : _generate,
            ),
            footer: AtelierHeroStats(
              stats: [
                AtelierHeroStat(
                  label: 'Active keys',
                  value: firstLoad ? '—' : '${keys.length}',
                  caption: 'Working right now',
                  tone: keys.isEmpty ? null : AtelierTone.emerald,
                ),
                AtelierHeroStat(
                  label: 'Partners',
                  value: firstLoad ? '—' : '${partners.length}',
                  caption: 'Distinct recipients',
                ),
                AtelierHeroStat(
                  label: 'Catalogue access',
                  value: firstLoad ? '—' : '$catalogue',
                  caption: 'Keys that add or edit stones',
                  tone: catalogue > 0 ? AtelierTone.amber : null,
                ),
              ],
            ),
          ),
          if (loadError != null && keys.isNotEmpty) ...[
            const SizedBox(height: AtelierSpace.s16),
            Reveal(
              child: AtelierNotice(
                tone: AtelierTone.ruby,
                icon: Icons.cloud_off_rounded,
                text: loadError,
                actionLabel: context.tr(RemainingL10n.retry),
                onAction: _refresh,
              ),
            ),
          ],
          const SizedBox(height: AtelierSpace.s32),
          Reveal(
            index: 1,
            child: AtelierSectionHeader(
              overline: 'Scopes',
              title: context.tr(RemainingL10n.permissions),
              subtitle: keys.isEmpty
                  ? 'What a partner can do with a key.'
                  : 'What a partner can do with a key — tap one to filter.',
            ),
          ),
          const SizedBox(height: AtelierSpace.s16),
          AtelierTileGrid(
            columns: 4,
            minTileWidth: 150,
            children: [
              for (final perm in ApiSharePermission.values)
                _ScopeTile(
                  permission: perm,
                  count: firstLoad
                      ? null
                      : keys.where((k) => k.permissions.contains(perm)).length,
                  selected: _filter == perm,
                  onTap: keys.isEmpty
                      ? null
                      : () => setState(
                          () => _filter = _filter == perm ? null : perm,
                        ),
                ),
            ],
          ),
          const SizedBox(height: AtelierSpace.s40),
          Reveal(
            index: 2,
            child: AtelierSectionHeader(
              overline: 'Issued',
              title: 'Your keys',
              subtitle: firstLoad
                  ? null
                  : keys.isEmpty
                  ? 'None issued yet.'
                  : visible.length == keys.length
                  ? '${keys.length} ${keys.length == 1 ? 'key' : 'keys'}'
                  : 'Showing ${visible.length} of ${keys.length}',
              trailing: AtelierIconButton(
                icon: Icons.refresh_rounded,
                tooltip: context.tr(RemainingL10n.refresh),
                filled: true,
                onPressed: state.isLoading || state.isMutating
                    ? null
                    : _refresh,
              ),
            ),
          ),
          const SizedBox(height: AtelierSpace.s16),
          if (keys.length > 3) ...[
            Reveal(
              index: 3,
              child: AtelierSearchField(
                controller: _search,
                hint: 'Search by key name or partner email',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AtelierSpace.s12),
          ],
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topLeft,
            child: _filter == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AtelierFilterTag(
                        label: 'Can ${_filter!.title.toLowerCase()}',
                        onRemove: () => setState(() => _filter = null),
                      ),
                    ),
                  ),
          ),
          AnimatedSize(
            duration: AtelierMotion.slow,
            curve: AtelierMotion.emphasized,
            alignment: Alignment.topCenter,
            child: _keyList(state, visible, loadError),
          ),
        ],
      ),
    );
  }

  Widget _keyList(
    ApiShareState state,
    List<ApiShareKey> visible,
    String? loadError,
  ) {
    if (state.isLoading && state.keys.isEmpty) {
      return const AtelierSkeletonList(count: 3, height: 168);
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
      return Column(
        children: [
          AtelierEmptyState(
            compact: true,
            icon: Icons.vpn_key_outlined,
            title: 'No keys issued',
            message: context.tr(RemainingL10n.noApiKeysYetGenerateOneTo),
            actionLabel: context.tr(RemainingL10n.generateApiKey),
            onAction: _generate,
          ),
          const _HowItWorks(),
        ],
      );
    }
    if (visible.isEmpty) {
      return AtelierEmptyState(
        compact: true,
        icon: Icons.filter_alt_off_outlined,
        title: 'No matching keys',
        message: 'Try another scope or clear your search.',
        actionLabel: 'Clear filters',
        onAction: () => setState(() {
          _filter = null;
          _search.clear();
          _query = '';
        }),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++)
          Padding(
            key: ValueKey(visible[i].id),
            padding: const EdgeInsets.only(bottom: AtelierSpace.s12),
            child: Reveal(
              index: i,
              child: _ApiKeyCard(
                apiKey: visible[i],
                revoking: _revoking == visible[i].id,
                busy: state.isMutating,
                onCopy: () => _copyKey(visible[i]),
                onEdit: () => _editPermissions(visible[i]),
                onRevoke: () => _revoke(visible[i]),
              ),
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

  IconData get icon => switch (this) {
    ApiSharePermission.hold => Icons.back_hand_outlined,
    ApiSharePermission.sell => Icons.sell_outlined,
    ApiSharePermission.insert => Icons.add_box_outlined,
    ApiSharePermission.update => Icons.edit_note_rounded,
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
// Scope tiles
// ---------------------------------------------------------------------------

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.permission,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ApiSharePermission permission;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final tone = permission.edits ? AtelierTone.amber : AtelierTone.gold;
    final body = AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.emphasized,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
      decoration: BoxDecoration(
        color: selected ? p.goldSoft : p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(
          color: selected ? p.gold : p.hairline,
          width: selected ? 1.3 : 1,
        ),
        boxShadow: selected ? null : p.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AtelierIconBadge(icon: permission.icon, tone: tone, size: 34),
              const Spacer(),
              if (count != null)
                AnimatedSwitcher(
                  duration: AtelierMotion.base,
                  child: Text(
                    '$count',
                    key: ValueKey(count),
                    style: AtelierType.display(
                      selected ? p.gold : p.ink,
                      size: 26,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                permission.apiValue,
                style: AtelierType.overline(selected ? p.ink : p.muted),
              ),
              if (permission.edits)
                const AtelierPill(
                  label: 'Catalogue',
                  tone: AtelierTone.amber,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            permission.blurb,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AtelierType.caption(p.inkSoft, size: 12.5),
          ),
        ],
      ),
    );
    if (onTap == null) return body;
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Filter keys that can ${permission.title}',
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        child: body,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Key card
// ---------------------------------------------------------------------------

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

    return AnimatedOpacity(
      duration: AtelierMotion.base,
      opacity: widget.revoking ? 0.55 : 1,
      child: AtelierCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  AtelierMonogram(name: k.name, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.title(p.ink),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          k.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtelierType.caption(p.muted, size: 12.5),
                        ),
                      ],
                    ),
                  ),
                  if (created != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        edited ? 'Edited ${_date(updated)}' : _date(created),
                        style: AtelierType.caption(p.muted, size: 11.5),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final perm in ApiSharePermission.values)
                    _ScopeChip(
                      permission: perm,
                      granted: k.permissions.contains(perm),
                    ),
                ],
              ),
            ),
            const AtelierHairline(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Flexible(
                    child: AtelierButton(
                      label: context.tr(RemainingL10n.copyKey),
                      icon: Icons.copy_rounded,
                      variant: AtelierButtonVariant.ghost,
                      compact: true,
                      onPressed: locked ? null : widget.onCopy,
                    ),
                  ),
                  Flexible(
                    child: AtelierButton(
                      label: context.tr(RemainingL10n.permissions),
                      icon: Icons.tune_rounded,
                      variant: AtelierButtonVariant.ghost,
                      compact: true,
                      onPressed: locked ? null : widget.onEdit,
                    ),
                  ),
                  const Spacer(),
                  AtelierButton(
                    label: context.tr(RemainingL10n.revoke),
                    icon: Icons.key_off_outlined,
                    variant: AtelierButtonVariant.danger,
                    compact: true,
                    loading: widget.revoking,
                    onPressed: locked ? null : widget.onRevoke,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monospace key display with reveal and copy.
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
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: p.sunken,
        borderRadius: BorderRadius.circular(AtelierRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.vpn_key_outlined, size: 15, color: p.gold),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: AtelierMotion.base,
              transitionBuilder: (child, a) =>
                  FadeTransition(opacity: a, child: child),
              child: Align(
                key: ValueKey(shown),
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  value,
                  maxLines: shown ? 3 : 1,
                  style: AtelierType.label(p.ink, size: 13).copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: shown ? 0.4 : 1.6,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: shown ? 'Hide key' : 'Show key',
            onPressed: onToggle,
            icon: Icon(
              shown ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: p.inkSoft,
            ),
          ),
          IconButton(
            tooltip: context.tr(RemainingL10n.copyKey),
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: 17, color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: granted
              ? c.withValues(alpha: p.isDark ? 0.16 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AtelierRadius.pill),
          border: Border.all(
            color: granted ? c.withValues(alpha: 0.35) : p.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.check_rounded : Icons.remove_rounded,
              size: 12,
              color: granted ? c : p.muted,
            ),
            const SizedBox(width: 5),
            Text(
              permission.apiValue,
              style: AtelierType.label(
                granted ? p.ink : p.muted,
                size: 11,
              ).copyWith(letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    const steps = [
      (Icons.vpn_key_outlined, 'Generate', 'Name the partner and pick scopes.'),
      (
        Icons.mark_email_read_outlined,
        'Deliver',
        'The key is emailed to them.',
      ),
      (Icons.hub_outlined, 'Connect', 'They use it to reach your inventory.'),
    ];
    return AtelierPanel(
      overline: 'How it works',
      title: 'Three steps to partner access',
      child: AtelierTileGrid(
        columns: 3,
        minTileWidth: 180,
        children: [
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.gold.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AtelierType.display(p.gold, size: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(steps[i].$1, size: 14, color: p.inkSoft),
                          const SizedBox(width: 6),
                          Text(
                            steps[i].$2,
                            style: AtelierType.title(p.ink, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i].$3,
                        style: AtelierType.caption(p.muted, size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(RemainingL10n.permissions).toUpperCase(),
                style: AtelierType.overline(p.muted),
              ),
            ),
            TextButton(
              onPressed: enabled
                  ? () => onChanged(
                      all
                          ? <ApiSharePermission>{}
                          : ApiSharePermission.values.toSet(),
                    )
                  : null,
              style: TextButton.styleFrom(foregroundColor: p.gold),
              child: Text(
                all ? 'Clear all' : 'Select all',
                style: AtelierType.label(p.gold, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) {
            const gap = AtelierSpace.s10;
            final cols = c.maxWidth >= 380 ? 2 : 1;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final perm in ApiSharePermission.values)
                  SizedBox(
                    width: w,
                    child: _PermissionToggle(
                      permission: perm,
                      on: selected.contains(perm),
                      onTap: enabled ? () => _toggle(perm) : null,
                    ),
                  ),
              ],
            );
          },
        ),
        AtelierFieldError(error: error),
      ],
    );
  }
}

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
      child: Pressable(
        onTap: onTap,
        semanticLabel: '${permission.title}, ${permission.blurb}',
        borderRadius: BorderRadius.circular(AtelierRadius.md),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? p.goldSoft : p.sunken,
            borderRadius: BorderRadius.circular(AtelierRadius.md),
            border: Border.all(
              color: on ? p.gold : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(permission.icon, size: 18, color: on ? p.gold : p.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.title,
                      style: AtelierType.label(p.ink, size: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      permission.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: AtelierMotion.base,
                curve: AtelierMotion.settle,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? p.gold : Colors.transparent,
                  border: Border.all(
                    color: on ? p.gold : p.hairline,
                    width: 1.4,
                  ),
                ),
                child: AnimatedScale(
                  scale: on ? 1 : 0,
                  duration: AtelierMotion.base,
                  curve: AtelierMotion.settle,
                  child: Icon(Icons.check_rounded, size: 14, color: p.onGold),
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
          Reveal(
            child: AtelierTextField(
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
          ),
          const SizedBox(height: AtelierSpace.s16),
          Reveal(
            index: 1,
            child: AtelierTextField(
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
          ),
          const SizedBox(height: AtelierSpace.s20),
          Reveal(
            index: 2,
            child: _PermissionPicker(
              selected: _selected,
              enabled: !_saving,
              error: _permissionError,
              onChanged: (next) => setState(() {
                _selected = next;
                _permissionError = null;
              }),
            ),
          ),
          AnimatedSize(
            duration: AtelierMotion.base,
            curve: AtelierMotion.emphasized,
            child: _submitError == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AtelierSpace.s16),
                    child: AtelierNotice(
                      tone: AtelierTone.ruby,
                      icon: Icons.error_outline_rounded,
                      text: _submitError!,
                    ),
                  ),
          ),
          const SizedBox(height: AtelierSpace.s24),
          Reveal(
            index: 3,
            child: AtelierButton(
              label: _saving
                  ? context.tr(RemainingL10n.generatingApiKey)
                  : context.tr(RemainingL10n.generate),
              icon: Icons.vpn_key_rounded,
              variant: AtelierButtonVariant.gold,
              expand: true,
              loading: _saving,
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: AtelierSpace.s8),
          AtelierButton(
            label: context.tr(RemainingL10n.cancel),
            variant: AtelierButtonVariant.ghost,
            expand: true,
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
          const SizedBox(height: AtelierSpace.s12),
          const AtelierNotice(
            icon: Icons.bolt_rounded,
            text:
                'Changes apply to this key immediately — partners don’t '
                'need a new key.',
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
          const SizedBox(height: AtelierSpace.s24),
          Row(
            children: [
              Expanded(
                child: AtelierButton(
                  label: context.tr(RemainingL10n.cancel),
                  variant: AtelierButtonVariant.secondary,
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
            padding: const EdgeInsets.all(14),
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
              ).copyWith(fontFamily: 'monospace', height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final perm in ApiSharePermission.values)
                _ScopeChip(
                  permission: perm,
                  granted: k.permissions.contains(perm),
                ),
            ],
          ),
          const SizedBox(height: 14),
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
