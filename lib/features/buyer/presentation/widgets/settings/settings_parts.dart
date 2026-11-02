import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/auth_providers.dart';
import '../../../../../core/haptics/app_haptics.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/widgets/profile_avatar.dart';
import '../../../../seller/presentation/atelier/atelier_components.dart';
import '../../../../seller/presentation/atelier/atelier_feedback.dart';
import '../../../../seller/presentation/atelier/atelier_motion.dart';
import '../../../../seller/presentation/atelier/atelier_studio.dart';
import '../../../../seller/presentation/atelier/atelier_theme.dart';

// ── Identity ────────────────────────────────────────────────────────────

/// Who is signed in: portrait in a gold ring, name, email, account type and
/// verification. Tapping opens the profile.
class SettingsIdentityCard extends StatelessWidget {
  const SettingsIdentityCard({
    required this.displayName,
    required this.email,
    required this.imageUrl,
    required this.isSeller,
    required this.verified,
    required this.onTap,
    super.key,
  });

  final String displayName;
  final String email;
  final String? imageUrl;
  final bool isSeller;
  final bool verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AtelierCard(
      onTap: onTap,
      semanticLabel:
          '$displayName, ${context.tr(AccountCommerceL10n.myProfile)}',
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: p.goldGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface,
              ),
              child: ProfileAvatar(
                displayName: displayName,
                imageUrl: imageUrl,
                radius: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtelierType.display(p.ink, size: 24),
                ),
                if (email.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.caption(p.muted, size: 12),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    AtelierPill(
                      label: isSeller
                          ? context.tr(AccountCommerceL10n.sellerBusiness)
                          : context.tr(AccountCommerceL10n.individualBuyer),
                      tone: AtelierTone.gold,
                      dense: true,
                    ),
                    AtelierPill(
                      label: verified
                          ? 'Verified'
                          : context.tr(AccountCommerceL10n.verificationPending),
                      icon: verified
                          ? Icons.verified_rounded
                          : Icons.schedule_rounded,
                      tone: verified ? AtelierTone.emerald : AtelierTone.amber,
                      dense: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: p.muted),
        ],
      ),
    );
  }
}

// ── Appearance ──────────────────────────────────────────────────────────

