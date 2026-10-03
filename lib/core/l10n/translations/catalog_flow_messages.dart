import '../localized_message.dart';

/// Copy for the luxe watch and bullion flows (filters → results → detail).
/// Generic flow copy (reset, filters, sort, grid, …) is shared via
/// `DiamondFlowL10n`.
abstract final class CatalogFlowL10n {
  // Shared
  static const showAll = 'catalogFlow.showAll';
  static const showLess = 'catalogFlow.showLess';
  static const min = 'catalogFlow.min';
  static const max = 'catalogFlow.max';
  static const invalidRange = 'catalogFlow.invalidRange';
  static const errorTitle = 'catalogFlow.errorTitle';
  static const draftDiscarded = 'catalogFlow.draftDiscarded';

  // Watches
  static const watchFilterEyebrow = 'catalogFlow.watchFilterEyebrow';
  static const watchFilterHeadline = 'catalogFlow.watchFilterHeadline';
  static const watchFilterIntro = 'catalogFlow.watchFilterIntro';
  static const watchResults = 'catalogFlow.watchResults';
  static const watchSort = 'catalogFlow.watchSort';
  static const brandEyebrow = 'catalogFlow.brandEyebrow';
  static const sectionBrandModel = 'catalogFlow.sectionBrandModel';
  static const sectionStyle = 'catalogFlow.sectionStyle';
  static const sectionPrice = 'catalogFlow.sectionPrice';
  static const sectionMovement = 'catalogFlow.sectionMovement';
  static const sectionCase = 'catalogFlow.sectionCase';
  static const sectionDial = 'catalogFlow.sectionDial';
  static const sectionStrap = 'catalogFlow.sectionStrap';
  static const sectionCondition = 'catalogFlow.sectionCondition';

  // Bullion
  static const bullionFilterEyebrow = 'catalogFlow.bullionFilterEyebrow';
  static const bullionFilterHeadline = 'catalogFlow.bullionFilterHeadline';
  static const bullionFilterIntro = 'catalogFlow.bullionFilterIntro';
  static const bullionResults = 'catalogFlow.bullionResults';
  static const bullionSort = 'catalogFlow.bullionSort';
  static const metal = 'catalogFlow.metal';
  static const sectionFormWeight = 'catalogFlow.sectionFormWeight';
  static const sectionQuantity = 'catalogFlow.sectionQuantity';
  static const sectionProvenance = 'catalogFlow.sectionProvenance';
}

