import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'localized_message.dart';

/// Display labels for catalog filter/API enum values.
///
/// Keys are the canonical English values sent to and received from the API.
const catalogFilterValueLabels = <String, LocalizedMessage>{
  // Rough source
  'Canadian': LocalizedMessage(
    english: 'Canadian',
    hindi: 'कनाडाई',
    gujarati: 'કેનેડિયન',
  ),
  'Sight Holder': LocalizedMessage(
    english: 'Sight Holder',
    hindi: 'साइट होल्डर',
    gujarati: 'સાઇટ હોલ્ડર',
  ),
  'Russian': LocalizedMessage(
    english: 'Russian',
    hindi: 'रूसी',
    gujarati: 'રશિયન',
  ),
  'Rio Tinto': LocalizedMessage(
    english: 'Rio Tinto',
    hindi: 'रियो टिंटो',
    gujarati: 'રિયો ટિંટો',
  ),
  'Others': LocalizedMessage(
    english: 'Others',
    hindi: 'अन्य',
    gujarati: 'અન્ય',
  ),
  // Enhancement / treatment
  'None (Treatment)': LocalizedMessage(
    english: 'None (Treatment)',
    hindi: 'कोई नहीं (उपचार)',
    gujarati: 'કોઈ નહીં (ઉપચાર)',
  ),
  'HPHT (Treatment)': LocalizedMessage(
    english: 'HPHT (Treatment)',
    hindi: 'HPHT (उपचार)',
    gujarati: 'HPHT (ઉપચાર)',
  ),
  'Irradiation': LocalizedMessage(
    english: 'Irradiation',
    hindi: 'विकिरण',
    gujarati: 'વિકિરણ',
  ),
  'Fracture Filling': LocalizedMessage(
    english: 'Fracture Filling',
    hindi: 'दरार भरना',
    gujarati: 'ફ્રેક્ચર ભરણ',
  ),
  'Laser Drilling': LocalizedMessage(
    english: 'Laser Drilling',
    hindi: 'लेज़र ड्रिलिंग',
    gujarati: 'લેસર ડ્રિલિંગ',
  ),
  'Surface Coating': LocalizedMessage(
    english: 'Surface Coating',
    hindi: 'सतह की परत',
    gujarati: 'સપાટી કોટિંગ',
  ),
  // Fluorescence color
  'None': LocalizedMessage(
    english: 'None',
    hindi: 'कोई नहीं',
    gujarati: 'કોઈ નહીં',
  ),
  'Blue': LocalizedMessage(english: 'Blue', hindi: 'नीला', gujarati: 'વાદળી'),
  'Yellow': LocalizedMessage(
    english: 'Yellow',
    hindi: 'पीला',
    gujarati: 'પીળો',
  ),
  'White': LocalizedMessage(english: 'White', hindi: 'सफ़ेद', gujarati: 'સફેદ'),
  'Green': LocalizedMessage(english: 'Green', hindi: 'हरा', gujarati: 'લીલો'),
  'Orange': LocalizedMessage(
    english: 'Orange',
    hindi: 'नारंगी',
    gujarati: 'નારંગી',
  ),
  'Red': LocalizedMessage(english: 'Red', hindi: 'लाल', gujarati: 'લાલ'),
  // Milkiness
  'Slightly': LocalizedMessage(
    english: 'Slightly',
    hindi: 'हल्का',
    gujarati: 'થોડું',
  ),
  'Moderately': LocalizedMessage(
    english: 'Moderately',
    hindi: 'मध्यम',
    gujarati: 'મધ્યમ',
  ),
  'Strongly': LocalizedMessage(
    english: 'Strongly',
    hindi: 'तीव्र',
    gujarati: 'તીવ્ર',
  ),
  'Severely': LocalizedMessage(
    english: 'Severely',
    hindi: 'अत्यधिक',
    gujarati: 'ગંભીર',
  ),
  // Fluorescence intensity
  'Faint': LocalizedMessage(
    english: 'Faint',
    hindi: 'हल्का',
    gujarati: 'હળવું',
  ),
  'Medium': LocalizedMessage(
    english: 'Medium',
    hindi: 'मध्यम',
    gujarati: 'મધ્યમ',
  ),
  'Strong': LocalizedMessage(
    english: 'Strong',
    hindi: 'तीव्र',
    gujarati: 'તીવ્ર',
  ),
  'Very Strong': LocalizedMessage(
    english: 'Very Strong',
    hindi: 'बहुत तीव्र',
    gujarati: 'ખૂબ તીવ્ર',
  ),
  // Diamond shapes
  'Round': LocalizedMessage(english: 'Round', hindi: 'गोल', gujarati: 'ગોળ'),
  'Cushion': LocalizedMessage(
    english: 'Cushion',
    hindi: 'कुशन',
    gujarati: 'કુશન',
  ),
  'Emerald': LocalizedMessage(
    english: 'Emerald',
    hindi: 'एमराल्ड',
    gujarati: 'એમરાલ્ડ',
  ),
  'Pear': LocalizedMessage(english: 'Pear', hindi: 'नाशपाती', gujarati: 'પિઅર'),
  'Oval': LocalizedMessage(
    english: 'Oval',
    hindi: 'अंडाकार',
    gujarati: 'અંડાકાર',
  ),
  'Princess': LocalizedMessage(
    english: 'Princess',
    hindi: 'प्रिंसेस',
    gujarati: 'પ્રિન્સેસ',
  ),
  'Marquise': LocalizedMessage(
    english: 'Marquise',
    hindi: 'मार्कीज़',
    gujarati: 'માર્કીઝ',
  ),
  'Heart': LocalizedMessage(english: 'Heart', hindi: 'हृदय', gujarati: 'હૃદય'),
  'Radiant': LocalizedMessage(
    english: 'Radiant',
    hindi: 'रेडिएंट',
    gujarati: 'રેડિઅન્ટ',
  ),
  'Asscher': LocalizedMessage(
    english: 'Asscher',
    hindi: 'अशर',
    gujarati: 'અસ્ચર',
  ),
  'Trilliant': LocalizedMessage(
    english: 'Trilliant',
    hindi: 'ट्रिलियंट',
    gujarati: 'ટ્રિલિયન્ટ',
  ),
  'Baguette': LocalizedMessage(
    english: 'Baguette',
    hindi: 'बैगेट',
    gujarati: 'બેગેટ',
  ),
  'Flanders': LocalizedMessage(
    english: 'Flanders',
    hindi: 'फ्लैंडर्स',
    gujarati: 'ફ્લેન્ડર્સ',
  ),
  'Shield': LocalizedMessage(english: 'Shield', hindi: 'ढाल', gujarati: 'ઢાલ'),
  'Polki': LocalizedMessage(
    english: 'Polki',
    hindi: 'पोल्की',
    gujarati: 'પોલકી',
  ),
  'Rose Cut': LocalizedMessage(
    english: 'Rose Cut',
    hindi: 'रोज़ कट',
    gujarati: 'રોઝ કટ',
  ),
  'Tapered Baguette': LocalizedMessage(
    english: 'Tapered Baguette',
    hindi: 'टेपर्ड बैगेट',
    gujarati: 'ટેપર્ડ બેગેટ',
  ),
  'Trapezoid': LocalizedMessage(
    english: 'Trapezoid',
    hindi: 'समलंब',
    gujarati: 'ટ્રેપીઝોઇડ',
  ),
  'Half Moon': LocalizedMessage(
    english: 'Half Moon',
    hindi: 'अर्धचंद्र',
    gujarati: 'અર્ધચંદ્ર',
  ),
  'Bullet': LocalizedMessage(
    english: 'Bullet',
    hindi: 'बुलेट',
    gujarati: 'બુલેટ',
  ),
  'Lozenge': LocalizedMessage(
    english: 'Lozenge',
    hindi: 'लोजेंज',
    gujarati: 'લોઝેન્જ',
  ),
};

/// Resolves a catalog filter/API value for display without changing payloads.
String localizedCatalogFilterValue(BuildContext context, String value) {
  final message = catalogFilterValueLabels[value];
  if (message == null) return value;
  return message.forLanguage(AppLocalizations.of(context).locale.languageCode);
}

extension CatalogFilterValueContext on BuildContext {
  String trCatalogValue(String value) =>
      localizedCatalogFilterValue(this, value);
}