/// Every palette as a live miniature of the app, two per row; the chosen
/// one wears an accent edge and check.
class SettingsThemeChooser extends StatelessWidget {
  const SettingsThemeChooser({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AppPaletteId selected;
  final ValueChanged<AppPaletteId> onChanged;

  @override
  Widget build(BuildContext context) {
    const palettes = AppPalette.selectable;
    return Column(
      children: [
        for (var row = 0; row < palettes.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = row; i < row + 2; i++) ...[
                if (i > row) const SizedBox(width: 8),
                Expanded(
                  child: i < palettes.length
                      ? _ThemeTile(
                          palette: palettes[i].atelier,
                          label: palettes[i].label,
                          caption: palettes[i].id == AppPaletteId.onyx
                              ? context.tr(CoreL10n.darkTheme)
                              : palettes[i].caption,
                          selected: palettes[i].id == selected,
                          onTap: () => onChanged(palettes[i].id),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.palette,
    required this.label,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final AtelierPalette palette;
  final String label;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final m = palette;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: selected ? null : onTap,
        semanticLabel: '$label theme',
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(
              color: selected ? p.gold : p.hairline,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? p.softShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Miniature of a buyer page in this palette.
              Container(
                height: 96,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: m.canvas,
                  borderRadius: BorderRadius.circular(AtelierRadius.md),
                  border: Border.all(color: m.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 14, height: 1.5, color: m.gold),
                        const SizedBox(width: 4),
                        Container(
                          width: 26,
                          height: 3,
                          decoration: BoxDecoration(
                            color: m.muted.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.diamond_outlined, size: 11, color: m.gold),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 54,
                      height: 7,
                      decoration: BoxDecoration(
                        color: m.ink,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: m.surface,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: m.hairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: m.goldGradient,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: 0.8,
                                  child: Container(
                                    height: 3,
                                    color: m.ink.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FractionallySizedBox(
                                  widthFactor: 0.5,
                                  child: Container(
                                    height: 3,
                                    color: m.muted.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 8, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.title(p.ink, size: 14),
                          ),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AtelierType.caption(p.muted, size: 11),
                          ),
                        ],
                      ),
                    ),
                    _Check(selected: selected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return AnimatedContainer(
      duration: AtelierMotion.base,
      curve: AtelierMotion.settle,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: selected ? p.goldGradient : null,
        border: selected ? null : Border.all(color: p.hairline, width: 1.4),
      ),
      child: AnimatedScale(
        duration: AtelierMotion.base,
        curve: AtelierMotion.settle,
        scale: selected ? 1 : 0,
        child: Icon(Icons.check_rounded, size: 14, color: p.onGold),
      ),
    );
  }
}

// ── Language ────────────────────────────────────────────────────────────

/// Every language on screen in its own script — one tap switches.
class SettingsLanguageChooser extends StatelessWidget {
  const SettingsLanguageChooser({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final Locale selected;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (AppLocale.english, 'Aa', 'English', CoreL10n.english),
      (AppLocale.hindi, 'अ', 'हिन्दी', CoreL10n.hindi),
      (AppLocale.gujarati, 'અ', 'ગુજરાતી', CoreL10n.gujarati),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _LanguageTile(
              glyph: options[i].$2,
              name: options[i].$3,
              translated: context.tr(options[i].$4),
              selected: selected.languageCode == options[i].$1.languageCode,
              onTap: () => onChanged(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.glyph,
    required this.name,
    required this.translated,
    required this.selected,
    required this.onTap,
  });

  final String glyph;
  final String name;
  final String translated;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: selected ? null : onTap,
        semanticLabel: translated,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        child: AnimatedContainer(
          duration: AtelierMotion.base,
          curve: AtelierMotion.emphasized,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? p.ink : p.surface,
            borderRadius: BorderRadius.circular(AtelierRadius.lg),
            border: Border.all(color: selected ? p.ink : p.hairline),
            boxShadow: selected ? p.softShadow : null,
          ),
          child: Column(
            children: [
              AnimatedDefaultTextStyle(
                duration: AtelierMotion.base,
                style: AtelierType.display(selected ? p.gold : p.ink, size: 30),
                child: Text(glyph, maxLines: 1),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: AtelierMotion.base,
                style: AtelierType.label(
                  selected ? p.canvas : p.inkSoft,
                  size: 12.5,
                ),
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rows ────────────────────────────────────────────────────────────────

/// Hairline-separated card of [SettingsRow]s.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AtelierRadius.lg),
        border: Border.all(color: p.hairline),
        boxShadow: p.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 66),
                child: Container(height: 1, color: p.hairline),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One destination or action: icon well, title, optional caption, chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.caption,
    this.tone,
    this.chevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? caption;

  /// Colours icon and title (e.g. ruby for destructive rows).
  final AtelierTone? tone;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    final accent = tone == null ? p.ink : p.tone(tone!);
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone == null
                    ? p.sunken
                    : accent.withValues(alpha: p.isDark ? 0.14 : 0.08),
              ),
              child: Icon(
                icon,
                size: 18,
                color: tone == null ? p.inkSoft : accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AtelierType.label(accent, size: 14),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtelierType.caption(p.muted, size: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Delete account ──────────────────────────────────────────────────────

/// Asks for the password and schedules deletion in place; resolves `true`
/// once the server accepted it.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final result = await showAtelierDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeleteAccountDialog(),
  );
  return result ?? false;
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final password = _password.text;
    if (password.trim().isEmpty) {
      AppHaptics.error();
      setState(() => _error = 'Enter your current password to continue.');
      return;
    }
    AppHaptics.warning();
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(authProvider.notifier)
        .requestAccountDeletion(password: password);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    AppHaptics.error();
    setState(() {
      _busy = false;
      _error =
          ref.read(authProvider).errorMessage ??
          'Could not delete account. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.atelier;
    return PopScope(
      canPop: !_busy,
      child: AtelierDialogFrame(
        title: context.tr(AccountCommerceL10n.deleteAccountTitle),
        message:
            'Your account will be scheduled for deletion. You have 7 days to '
            'recover it from the email link or the recover account screen.',
        icon: Icons.delete_forever_outlined,
        tone: AtelierTone.ruby,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(AccountCommerceL10n.currentPassword).toUpperCase(),
              style: AtelierType.overline(p.muted),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: AtelierMotion.base,
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: p.sunken,
                borderRadius: BorderRadius.circular(AtelierRadius.md),
                border: Border.all(
                  color: _error != null
                      ? p.ruby.withValues(alpha: 0.7)
                      : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 17, color: p.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _password,
                      obscureText: _obscure,
                      autofocus: true,
                      enabled: !_busy,
                      cursorColor: p.gold,
                      style: AtelierType.body(p.ink),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _confirm(),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        hintText: '••••••••',
                        hintStyle: AtelierType.body(p.muted),
                      ),
                    ),
                  ),
                  AtelierIconButton(
                    icon: _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    tooltip: _obscure
                        ? context.tr(AccountCommerceL10n.showPassword)
                        : context.tr(AccountCommerceL10n.hidePassword),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ],
              ),
            ),
            AtelierFieldError(error: _error),
          ],
        ),
        actions: [
          AtelierButton(
            label: context.tr(CoreL10n.cancel),
            variant: AtelierButtonVariant.secondary,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          AtelierButton(
            label: context.tr(AccountCommerceL10n.deleteAccount),
            variant: AtelierButtonVariant.danger,
            loading: _busy,
            onPressed: _confirm,
          ),
        ],
      ),
    );
  }
}