const catalogFlowMessages = <String, LocalizedMessage>{
  CatalogFlowL10n.showAll: LocalizedMessage(
    english: 'Show all ({count})',
    hindi: 'सभी दिखाएँ ({count})',
    gujarati: 'બધું બતાવો ({count})',
  ),
  CatalogFlowL10n.showLess: LocalizedMessage(
    english: 'Show less',
    hindi: 'कम दिखाएँ',
    gujarati: 'ઓછું બતાવો',
  ),
  CatalogFlowL10n.min: LocalizedMessage(
    english: 'Min',
    hindi: 'न्यूनतम',
    gujarati: 'ન્યૂનતમ',
  ),
  CatalogFlowL10n.max: LocalizedMessage(
    english: 'Max',
    hindi: 'अधिकतम',
    gujarati: 'મહત્તમ',
  ),
  CatalogFlowL10n.invalidRange: LocalizedMessage(
    english: 'Max should be above min',
    hindi: 'अधिकतम, न्यूनतम से अधिक होना चाहिए',
    gujarati: 'મહત્તમ, ન્યૂનતમ કરતાં વધુ હોવું જોઈએ',
  ),
  CatalogFlowL10n.errorTitle: LocalizedMessage(
    english: 'We couldn’t load this catalogue.',
    hindi: 'यह सूची लोड नहीं हो सकी।',
    gujarati: 'આ સૂચિ લોડ થઈ શકી નહીં.',
  ),
  CatalogFlowL10n.draftDiscarded: LocalizedMessage(
    english: 'Changes discarded',
    hindi: 'बदलाव हटाए गए',
    gujarati: 'ફેરફારો રદ થયા',
  ),
  CatalogFlowL10n.watchFilterEyebrow: LocalizedMessage(
    english: 'Watch filters',
    hindi: 'घड़ी फ़िल्टर',
    gujarati: 'ઘડિયાળ ફિલ્ટર',
  ),
  CatalogFlowL10n.watchFilterHeadline: LocalizedMessage(
    english: 'Refine your\nwatch search.',
    hindi: 'अपनी घड़ी की\nखोज सटीक करें।',
    gujarati: 'તમારી ઘડિયાળની\nશોધ ચોક્કસ કરો.',
  ),
  CatalogFlowL10n.watchFilterIntro: LocalizedMessage(
    english: 'Start with the brand, then narrow by style, size and detail.',
    hindi: 'ब्रांड से शुरू करें, फिर स्टाइल, साइज़ और विवरण से सटीक करें।',
    gujarati: 'બ્રાન્ડથી શરૂ કરો, પછી સ્ટાઇલ, સાઇઝ અને વિગતથી ચોક્કસ કરો.',
  ),
  CatalogFlowL10n.watchResults: LocalizedMessage(
    english: '{count} watches',
    hindi: '{count} घड़ियाँ',
    gujarati: '{count} ઘડિયાળો',
  ),
  CatalogFlowL10n.watchSort: LocalizedMessage(
    english: 'Sort watches',
    hindi: 'घड़ियाँ क्रमबद्ध करें',
    gujarati: 'ઘડિયાળો ગોઠવો',
  ),
  CatalogFlowL10n.brandEyebrow: LocalizedMessage(
    english: 'The maison',
    hindi: 'ब्रांड',
    gujarati: 'બ્રાન્ડ',
  ),
  CatalogFlowL10n.sectionBrandModel: LocalizedMessage(
    english: 'Brand & model',
    hindi: 'ब्रांड और मॉडल',
    gujarati: 'બ્રાન્ડ અને મોડેલ',
  ),
  CatalogFlowL10n.sectionStyle: LocalizedMessage(
    english: 'Style & wearer',
    hindi: 'स्टाइल और पहनने वाला',
    gujarati: 'સ્ટાઇલ અને પહેરનાર',
  ),
  CatalogFlowL10n.sectionPrice: LocalizedMessage(
    english: 'Price',
    hindi: 'कीमत',
    gujarati: 'કિંમત',
  ),
  CatalogFlowL10n.sectionMovement: LocalizedMessage(
    english: 'Movement & features',
    hindi: 'मूवमेंट और फ़ीचर',
    gujarati: 'મૂવમેન્ટ અને ફીચર',
  ),
  CatalogFlowL10n.sectionCase: LocalizedMessage(
    english: 'Case & bezel',
    hindi: 'केस और बेज़ल',
    gujarati: 'કેસ અને બેઝલ',
  ),
  CatalogFlowL10n.sectionDial: LocalizedMessage(
    english: 'Dial',
    hindi: 'डायल',
    gujarati: 'ડાયલ',
  ),
  CatalogFlowL10n.sectionStrap: LocalizedMessage(
    english: 'Strap, clasp & crown',
    hindi: 'स्ट्रैप, क्लैस्प और क्राउन',
    gujarati: 'સ્ટ્રેપ, ક્લાસ્પ અને ક્રાઉન',
  ),
  CatalogFlowL10n.sectionCondition: LocalizedMessage(
    english: 'Condition & papers',
    hindi: 'स्थिति और दस्तावेज़',
    gujarati: 'સ્થિતિ અને દસ્તાવેજ',
  ),
  CatalogFlowL10n.bullionFilterEyebrow: LocalizedMessage(
    english: 'Bullion filters',
    hindi: 'बुलियन फ़िल्टर',
    gujarati: 'બુલિયન ફિલ્ટર',
  ),
  CatalogFlowL10n.bullionFilterHeadline: LocalizedMessage(
    english: 'Refine your\nbullion search.',
    hindi: 'अपनी बुलियन\nखोज सटीक करें।',
    gujarati: 'તમારી બુલિયન\nશોધ ચોક્કસ કરો.',
  ),
  CatalogFlowL10n.bullionFilterIntro: LocalizedMessage(
    english:
        'Choose the form and weight, then set price, quantity and provenance.',
    hindi: 'रूप और वज़न चुनें, फिर कीमत, मात्रा और स्रोत तय करें।',
    gujarati: 'સ્વરૂપ અને વજન પસંદ કરો, પછી કિંમત, જથ્થો અને સ્રોત નક્કી કરો.',
  ),
  CatalogFlowL10n.bullionResults: LocalizedMessage(
    english: '{count} bars & coins',
    hindi: '{count} बार और सिक्के',
    gujarati: '{count} બાર અને સિક્કા',
  ),
  CatalogFlowL10n.bullionSort: LocalizedMessage(
    english: 'Sort bullion',
    hindi: 'बुलियन क्रमबद्ध करें',
    gujarati: 'બુલિયન ગોઠવો',
  ),
  CatalogFlowL10n.metal: LocalizedMessage(
    english: 'Metal',
    hindi: 'धातु',
    gujarati: 'ધાતુ',
  ),
  CatalogFlowL10n.sectionFormWeight: LocalizedMessage(
    english: 'Form & weight',
    hindi: 'रूप और वज़न',
    gujarati: 'સ્વરૂપ અને વજન',
  ),
  CatalogFlowL10n.sectionQuantity: LocalizedMessage(
    english: 'Quantity',
    hindi: 'मात्रा',
    gujarati: 'જથ્થો',
  ),
  CatalogFlowL10n.sectionProvenance: LocalizedMessage(
    english: 'Condition & provenance',
    hindi: 'स्थिति और स्रोत',
    gujarati: 'સ્થિતિ અને સ્રોત',
  ),
};
