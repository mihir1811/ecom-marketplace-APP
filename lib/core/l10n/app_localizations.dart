import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'locale_preference_provider.dart';
import 'localized_message.dart';
import 'translations/account_commerce_messages.dart';
import 'translations/catalog_messages.dart';
import 'translations/core_messages.dart';
import 'translations/home_messages.dart';
import 'translations/remaining_messages.dart';

export 'locale_preference_provider.dart';
export 'translations/account_commerce_messages.dart';
export 'translations/catalog_messages.dart';
export 'translations/core_messages.dart';
export 'translations/home_messages.dart';
export 'translations/remaining_messages.dart';
export 'catalog_filter_value_labels.dart';

/// Type-safe access to all static frontend translations.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = AppLocale.supported;
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLocale.english);
  }

  static const Map<String, LocalizedMessage> _messages = {
    ...coreMessages,
    ...accountCommerceMessages,
    ...catalogMessages,
    ...remainingMessages,
    ...homeMessages,
  };

  /// Complete immutable message catalog, exposed for validation tests.
  static Map<String, LocalizedMessage> get messages => _messages;

  /// Resolves a stable localization key and safely substitutes placeholders.
  String text(String key, [Map<String, Object?> parameters = const {}]) {
    final message = _messages[key];
    assert(message != null, 'Missing localization key: $key');
    var value =
        message?.forLanguage(locale.languageCode) ??
        coreMessages[key]?.english ??
        key;
    for (final entry in parameters.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }
}

/// Installs [AppLocalizations] for the active locale.
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocale.supported.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(AppLocale.fromLanguageCode(locale.languageCode)),
    );
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Concise localized-message lookup for widgets.
extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, [Map<String, Object?> parameters = const {}]) {
    return l10n.text(key, parameters);
  }
}
