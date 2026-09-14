import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../haptics/app_haptics.dart';
import '../l10n/app_localizations.dart';

/// Compact app-bar control for changing the persisted application language.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({
    super.key,
    this.iconSize = 22,
    this.unauthenticatedOnly = false,
  });

  final double iconSize;
  final bool unauthenticatedOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authProvider.select((state) => state.isAuthenticated),
    );
    if (unauthenticatedOnly && isAuthenticated) {
      return const SizedBox.shrink();
    }
    final locale = ref.watch(localePreferenceProvider);
    return PopupMenuButton<Locale>(
      tooltip: context.tr(CoreL10n.changeLanguage),
      initialValue: locale,
      icon: Icon(Icons.language_outlined, size: iconSize),
      onSelected: (locale) {
        AppHaptics.selection();
        ref.read(localePreferenceProvider.notifier).setLocale(locale);
      },
      itemBuilder: (context) => [
        _item(context, AppLocale.english, CoreL10n.english),
        _item(context, AppLocale.hindi, CoreL10n.hindi),
        _item(context, AppLocale.gujarati, CoreL10n.gujarati),
      ],
    );
  }

  PopupMenuItem<Locale> _item(
    BuildContext context,
    Locale locale,
    String labelKey,
  ) {
    return PopupMenuItem<Locale>(
      value: locale,
      child: Text(context.tr(labelKey)),
    );
  }
}

/// Settings-row variant of the language selector.
class LanguageSettingsTile extends ConsumerWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceProvider);
    final labelKey = switch (locale.languageCode) {
      'hi' => CoreL10n.hindi,
      'gu' => CoreL10n.gujarati,
      _ => CoreL10n.english,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language_outlined),
      title: Text(context.tr(CoreL10n.language)),
      subtitle: Text(context.tr(labelKey)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, ref, locale),
    );
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Locale selected,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr(CoreL10n.selectLanguage)),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
        content: RadioGroup<Locale>(
          groupValue: selected,
          onChanged: (locale) {
            if (locale == null) return;
            AppHaptics.selection();
            ref.read(localePreferenceProvider.notifier).setLocale(locale);
            Navigator.of(dialogContext).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _option(dialogContext, AppLocale.english, CoreL10n.english),
              _option(dialogContext, AppLocale.hindi, CoreL10n.hindi),
              _option(dialogContext, AppLocale.gujarati, CoreL10n.gujarati),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.tr(CoreL10n.cancel)),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, Locale locale, String labelKey) {
    return RadioListTile<Locale>(
      value: locale,
      title: Text(context.tr(labelKey)),
    );
  }
}
