import '../localized_message.dart';

/// Copy for Interested buyers: the seller menu entry, the buyer's privacy
/// switch and the cart notice. English follows the website wording.
abstract final class InterestedBuyersL10n {
  static const menu = 'interestedBuyers.menu';
  static const privacyGroup = 'interestedBuyers.privacyGroup';
  static const settingTitle = 'interestedBuyers.settingTitle';
  static const settingBody = 'interestedBuyers.settingBody';
  static const settingSaveFailed = 'interestedBuyers.settingSaveFailed';
  static const cartNotice = 'interestedBuyers.cartNotice';
  static const manage = 'interestedBuyers.manage';
}

const interestedBuyersMessages = <String, LocalizedMessage>{
  InterestedBuyersL10n.menu: LocalizedMessage(
    english: 'Interested buyers',
    hindi: 'रुचि रखने वाले खरीदार',
    gujarati: 'રસ ધરાવતા ખરીદદારો',
  ),
  InterestedBuyersL10n.privacyGroup: LocalizedMessage(
    english: 'Privacy',
    hindi: 'गोपनीयता',
    gujarati: 'ગોપનીયતા',
  ),
  InterestedBuyersL10n.settingTitle: LocalizedMessage(
    english: 'Seller offers on my cart',
    hindi: 'मेरे कार्ट पर विक्रेता के ऑफ़र',
    gujarati: 'મારા કાર્ટ પર વિક્રેતાની ઑફર',
  ),
  InterestedBuyersL10n.settingBody: LocalizedMessage(
    english:
        'One hour after you add an item, its seller can see your name and '
        'that item, and can message you or send a private price.',
    hindi:
        'आइटम जोड़ने के एक घंटे बाद, उसका विक्रेता आपका नाम और वह आइटम देख '
        'सकता है, और आपको संदेश या निजी कीमत भेज सकता है।',
    gujarati:
        'આઇટમ ઉમેર્યાના એક કલાક પછી, તેનો વિક્રેતા તમારું નામ અને તે આઇટમ '
        'જોઈ શકે છે, અને તમને સંદેશ અથવા ખાનગી કિંમત મોકલી શકે છે.',
  ),
  InterestedBuyersL10n.settingSaveFailed: LocalizedMessage(
    english: 'Could not save this setting. Please try again.',
    hindi: 'यह सेटिंग सहेजी नहीं जा सकी। कृपया फिर से प्रयास करें।',
    gujarati: 'આ સેટિંગ સાચવી શકાઈ નહીં. કૃપા કરીને ફરી પ્રયાસ કરો.',
  ),
  InterestedBuyersL10n.cartNotice: LocalizedMessage(
    english:
        'After 1 hour, sellers can see your name and their item in your '
        'cart, and may message you or send a private price.',
    hindi:
        '1 घंटे बाद, विक्रेता आपका नाम और आपके कार्ट में अपना आइटम देख सकते '
        'हैं, और आपको संदेश या निजी कीमत भेज सकते हैं।',
    gujarati:
        '1 કલાક પછી, વિક્રેતાઓ તમારું નામ અને તમારા કાર્ટમાં તેમની આઇટમ જોઈ '
        'શકે છે, અને તમને સંદેશ અથવા ખાનગી કિંમત મોકલી શકે છે.',
  ),
  InterestedBuyersL10n.manage: LocalizedMessage(
    english: 'Manage',
    hindi: 'प्रबंधित करें',
    gujarati: 'મેનેજ કરો',
  ),
};
