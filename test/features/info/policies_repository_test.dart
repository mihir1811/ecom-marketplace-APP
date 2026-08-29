import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone/core/l10n/app_localizations.dart';
import 'package:gemstone/features/info/data/policies_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all policy bundles for supported locales', () async {
    final english = await PoliciesRepository.loadAll(AppLocale.english);
    final hindi = await PoliciesRepository.loadAll(AppLocale.hindi);
    final gujarati = await PoliciesRepository.loadAll(AppLocale.gujarati);

    expect(english, isNotEmpty);
    expect(hindi.length, english.length);
    expect(gujarati.length, english.length);

    final englishTerms = english.firstWhere((policy) => policy.id == 'terms');
    final hindiTerms = hindi.firstWhere((policy) => policy.id == 'terms');
    final gujaratiTerms = gujarati.firstWhere((policy) => policy.id == 'terms');

    expect(englishTerms.title, isNotEmpty);
    expect(hindiTerms.title, isNot(englishTerms.title));
    expect(gujaratiTerms.title, isNot(englishTerms.title));
    expect(hindiTerms.title, isNot(gujaratiTerms.title));
  });

  test('loadById returns localized policy for active locale', () async {
    final hindiPrivacy = await PoliciesRepository.loadById(
      'privacy',
      AppLocale.hindi,
    );
    final englishPrivacy = await PoliciesRepository.loadById(
      'privacy',
      AppLocale.english,
    );

    expect(hindiPrivacy, isNotNull);
    expect(englishPrivacy, isNotNull);
    expect(hindiPrivacy!.title, isNot(englishPrivacy!.title));
    expect(hindiPrivacy.sections.length, englishPrivacy.sections.length);
  });
}
