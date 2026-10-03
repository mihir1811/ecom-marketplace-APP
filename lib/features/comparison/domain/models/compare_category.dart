import '../../../../core/l10n/translations/account_commerce_messages.dart';

/// Product category allowed in a single comparison session.
enum CompareCategory {
  diamond,
  gemstone,
  watch,
  jewelry;

  String get labelKey => switch (this) {
    CompareCategory.diamond => AccountCommerceL10n.compareDiamond,
    CompareCategory.gemstone => AccountCommerceL10n.compareGemstone,
    CompareCategory.watch => AccountCommerceL10n.compareWatch,
    CompareCategory.jewelry => AccountCommerceL10n.compareJewelry,
  };

  String get labelPluralKey => switch (this) {
    CompareCategory.diamond => AccountCommerceL10n.compareDiamonds,
    CompareCategory.gemstone => AccountCommerceL10n.compareGemstones,
    CompareCategory.watch => AccountCommerceL10n.compareWatches,
    CompareCategory.jewelry => AccountCommerceL10n.compareJewelryPieces,
  };

  String get label => accountCommerceMessages[labelKey]!.english;

  String get labelPlural => accountCommerceMessages[labelPluralKey]!.english;
}
