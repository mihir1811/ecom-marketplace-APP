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
  static const aiModeAsk = 'home.aiModeAsk';
  static const aiModePromptDiamonds = 'home.aiModePromptDiamonds';
  static const aiModePromptGemstones = 'home.aiModePromptGemstones';
  static const aiModePromptJewellery = 'home.aiModePromptJewellery';
  static const aiModePromptWatches = 'home.aiModePromptWatches';
  static const aiModePromptBullion = 'home.aiModePromptBullion';
  static const recentSearchesEyebrow = 'home.recentSearchesEyebrow';
  static const removeRecentSearch = 'home.removeRecentSearch';
  static const searchNoteDiamonds = 'home.searchNoteDiamonds';
  static const searchNoteLab = 'home.searchNoteLab';
  static const searchNoteGemstones = 'home.searchNoteGemstones';
  static const searchNoteJewellery = 'home.searchNoteJewellery';
  static const searchNoteWatches = 'home.searchNoteWatches';
  static const searchNoteBullion = 'home.searchNoteBullion';
  static const searchSuggestEyebrow = 'home.searchSuggestEyebrow';
  static const searchSuggestDiamonds = 'home.searchSuggestDiamonds';
  static const searchSuggestGemstones = 'home.searchSuggestGemstones';
  static const searchSuggestJewellery = 'home.searchSuggestJewellery';
  static const searchSuggestWatches = 'home.searchSuggestWatches';
  static const searchSuggestBullion = 'home.searchSuggestBullion';
  static const searchTipTitle = 'home.searchTipTitle';
  static const searchTipBody = 'home.searchTipBody';
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
  static const saleShop = 'home.saleShop';
  static const saleDiwaliTag = 'home.saleDiwaliTag';
  static const saleDiwaliTitle = 'home.saleDiwaliTitle';
  static const saleDiwaliBody = 'home.saleDiwaliBody';
  static const saleDhanterasTag = 'home.saleDhanterasTag';
  static const saleDhanterasTitle = 'home.saleDhanterasTitle';
  static const saleDhanterasBody = 'home.saleDhanterasBody';
  static const saleWeddingTag = 'home.saleWeddingTag';
  static const saleWeddingTitle = 'home.saleWeddingTitle';
  static const saleWeddingBody = 'home.saleWeddingBody';
  static const saleGemTag = 'home.saleGemTag';
  static const saleGemTitle = 'home.saleGemTitle';
  static const saleGemBody = 'home.saleGemBody';
  static const saleGoldTag = 'home.saleGoldTag';
  static const saleGoldTitle = 'home.saleGoldTitle';
  static const saleGoldBody = 'home.saleGoldBody';
  // GemWorld info banners, shown on the hero while no paid banner is live.
  static const infoAboutTitle = 'home.infoAboutTitle';
  static const infoAboutBody = 'home.infoAboutBody';
  static const infoAboutAction = 'home.infoAboutAction';
  static const infoCertifiedTitle = 'home.infoCertifiedTitle';
  static const infoCertifiedBody = 'home.infoCertifiedBody';
  static const infoCertifiedAction = 'home.infoCertifiedAction';
  static const infoLiveTitle = 'home.infoLiveTitle';
  static const infoLiveBody = 'home.infoLiveBody';
  static const infoLiveAction = 'home.infoLiveAction';
  static const infoLearnTitle = 'home.infoLearnTitle';
  static const infoLearnBody = 'home.infoLearnBody';
  static const infoLearnAction = 'home.infoLearnAction';
  static const infoSecureTitle = 'home.infoSecureTitle';
  static const infoSecureBody = 'home.infoSecureBody';
  static const infoSecureAction = 'home.infoSecureAction';
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
  HomeL10n.recentSearchesEyebrow: LocalizedMessage(
    english: 'Recent searches',
    hindi: 'हाल की खोजें',
    gujarati: 'તાજેતરની શોધો',
  ),
  HomeL10n.removeRecentSearch: LocalizedMessage(
    english: 'Remove from recent searches',
    hindi: 'हाल की खोजों से हटाएँ',
    gujarati: 'તાજેતરની શોધોમાંથી દૂર કરો',
  ),
  HomeL10n.searchNoteDiamonds: LocalizedMessage(
    english: 'Certified, graded natural stones',
    hindi: 'प्रमाणित, ग्रेड किए गए प्राकृतिक हीरे',
    gujarati: 'પ્રમાણિત, ગ્રેડ કરેલા કુદરતી હીરા',
  ),
  HomeL10n.searchNoteLab: LocalizedMessage(
    english: 'Lab-grown diamonds with full grading',
    hindi: 'पूरी ग्रेडिंग के साथ लैब-ग्रोन हीरे',
    gujarati: 'સંપૂર્ણ ગ્રેડિંગ સાથે લેબ-ગ્રોન હીરા',
  ),
  HomeL10n.searchNoteGemstones: LocalizedMessage(
    english: 'Sapphires, rubies, emeralds and more',
    hindi: 'नीलम, माणिक, पन्ना और भी बहुत कुछ',
    gujarati: 'નીલમ, માણેક, પન્ના અને વધુ',
  ),
  HomeL10n.searchNoteJewellery: LocalizedMessage(
    english: 'Rings, necklaces and fine pieces',
    hindi: 'अंगूठियाँ, हार और बेहतरीन आभूषण',
    gujarati: 'વીંટી, હાર અને ઉત્તમ ઘરેણાં',
  ),
  HomeL10n.searchNoteWatches: LocalizedMessage(
    english: 'Luxury timepieces from trusted sellers',
    hindi: 'भरोसेमंद विक्रेताओं की लग्ज़री घड़ियाँ',
    gujarati: 'વિશ્વસનીય વેચાણકર્તાઓની લક્ઝરી ઘડિયાળો',
  ),
  HomeL10n.searchNoteBullion: LocalizedMessage(
    english: 'Gold and silver coins and bars',
    hindi: 'सोने और चाँदी के सिक्के और बार',
    gujarati: 'સોના અને ચાંદીના સિક્કા અને બાર',
  ),
  HomeL10n.searchSuggestEyebrow: LocalizedMessage(
    english: 'Try searching',
    hindi: 'यह खोजकर देखें',
    gujarati: 'આ શોધી જુઓ',
  ),
  HomeL10n.searchSuggestDiamonds: LocalizedMessage(
    english: 'Round diamond 1 carat',
    hindi: 'राउंड हीरा 1 कैरेट',
    gujarati: 'રાઉન્ડ હીરો 1 કેરેટ',
  ),
  HomeL10n.searchSuggestGemstones: LocalizedMessage(
    english: 'Blue sapphire',
    hindi: 'नीलम',
    gujarati: 'નીલમ',
  ),
  HomeL10n.searchSuggestJewellery: LocalizedMessage(
    english: 'Diamond engagement ring',
    hindi: 'हीरे की सगाई की अंगूठी',
    gujarati: 'હીરાની સગાઈની વીંટી',
  ),
  HomeL10n.searchSuggestWatches: LocalizedMessage(
    english: 'Automatic steel watch',
    hindi: 'ऑटोमैटिक स्टील घड़ी',
    gujarati: 'ઓટોમેટિક સ્ટીલ ઘડિયાળ',
  ),
  HomeL10n.searchSuggestBullion: LocalizedMessage(
    english: '24k gold coin',
    hindi: '24 कैरेट सोने का सिक्का',
    gujarati: '24 કેરેટ સોનાનો સિક્કો',
  ),
  HomeL10n.searchTipTitle: LocalizedMessage(
    english: 'Have a stock or certificate number?',
    hindi: 'स्टॉक या सर्टिफिकेट नंबर है?',
    gujarati: 'સ્ટોક અથવા સર્ટિફિકેટ નંબર છે?',
  ),
  HomeL10n.searchTipBody: LocalizedMessage(
    english: 'Type it above to go straight to the piece.',
    hindi: 'सीधे उस पीस तक जाने के लिए इसे ऊपर लिखें।',
    gujarati: 'સીધા તે પીસ સુધી જવા માટે તેને ઉપર લખો.',
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
  HomeL10n.saleShop: LocalizedMessage(
    english: 'Shop now',
    hindi: 'अभी खरीदें',
    gujarati: 'હમણાં ખરીદો',
  ),
  HomeL10n.saleDiwaliTag: LocalizedMessage(
    english: 'Diwali sale',
    hindi: 'दिवाली सेल',
    gujarati: 'દિવાળી સેલ',
  ),
  HomeL10n.saleDiwaliTitle: LocalizedMessage(
    english: 'Up to 25% off',
    hindi: '25% तक की छूट',
    gujarati: '25% સુધીની છૂટ',
  ),
  HomeL10n.saleDiwaliBody: LocalizedMessage(
    english: 'Certified natural diamond jewellery',
    hindi: 'प्रमाणित प्राकृतिक हीरे के गहने',
    gujarati: 'પ્રમાણિત કુદરતી હીરાના દાગીના',
  ),
  HomeL10n.saleDhanterasTag: LocalizedMessage(
    english: 'Dhanteras special',
    hindi: 'धनतेरस स्पेशल',
    gujarati: 'ધનતેરસ સ્પેશિયલ',
  ),
  HomeL10n.saleDhanterasTitle: LocalizedMessage(
    english: '0% making charges',
    hindi: '0% मेकिंग चार्ज',
    gujarati: '0% મેકિંગ ચાર્જ',
  ),
  HomeL10n.saleDhanterasBody: LocalizedMessage(
    english: 'On gold coins and bars',
    hindi: 'सोने के सिक्कों और बार पर',
    gujarati: 'સોનાના સિક્કા અને બાર પર',
  ),
  HomeL10n.saleWeddingTag: LocalizedMessage(
    english: 'Wedding season',
    hindi: 'शादी का सीज़न',
    gujarati: 'લગ્નની સીઝન',
  ),
  HomeL10n.saleWeddingTitle: LocalizedMessage(
    english: 'Flat 20% off',
    hindi: 'सीधे 20% की छूट',
    gujarati: 'સીધી 20% છૂટ',
  ),
  HomeL10n.saleWeddingBody: LocalizedMessage(
    english: 'Bridal jewellery sets',
    hindi: 'दुल्हन के गहनों के सेट',
    gujarati: 'દુલ્હનના દાગીનાના સેટ',
  ),
  HomeL10n.saleGemTag: LocalizedMessage(
    english: 'Festive gems',
    hindi: 'त्योहारी रत्न',
    gujarati: 'તહેવારના રત્નો',
  ),
  HomeL10n.saleGemTitle: LocalizedMessage(
    english: 'Up to 30% off',
    hindi: '30% तक की छूट',
    gujarati: '30% સુધીની છૂટ',
  ),
  HomeL10n.saleGemBody: LocalizedMessage(
    english: 'Sapphires, rubies and emeralds',
    hindi: 'नीलम, माणिक और पन्ना',
    gujarati: 'નીલમ, માણેક અને પન્ના',
  ),
  HomeL10n.saleGoldTag: LocalizedMessage(
    english: 'Festive offer',
    hindi: 'त्योहारी ऑफ़र',
    gujarati: 'તહેવારની ઓફર',
  ),
  HomeL10n.saleGoldTitle: LocalizedMessage(
    english: 'Extra 10% off',
    hindi: 'अतिरिक्त 10% छूट',
    gujarati: 'વધારાની 10% છૂટ',
  ),
  HomeL10n.saleGoldBody: LocalizedMessage(
    english: 'Gold and diamond necklaces',
    hindi: 'सोने और हीरे के हार',
    gujarati: 'સોના અને હીરાના હાર',
  ),
  HomeL10n.infoAboutTitle: LocalizedMessage(
    english: 'One world for every gem',
    hindi: 'हर रत्न के लिए एक दुनिया',
    gujarati: 'દરેક રત્ન માટે એક દુનિયા',
  ),
  HomeL10n.infoAboutBody: LocalizedMessage(
    english: 'Diamonds, jewellery, watches and bullion from verified sellers.',
    hindi: 'सत्यापित विक्रेताओं से हीरे, आभूषण, घड़ियाँ और बुलियन।',
    gujarati: 'ચકાસાયેલા વિક્રેતાઓ પાસેથી હીરા, ઘરેણાં, ઘડિયાળો અને બુલિયન.',
  ),
  HomeL10n.infoAboutAction: LocalizedMessage(
    english: 'About us',
    hindi: 'हमारे बारे में',
    gujarati: 'અમારા વિશે',
  ),
  HomeL10n.infoCertifiedTitle: LocalizedMessage(
    english: 'Certified diamonds',
    hindi: 'प्रमाणित हीरे',
    gujarati: 'પ્રમાણિત હીરા',
  ),
  HomeL10n.infoCertifiedBody: LocalizedMessage(
    english: 'Natural and lab-grown, with certificates you can check.',
    hindi: 'प्राकृतिक और लैब-ग्रोन हीरे, खरीदने से पहले प्रमाणपत्र जाँचें।',
    gujarati: 'કુદરતી અને લેબ-ગ્રોન હીરા, ખરીદતા પહેલાં પ્રમાણપત્ર તપાસો.',
  ),
  HomeL10n.infoCertifiedAction: LocalizedMessage(
    english: 'Search diamonds',
    hindi: 'हीरे खोजें',
    gujarati: 'હીરા શોધો',
  ),
  HomeL10n.infoLiveTitle: LocalizedMessage(
    english: 'Bid live with sellers',
    hindi: 'विक्रेताओं के साथ लाइव बोली',
    gujarati: 'વિક્રેતાઓ સાથે લાઇવ બોલી',
  ),
  HomeL10n.infoLiveBody: LocalizedMessage(
    english: 'Join live shows and auctions and win pieces in real time.',
    hindi: 'लाइव शो और नीलामी में जुड़ें और तुरंत जीतें।',
    gujarati: 'લાઇવ શો અને હરાજીમાં જોડાઓ અને તરત જીતો.',
  ),
  HomeL10n.infoLiveAction: LocalizedMessage(
    english: 'Watch live',
    hindi: 'लाइव देखें',
    gujarati: 'લાઇવ જુઓ',
  ),
  HomeL10n.infoLearnTitle: LocalizedMessage(
    english: 'Know your diamond',
    hindi: 'अपने हीरे को जानें',
    gujarati: 'તમારા હીરાને જાણો',
  ),
  HomeL10n.infoLearnBody: LocalizedMessage(
    english: 'Cut, colour, clarity and carat explained before you choose.',
    hindi: 'चुनने से पहले कट, रंग, स्पष्टता और कैरेट समझें।',
    gujarati: 'પસંદ કરતા પહેલાં કટ, રંગ, સ્પષ્ટતા અને કેરેટ સમજો.',
  ),
  HomeL10n.infoLearnAction: LocalizedMessage(
    english: 'Learn',
    hindi: 'सीखें',
    gujarati: 'શીખો',
  ),
  HomeL10n.infoSecureTitle: LocalizedMessage(
    english: 'Safe, secure checkout',
    hindi: 'सुरक्षित चेकआउट',
    gujarati: 'સુરક્ષિત ચેકઆઉટ',
  ),
  HomeL10n.infoSecureBody: LocalizedMessage(
    english: 'Protected payments and dedicated support at every step.',
    hindi: 'सुरक्षित भुगतान और हर कदम पर सहायता।',
    gujarati: 'સુરક્ષિત ચુકવણી અને દરેક પગલે સહાય.',
  ),
  HomeL10n.infoSecureAction: LocalizedMessage(
    english: 'Our policies',
    hindi: 'हमारी नीतियाँ',
    gujarati: 'અમારી નીતિઓ',
  ),
};
