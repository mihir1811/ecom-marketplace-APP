import '../localized_message.dart';

/// Copy for the redesigned gemstone finder → results → detail flow.
/// Generic flow copy (reset, filters, sort, …) is shared via
/// `DiamondFlowL10n`.
abstract final class GemstoneFlowL10n {
  static const finderEyebrow = 'gemstoneFlow.finderEyebrow';
  static const finderHeadline = 'gemstoneFlow.finderHeadline';
  static const finderHeadlineLab = 'gemstoneFlow.finderHeadlineLab';
  static const finderIntro = 'gemstoneFlow.finderIntro';
  static const sectionGemType = 'gemstoneFlow.sectionGemType';
  static const sectionColorQuality = 'gemstoneFlow.sectionColorQuality';
  static const sectionGrading = 'gemstoneFlow.sectionGrading';
  static const popularGems = 'gemstoneFlow.popularGems';
  static const resultsCount = 'gemstoneFlow.resultsCount';
  static const emptyTitle = 'gemstoneFlow.emptyTitle';
  static const errorTitle = 'gemstoneFlow.errorTitle';
  static const sortTitle = 'gemstoneFlow.sortTitle';
}

const gemstoneFlowMessages = <String, LocalizedMessage>{
  GemstoneFlowL10n.finderEyebrow: LocalizedMessage(
    english: 'Gemstone finder',
    hindi: 'रत्न फाइंडर',
    gujarati: 'રત્ન ફાઇન્ડર',
  ),
  GemstoneFlowL10n.finderHeadline: LocalizedMessage(
    english: 'Find your\ncoloured gemstone.',
    hindi: 'अपना\nरंगीन रत्न खोजें।',
    gujarati: 'તમારું\nરંગીન રત્ન શોધો.',
  ),
  GemstoneFlowL10n.finderHeadlineLab: LocalizedMessage(
    english: 'Find your\nlab-grown gemstone.',
    hindi: 'अपना\nलैब-ग्रोन रत्न खोजें।',
    gujarati: 'તમારું\nલેબ-ગ્રોન રત્ન શોધો.',
  ),
  GemstoneFlowL10n.finderIntro: LocalizedMessage(
    english: 'Choose a gem, then refine by shape, size, colour and quality.',
    hindi: 'रत्न चुनें, फिर आकार, साइज़, रंग और गुणवत्ता से सटीक करें।',
    gujarati: 'રત્ન પસંદ કરો, પછી આકાર, સાઇઝ, રંગ અને ગુણવત્તાથી ચોક્કસ કરો.',
  ),
  GemstoneFlowL10n.sectionGemType: LocalizedMessage(
    english: 'Gemstone',
    hindi: 'रत्न',
    gujarati: 'રત્ન',
  ),
  GemstoneFlowL10n.sectionColorQuality: LocalizedMessage(
    english: 'Colour & quality',
    hindi: 'रंग और गुणवत्ता',
    gujarati: 'રંગ અને ગુણવત્તા',
  ),
  GemstoneFlowL10n.sectionGrading: LocalizedMessage(
    english: 'Lab & treatment',
    hindi: 'लैब और उपचार',
    gujarati: 'લેબ અને ઉપચાર',
  ),
  GemstoneFlowL10n.popularGems: LocalizedMessage(
    english: 'Popular gems',
    hindi: 'लोकप्रिय रत्न',
    gujarati: 'લોકપ્રિય રત્નો',
  ),
  GemstoneFlowL10n.resultsCount: LocalizedMessage(
    english: '{count} gemstones',
    hindi: '{count} रत्न',
    gujarati: '{count} રત્નો',
  ),
  GemstoneFlowL10n.emptyTitle: LocalizedMessage(
    english: 'No gemstones match.',
    hindi: 'कोई रत्न मेल नहीं खाता।',
    gujarati: 'કોઈ રત્ન મેળ ખાતું નથી.',
  ),
  GemstoneFlowL10n.errorTitle: LocalizedMessage(
    english: 'We couldn’t load gemstones.',
    hindi: 'रत्न लोड नहीं हो सके।',
    gujarati: 'રત્નો લોડ થઈ શક્યા નહીં.',
  ),
  GemstoneFlowL10n.sortTitle: LocalizedMessage(
    english: 'Sort gemstones',
    hindi: 'रत्न क्रमबद्ध करें',
    gujarati: 'રત્નો ગોઠવો',
  ),
};
