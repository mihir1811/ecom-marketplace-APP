import '../localized_message.dart';

/// Copy for the redesigned gemstone finder → results → detail flow.
/// Generic flow copy (reset, filters, sort, …) is shared via
/// `DiamondFlowL10n`.
abstract final class GemstoneFlowL10n {
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
