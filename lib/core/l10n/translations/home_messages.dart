import '../localized_message.dart';

/// Stable keys for the home experience copy.
abstract final class HomeL10n {
  static const heroTitleLine1 = 'home.heroTitleLine1';
  static const heroTitleLine2 = 'home.heroTitleLine2';
  static const searchPrefix = 'home.searchPrefix';
  static const searchPlaceholder = 'home.searchPlaceholder';
  static const exploreCollections = 'home.exploreCollections';
  static const dragHint = 'home.dragHint';
  static const closeSearch = 'home.closeSearch';
  static const searchFieldHint = 'home.searchFieldHint';
  static const searchModeCatalog = 'home.searchModeCatalog';
  static const aiMode = 'home.aiMode';
  static const aiModeHint = 'home.aiModeHint';
  static const aiModeEyebrow = 'home.aiModeEyebrow';
  static const aiModeBody = 'home.aiModeBody';
  static const aiModeAsk = 'home.aiModeAsk';
  static const aiModePromptDiamonds = 'home.aiModePromptDiamonds';
  static const aiModePromptGemstones = 'home.aiModePromptGemstones';
  static const aiModePromptJewellery = 'home.aiModePromptJewellery';
  static const aiModePromptWatches = 'home.aiModePromptWatches';
  static const aiModePromptBullion = 'home.aiModePromptBullion';
  static const collectionsEyebrow = 'home.collectionsEyebrow';
  static const collectionsTitle = 'home.collectionsTitle';
  static const orders = 'home.orders';
  static const wishlist = 'home.wishlist';
  static const myBids = 'home.myBids';
  static const wallet = 'home.wallet';
  static const dashboard = 'home.dashboard';
  static const auctionsTitle = 'home.auctionsTitle';
  static const currentBid = 'home.currentBid';
  static const endsIn = 'home.endsIn';
  static const ended = 'home.ended';
  static const live = 'home.live';
  static const aiSearchTitle = 'home.aiSearchTitle';
  static const aiSearchBody = 'home.aiSearchBody';
  static const aiSearchPrompt1 = 'home.aiSearchPrompt1';
  static const aiSearchPrompt2 = 'home.aiSearchPrompt2';
  static const aiSearchPrompt3 = 'home.aiSearchPrompt3';
  static const aiSearchCta = 'home.aiSearchCta';
  static const promiseTitle = 'home.promiseTitle';
  static const pillarCertifiedTitle = 'home.pillarCertifiedTitle';
  static const pillarCertifiedBody = 'home.pillarCertifiedBody';
  static const pillarSellersTitle = 'home.pillarSellersTitle';
  static const pillarSellersBody = 'home.pillarSellersBody';
  static const pillarPaymentsTitle = 'home.pillarPaymentsTitle';
  static const pillarPaymentsBody = 'home.pillarPaymentsBody';
  static const appearance = 'home.appearance';
  static const light = 'home.light';
  static const dark = 'home.dark';
  static const rights = 'home.rights';
  static const notifications = 'home.notifications';
  static const auctions = 'home.auctions';
  static const formGlyph = 'home.formGlyph';
  static const formGem = 'home.formGem';
  static const formGalaxy = 'home.formGalaxy';
}

