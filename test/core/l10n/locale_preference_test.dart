import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemworld/core/l10n/app_localizations.dart';
import 'package:gemworld/core/widgets/language_menu_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('English is the default locale', () {
    final preference = LocalePreference();

    expect(preference.state, AppLocale.english);
  });

  test('saved locale is restored after hydration', () async {
    SharedPreferences.setMockInitialValues({
      'gw.locale.languageCode': AppLocale.gujarati.languageCode,
    });
    final preference = LocalePreference();

    await preference.hydrate();

    expect(preference.state, AppLocale.gujarati);
  });

  test('unsupported saved locale falls back to English', () async {
    SharedPreferences.setMockInitialValues({'gw.locale.languageCode': 'fr'});
    final preference = LocalePreference();

    await preference.hydrate();

    expect(preference.state, AppLocale.english);
  });

  test('locale selection updates immediately and persists', () async {
    final preference = LocalePreference();

    await preference.setLocale(AppLocale.hindi);

    expect(preference.state, AppLocale.hindi);
    final stored = await SharedPreferences.getInstance();
    expect(
      stored.getString('gw.locale.languageCode'),
      AppLocale.hindi.languageCode,
    );
  });

  test('localized messages resolve in all supported languages', () {
    const english = AppLocalizations(AppLocale.english);
    const hindi = AppLocalizations(AppLocale.hindi);
    const gujarati = AppLocalizations(AppLocale.gujarati);

    expect(english.text(CoreL10n.settings), 'Settings');
    expect(hindi.text(CoreL10n.settings), 'सेटिंग्स');
    expect(gujarati.text(CoreL10n.settings), 'સેટિંગ્સ');
  });

  test('every translation preserves interpolation placeholders', () {
    final placeholder = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)\}');
    Set<String> placeholders(String value) => placeholder
        .allMatches(value)
        .map((match) => match.group(1)!)
        .toSet();

    for (final entry in AppLocalizations.messages.entries) {
      final message = entry.value;
      expect(message.english.trim(), isNotEmpty, reason: entry.key);
      expect(message.hindi.trim(), isNotEmpty, reason: entry.key);
      expect(message.gujarati.trim(), isNotEmpty, reason: entry.key);
      expect(
        placeholders(message.hindi),
        placeholders(message.english),
        reason: '${entry.key} Hindi placeholders',
      );
      expect(
        placeholders(message.gujarati),
        placeholders(message.english),
        reason: '${entry.key} Gujarati placeholders',
      );
    }
  });

  testWidgets('language selection updates the visible UI immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _LocaleTestApp()),
    );

    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ગુજરાતી'));
    await tester.pumpAndSettle();

    expect(find.text('ભાષા'), findsOneWidget);
  });
}

class _LocaleTestApp extends ConsumerWidget {
  const _LocaleTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(localePreferenceProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const Scaffold(body: LanguageSettingsTile()),
    );
  }
}