const homeMessages = <String, LocalizedMessage>{
  HomeL10n.heroTitleLine1: LocalizedMessage(
    english: 'Rare beauty,',
    hindi: 'दुर्लभ सौंदर्य,',
    gujarati: 'દુર્લભ સૌંદર્ય,',
  ),
  HomeL10n.heroTitleLine2: LocalizedMessage(
    english: 'honestly traded.',
    hindi: 'पूरी ईमानदारी से।',
    gujarati: 'પૂરી પ્રામાણિકતાથી.',
  ),
  HomeL10n.searchPrefix: LocalizedMessage(
    english: 'Search',
    hindi: 'खोजें',
    gujarati: 'શોધો',
  ),
  HomeL10n.searchPlaceholder: LocalizedMessage(
    english: 'Search by shape, carat, brand or stone',
    hindi: 'आकार, कैरेट, ब्रांड या रत्न से खोजें',
    gujarati: 'આકાર, કેરેટ, બ્રાન્ડ અથવા રત્નથી શોધો',
  ),
  HomeL10n.exploreCollections: LocalizedMessage(
    english: 'Explore the collections',
    hindi: 'संग्रह देखें',
    gujarati: 'સંગ્રહ જુઓ',
  ),
  HomeL10n.dragHint: LocalizedMessage(
    english: 'Drag to orbit 360° · touch to scatter',
    hindi: '360° घुमाने के लिए खींचें · बिखेरने के लिए छुएँ',
    gujarati: '360° ફેરવવા ખેંચો · વિખેરવા સ્પર્શ કરો',
  ),
  HomeL10n.searchFieldHint: LocalizedMessage(
    english: 'Search...',
    hindi: 'खोजें...',
    gujarati: 'શોધો...',
  ),
  HomeL10n.searchModeCatalog: LocalizedMessage(
    english: 'Search',
    hindi: 'खोज',
    gujarati: 'શોધ',
  ),
  HomeL10n.aiMode: LocalizedMessage(
    english: 'AI Mode',
    hindi: 'AI मोड',
    gujarati: 'AI મોડ',
  ),
  HomeL10n.aiModeHint: LocalizedMessage(
    english: 'Describe what you are looking for...',
    hindi: 'बताइए आप क्या खोज रहे हैं...',
    gujarati: 'તમે શું શોધી રહ્યા છો તે જણાવો...',
  ),
  HomeL10n.aiModeEyebrow: LocalizedMessage(
    english: 'Search with Gem AI',
    hindi: 'Gem AI से खोजें',
    gujarati: 'Gem AI થી શોધો',
  ),
  HomeL10n.aiModeBody: LocalizedMessage(
    english:
        'Ask in your own words. Gem AI finds matching diamonds, gemstones, jewellery, watches and bullion.',
    hindi:
        'अपने शब्दों में पूछें। Gem AI मेल खाते हीरे, रत्न, आभूषण, घड़ियाँ और बुलियन ढूँढता है।',
    gujarati:
        'તમારા શબ્દોમાં પૂછો. Gem AI મેળ ખાતા હીરા, રત્નો, ઝવેરાત, ઘડિયાળો અને બુલિયન શોધે છે.',
  ),
  HomeL10n.aiModeAsk: LocalizedMessage(
    english: 'Ask Gem AI',
    hindi: 'Gem AI से पूछें',
    gujarati: 'Gem AI ને પૂછો',
  ),
  HomeL10n.aiModePromptDiamonds: LocalizedMessage(
    english: '1 carat round diamond, D–F colour, VVS clarity',
    hindi: '1 कैरेट राउंड हीरा, D–F रंग, VVS क्लैरिटी',
    gujarati: '1 કેરેટ રાઉન્ડ હીરો, D–F રંગ, VVS ક્લેરિટી',
  ),
  HomeL10n.aiModePromptGemstones: LocalizedMessage(
    english: 'Untreated ruby around 2 carats',
    hindi: 'लगभग 2 कैरेट का अनुपचारित माणिक',
    gujarati: 'આશરે 2 કેરેટનું અનટ્રીટેડ માણેક',
  ),
  HomeL10n.aiModePromptJewellery: LocalizedMessage(
    english: 'Platinum engagement ring with an oval diamond',
    hindi: 'ओवल हीरे वाली प्लैटिनम सगाई की अंगूठी',
    gujarati: 'ઓવલ હીરાવાળી પ્લેટિનમ સગાઈની વીંટી',
  ),
  HomeL10n.aiModePromptWatches: LocalizedMessage(
    english: 'Steel Rolex Submariner, recent year',
    hindi: 'स्टील रोलेक्स सबमरीनर, हाल का वर्ष',
    gujarati: 'સ્ટીલ રોલેક્સ સબમરીનર, તાજેતરનું વર્ષ',
  ),
  HomeL10n.aiModePromptBullion: LocalizedMessage(
    english: '24k gold bars of 100 grams',
    hindi: '100 ग्राम की 24 कैरेट सोने की ईंटें',
    gujarati: '100 ગ્રામના 24 કેરેટ સોનાના બાર',
  ),
  HomeL10n.closeSearch: LocalizedMessage(
    english: 'Close search',
    hindi: 'खोज बंद करें',
    gujarati: 'શોધ બંધ કરો',
  ),
  HomeL10n.collectionsEyebrow: LocalizedMessage(
    english: 'The collections',
    hindi: 'संग्रह',
    gujarati: 'સંગ્રહ',
  ),
  HomeL10n.collectionsTitle: LocalizedMessage(
    english: 'Six worlds of the rare.',
    hindi: 'दुर्लभता के छह संसार।',
    gujarati: 'દુર્લભતાના છ વિશ્વ.',
  ),
  HomeL10n.orders: LocalizedMessage(
    english: 'Orders',
    hindi: 'ऑर्डर',
    gujarati: 'ઓર્ડર',
  ),
  HomeL10n.wishlist: LocalizedMessage(
    english: 'Wishlist',
    hindi: 'विशलिस्ट',
    gujarati: 'વિશલિસ્ટ',
  ),
  HomeL10n.myBids: LocalizedMessage(
    english: 'My bids',
    hindi: 'मेरी बोलियाँ',
    gujarati: 'મારી બોલીઓ',
  ),
  HomeL10n.wallet: LocalizedMessage(
    english: 'Wallet',
    hindi: 'वॉलेट',
    gujarati: 'વૉલેટ',
  ),
  HomeL10n.dashboard: LocalizedMessage(
    english: 'Dashboard',
    hindi: 'डैशबोर्ड',
    gujarati: 'ડેશબોર્ડ',
  ),
  HomeL10n.auctionsTitle: LocalizedMessage(
    english: 'Auctions in the room.',
    hindi: 'चल रही नीलामियाँ।',
    gujarati: 'ચાલુ હરાજીઓ.',
  ),
  HomeL10n.currentBid: LocalizedMessage(
    english: 'Current bid',
    hindi: 'मौजूदा बोली',
    gujarati: 'હાલની બોલી',
  ),
  HomeL10n.endsIn: LocalizedMessage(
    english: 'Ends in',
    hindi: 'समाप्ति में',
    gujarati: 'પૂર્ણ થવામાં',
  ),
  HomeL10n.ended: LocalizedMessage(
    english: 'Closing',
    hindi: 'समाप्त हो रही है',
    gujarati: 'પૂર્ણ થઈ રહી છે',
  ),
  HomeL10n.live: LocalizedMessage(
    english: 'Live',
    hindi: 'लाइव',
    gujarati: 'લાઇવ',
  ),
  HomeL10n.aiSearchTitle: LocalizedMessage(
    english: 'Describe it.\nWe will find it.',
    hindi: 'बताइए।\nहम ढूँढ लेंगे।',
    gujarati: 'વર્ણન કરો.\nઅમે શોધી આપીશું.',
  ),
  HomeL10n.aiSearchBody: LocalizedMessage(
    english: 'Ask in your own words — budget, occasion, cut or carat.',
    hindi: 'अपने शब्दों में पूछें — बजट, अवसर, कट या कैरेट।',
    gujarati: 'તમારા શબ્દોમાં પૂછો — બજેટ, પ્રસંગ, કટ કે કેરેટ.',
  ),
  HomeL10n.aiSearchPrompt1: LocalizedMessage(
    english: 'An oval diamond near 1.5 ct, G colour, VS1',
    hindi: 'लगभग 1.5 कैरेट का ओवल हीरा, G रंग, VS1',
    gujarati: 'આશરે 1.5 કેરેટનો ઓવલ હીરો, G રંગ, VS1',
  ),
  HomeL10n.aiSearchPrompt2: LocalizedMessage(
    english: 'A Colombian emerald for an anniversary ring',
    hindi: 'सालगिरह की अंगूठी के लिए कोलंबियाई पन्ना',
    gujarati: 'વર્ષગાંઠની વીંટી માટે કોલંબિયન પન્ના',
  ),
  HomeL10n.aiSearchPrompt3: LocalizedMessage(
    english: 'Lab-grown studs under a set budget',
    hindi: 'तय बजट में लैब-ग्रोन स्टड्स',
    gujarati: 'નિશ્ચિત બજેટમાં લેબ-ગ્રોન સ્ટડ્સ',
  ),
  HomeL10n.aiSearchCta: LocalizedMessage(
    english: 'Ask Gem AI',
    hindi: 'जेम AI से पूछें',
    gujarati: 'જેમ AI ને પૂછો',
  ),
  HomeL10n.promiseTitle: LocalizedMessage(
    english: 'Trust, cut\nto perfection.',
    hindi: 'भरोसा,\nबेहतरीन तराश में।',
    gujarati: 'વિશ્વાસ,\nશ્રેષ્ઠ ઘાટમાં.',
  ),
  HomeL10n.pillarCertifiedTitle: LocalizedMessage(
    english: 'Certified stones',
    hindi: 'प्रमाणित रत्न',
    gujarati: 'પ્રમાણિત રત્નો',
  ),
  HomeL10n.pillarCertifiedBody: LocalizedMessage(
    english: 'Graded stones with certificates you can check before you buy.',
    hindi:
        'ग्रेड किए गए रत्न, जिनके प्रमाणपत्र आप खरीदने से पहले देख सकते हैं।',
    gujarati: 'ગ્રેડ કરેલા રત્નો, જેના પ્રમાણપત્રો તમે ખરીદતા પહેલાં જોઈ શકો.',
  ),
  HomeL10n.pillarSellersTitle: LocalizedMessage(
    english: 'Transparent sellers',
    hindi: 'पारदर्शी विक्रेता',
    gujarati: 'પારદર્શક વિક્રેતાઓ',
  ),
  HomeL10n.pillarSellersBody: LocalizedMessage(
    english: 'Every listing traces back to a verified business profile.',
    hindi: 'हर लिस्टिंग एक सत्यापित व्यावसायिक प्रोफ़ाइल से जुड़ी है।',
    gujarati: 'દરેક લિસ્ટિંગ ચકાસાયેલ વ્યવસાય પ્રોફાઇલ સાથે જોડાયેલ છે.',
  ),
  HomeL10n.pillarPaymentsTitle: LocalizedMessage(
    english: 'Protected payments',
    hindi: 'सुरक्षित भुगतान',
    gujarati: 'સુરક્ષિત ચુકવણી',
  ),
  HomeL10n.pillarPaymentsBody: LocalizedMessage(
    english: 'Secure checkout and dedicated support at every step.',
    hindi: 'सुरक्षित चेकआउट और हर कदम पर समर्पित सहायता।',
    gujarati: 'સુરક્ષિત ચેકઆઉટ અને દરેક પગલે સમર્પિત સહાય.',
  ),
  HomeL10n.appearance: LocalizedMessage(
    english: 'Appearance',
    hindi: 'रूप',
    gujarati: 'દેખાવ',
  ),
  HomeL10n.light: LocalizedMessage(
    english: 'Light',
    hindi: 'लाइट',
    gujarati: 'લાઇટ',
  ),
  HomeL10n.dark: LocalizedMessage(
    english: 'Dark',
    hindi: 'डार्क',
    gujarati: 'ડાર્ક',
  ),
  HomeL10n.rights: LocalizedMessage(
    english: '© {year} GemWorld. All rights reserved.',
    hindi: '© {year} जेमवर्ल्ड. सर्वाधिकार सुरक्षित।',
    gujarati: '© {year} જેમવર્લ્ડ. સર્વ હક સુરક્ષિત.',
  ),
  HomeL10n.notifications: LocalizedMessage(
    english: 'Notifications',
    hindi: 'सूचनाएँ',
    gujarati: 'સૂચનાઓ',
  ),
  HomeL10n.auctions: LocalizedMessage(
    english: 'Auctions',
    hindi: 'नीलामी',
    gujarati: 'હરાજી',
  ),
  HomeL10n.formGlyph: LocalizedMessage(
    english: 'The GemWorld mark',
    hindi: 'जेमवर्ल्ड की पहचान',
    gujarati: 'જેમવર્લ્ડની ઓળખ',
  ),
  HomeL10n.formGem: LocalizedMessage(
    english: '57 facets of light',
    hindi: 'प्रकाश के 57 पहलू',
    gujarati: 'પ્રકાશના 57 પાસાં',
  ),
  HomeL10n.formGalaxy: LocalizedMessage(
    english: 'Every gem began as stardust',
    hindi: 'हर रत्न की शुरुआत तारों की धूल से हुई',
    gujarati: 'દરેક રત્નની શરૂઆત તારાઓની ધૂળથી થઈ',
  ),
};
